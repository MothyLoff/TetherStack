import SwiftUI



// MARK: - Public vertical alignment

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



// MARK: - Underlay payload

/// Underlay content + its vertical alignment in the row. The horizontal axis
/// (the reveal side) is NOT stored here - it is carried by the container key
/// itself (`leading`/`trailing`); that is the functional axis, not a cosmetic one.
struct TetherUnderlayContent {
    let view: AnyView
    let verticalAlignment: TetherVerticalAlignment
}



// MARK: - Container values

// Per-side underlay content. Passed into the container via container values
// (iOS 18+, like `.tag` / `.badge`): the modifier attaches the value to the row,
// and `TetherVStack` reads it while enumerating subviews via `Group(subviews:)`.
extension ContainerValues {
    @Entry var tetherLeadingUnderlay: TetherUnderlayContent? = nil
    @Entry var tetherTrailingUnderlay: TetherUnderlayContent? = nil
}



// MARK: - Public modifier

public extension View {

    /// Declares the content that sits under the plate on the given edge; it is
    /// revealed as the plate is pulled toward that side.
    ///
    /// You can attach different content to each edge independently:
    /// ```swift
    /// RowView(item)
    ///     .tetherUnderlay(.leading)  { LeadingContent(item) }
    ///     .tetherUnderlay(.trailing) { TrailingContent(item) }
    /// ```
    ///
    /// - Parameters:
    ///   - edge: the reveal side. A native `HorizontalEdge`; in RTL the sides and
    ///     swipes mirror automatically via `\.layoutDirection`, like
    ///     `swipeActions(edge:)`. This is the functional axis - there is no
    ///     "center" reveal, so it is type-safe rather than part of `Alignment`.
    ///   - verticalAlignment: vertical alignment of the content within the row's
    ///     height (the front plate sets the height). Defaults to `.center`;
    ///     `.top` aligns the underlay's top with the plate's top. Cosmetic axis.
    ///
    /// A missing underlay on a side does NOT disable the pull: the plate still
    /// moves (uniform rope-ladder physics), there is simply nothing to reveal
    /// under it on that side.
    func tetherUnderlay<Underlay: View>(
        _ edge: HorizontalEdge,
        verticalAlignment: TetherVerticalAlignment = .center,
        @ViewBuilder content: () -> Underlay
    ) -> some View {
        let payload = TetherUnderlayContent(
            view: AnyView(content()),
            verticalAlignment: verticalAlignment
        )
        switch edge {
        case .leading:
            return containerValue(\.tetherLeadingUnderlay, payload)
        case .trailing:
            return containerValue(\.tetherTrailingUnderlay, payload)
        }
    }
    
}
