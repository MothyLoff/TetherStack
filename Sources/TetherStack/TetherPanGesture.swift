import SwiftUI
import UIKit



/// Bridge between the UIKit gesture and the container's SwiftUI state.
///
/// `UIGestureRecognizerRepresentable` (iOS 18+) attaches a REAL UIKit recognizer
/// directly onto a SwiftUI view - without wrapping the whole container in a
/// `UIViewRepresentable`. This is option A: the container stays native SwiftUI,
/// while a real recognizer provides the directional lock that pure SwiftUI
/// `Gesture` cannot.
///
/// The directional lock is implemented NOT via a subclass with `state = .failed`,
/// but via the delegate `gestureRecognizerShouldBegin(_:)` at the
/// `possible -> began` boundary: we measure `velocity`, and a clear horizontal
/// -> begin (claim it), otherwise -> fail (the touch goes to the outer scroll).
/// This avoids the began/failed race.
struct TetherPanGesture: UIGestureRecognizerRepresentable {

    @Binding var drag: TetherDragState

    /// Vertical row centers in `TetherLayout.coordinateSpaceName` coordinates.
    let rowCenters: [Int: CGFloat]

    /// Row widths by index - for the translation rubber band (lead row's dimension).
    let rowWidths: [Int: CGFloat]

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator()
    }

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let recognizer = UIPanGestureRecognizer()
        recognizer.delegate = context.coordinator
        return recognizer
    }

    func handleUIGestureRecognizerAction(
        _ recognizer: UIPanGestureRecognizer,
        context: Context
    ) {
        let space = NamedCoordinateSpace.named(TetherLayout.coordinateSpaceName)

        switch recognizer.state {
        case .began:
            // Take the touch point via the converter -> into the same coordinate
            // system where row centers are measured. Otherwise, inside a
            // ScrollView, lead detection misses by the scroll offset.
            let y = context.converter.location(in: space).y
            drag.leadIndex = nearestRow(toY: y)
            drag.leadTranslation = 0

        case .changed:
            let dx = context.converter.localTranslation?.x ?? 0
            // Smooth translation rubber band (arctan): 1:1 at first, then eases.
            // Resistance scale d = resistanceFraction · lead row width.
            // If the width isn't measured yet (0), resist returns dx (1:1).
            let leadWidth = drag.leadIndex.flatMap { rowWidths[$0] } ?? 0
            drag.leadTranslation = TetherPhysics.resist(
                dx,
                d: TetherLayout.resistanceFraction * leadWidth
            )

        case .ended, .cancelled, .failed:
            // Peek: spring back to zero. Overshoot past zero is allowed - the
            // underlay reveal is continuous in offset (TetherRow.reveal); on the
            // overshoot the opposite side is revealed ~0, so nothing flickers.
            //
            // Do NOT zero leadIndex: offset = leadTranslation · falloff, and
            // leadTranslation animates to 0 anyway; the next .began overwrites it.
            // There used to be a completion { leadIndex = nil } here - it fired
            // asynchronously after ~0.3s and, on a fast re-grab of the row, zeroed
            // leadIndex in the middle of a new drag (a race, "1 in 10").
            // TODO(physics): inject initial velocity from localVelocity - the
            // SwiftUI animation doesn't take it directly; option B would provide
            // this via UISpringTimingParameters.
            withAnimation(TetherLayout.returnAnimation) {
                drag.leadTranslation = 0
            }

        default:
            break
        }
    }

    /// The row vertically nearest to the touch point.
    private func nearestRow(toY y: CGFloat) -> Int? {
        rowCenters.min { abs($0.value - y) < abs($1.value - y) }?.key
    }

    /// Delegate coordinator: directional lock + reactive coordination with the scroll.
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {

        /// Decision at the possible -> began boundary: claim the touch only on a
        /// clear horizontal dominance, otherwise yield to the scroll.
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
            let velocity = pan.velocity(in: pan.view)
            return abs(velocity.x) > abs(velocity.y) * TetherLayout.horizontalBias
        }

        /// The other recognizer is passed in - no view-hierarchy walk needed.
        /// We ask the scroll's pan to wait until we settle on a direction
        /// (closing the timing gap in the first millimeters).
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldBeRequiredToFailBy other: UIGestureRecognizer
        ) -> Bool {
            other.view is UIScrollView
        }
    }
    
}
