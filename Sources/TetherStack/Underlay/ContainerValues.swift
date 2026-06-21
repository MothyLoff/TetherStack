import SwiftUI



// Per-side underlay content. Passed into the container via container values
// (iOS 18+, like `.tag` / `.badge`): the modifier attaches the value to the row,
// and `TetherVStack` reads it while enumerating subviews via `Group(subviews:)`.
extension ContainerValues {

    @Entry var tetherLeadingUnderlay: TetherUnderlayContent? = nil

    @Entry var tetherTrailingUnderlay: TetherUnderlayContent? = nil

}
