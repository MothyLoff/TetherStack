import SwiftUI



/// Underlay content + its vertical alignment in the row. The horizontal axis
/// (the reveal side) is NOT stored here - it is carried by the container key
/// itself (`leading`/`trailing`); that is the functional axis, not a cosmetic one.
struct TetherUnderlayContent {

    let view: AnyView

    let verticalAlignment: TetherVerticalAlignment

}
