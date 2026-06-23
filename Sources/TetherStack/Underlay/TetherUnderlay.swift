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
    ///   - edge: the reveal side.
    ///   - verticalAlignment: vertical alignment of the content within the row's
    ///     height (the front plate sets the height). Defaults to `.center`.
    ///
    /// A missing underlay on a side does NOT disable the pull: the plate still moves.
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
