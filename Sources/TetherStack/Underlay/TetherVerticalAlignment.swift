import SwiftUI



/// Vertical alignment of the underlay content within the row's height.
///
/// Deliberately NOT `SwiftUI.VerticalAlignment`: that one drags in
/// `firstTextBaseline` / `lastTextBaseline`, which are meaningless inside a row
/// rectangle, plus protocol noise in autocomplete. Only the three meaningful
/// cases here - the same principle as `HorizontalEdge` for the side: invalid
/// state is unrepresentable.
public enum TetherVerticalAlignment {

    case top
    case center
    case bottom

    var resolved: VerticalAlignment {
        switch self {
        case .top:    .top
        case .center: .center
        case .bottom: .bottom
        }
    }

}
