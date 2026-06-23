import SwiftUI



/// Underlay content + its vertical alignment in the row. The horizontal axis
/// (the reveal side) is carried by the container key itself (`leading`/`trailing`).
struct TetherUnderlayContent {


    let view: AnyView

    let verticalAlignment: TetherVerticalAlignment


}
