import SwiftUI



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
