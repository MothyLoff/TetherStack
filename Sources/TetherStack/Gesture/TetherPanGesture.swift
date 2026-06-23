import SwiftUI
import UIKit



/// Connects the pan gesture to the container's drag state: finds the lead row
/// under the touch and converts the finger's horizontal travel into the lead
/// plate's offset.
///
/// The directional lock lives in the delegate `gestureRecognizerShouldBegin(_:)`
/// at the `possible -> began` boundary: measure `velocity`, a clear horizontal
/// begins (claim it), otherwise fail (the touch goes to the outer scroll).
struct TetherPanGesture: UIGestureRecognizerRepresentable {


    @Binding var drag: TetherDragState


    /// Vertical row centers in `TetherLayout.coordinateSpaceName` coordinates.
    let rowCenters: [Int: CGFloat]

    /// Each row's width by index. The lead row's width sets the rubber-band
    /// resistance scale (`d = resistanceFraction * width`).
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
            // Take the touch point via the converter, into the same coordinate
            // space where row centers are measured. Otherwise, inside a
            // ScrollView, lead detection misses by the scroll offset.
            let y = context.converter.location(in: space).y
            drag.leadIndex = nearestRow(toY: y)
            drag.leadTranslation = 0

        case .changed:
            let dx = context.converter.localTranslation?.x ?? 0
            // Smooth translation rubber band (arctan): 1:1 at first, then eases.
            // Resistance scale d = resistanceFraction * lead row width.
            // If the width isn't measured yet (0), resist returns dx (1:1).
            let leadWidth = drag.leadIndex.flatMap { rowWidths[$0] } ?? 0
            drag.leadTranslation = TetherPhysics.resist(
                dx,
                d: TetherLayout.resistanceFraction * leadWidth
            )

        case .ended, .cancelled, .failed:
            // Peek: spring back to zero. Overshoot past zero is allowed - the
            // underlay reveal is continuous in offset (TetherRow.reveal).
            //
            // Do NOT zero leadIndex: offset = leadTranslation * falloff, and
            // leadTranslation animates to 0 anyway; the next .began overwrites it.
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

        /// Ask the scroll's pan to wait until we settle on a direction, closing
        /// the timing gap in the first millimeters.
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldBeRequiredToFailBy other: UIGestureRecognizer
        ) -> Bool {
            other.view is UIScrollView
        }

    }


}
