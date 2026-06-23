import SwiftUI



/// Vertical alignment of the underlay content within the row's height.
///
/// Deliberately NOT `SwiftUI.VerticalAlignment`: that one drags in
/// `firstTextBaseline` / `lastTextBaseline`. Only the three meaningful cases here.
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
