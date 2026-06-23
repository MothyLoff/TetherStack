import SwiftUI



/// A vertical container that distributes a linked horizontal pull with arc-shaped
/// falloff (a rope-ladder-on-elastic effect).
///
/// Behaves like `LazyVStack`.
///
/// ```swift
/// ScrollView {
///     TetherVStack(spacing: 10) {
///         ForEach(items) { item in
///             RowView(item)
///                 .tetherUnderlay(.leading)  { LeadingContent(item) }
///                 .tetherUnderlay(.trailing) { TrailingContent(item) }
///         }
///     }
/// }
/// ```
///
/// Pull one plate sideways and it follows the finger; the neighbors above and
/// below follow with inverse-square falloff in `|i - lead|` (see `TetherPhysics`).
/// Peek with a spring-back return on release.
public struct TetherVStack<Content: View>: View {


    private let alignment: HorizontalAlignment

    private let spacing: CGFloat?

    private let content: Content


    @State private var drag = TetherDragState()


    /// Vertical row centers in the container's coordinate system - needed by the
    /// gesture layer to resolve the lead plate from the touch point.
    @State private var rowCenters: [Int: CGFloat] = [:]


    /// Row widths - needed by the gesture for the lead row's translation rubber band.
    @State private var rowWidths: [Int: CGFloat] = [:]


    /// - Parameters:
    ///   - alignment: horizontal alignment of the rows, like `LazyVStack`.
    ///     Defaults to `.center`. Meaningful for rows narrower than the container.
    ///   - spacing: defaults to `nil` - like native `VStack`/`LazyVStack`, the
    ///     system's adaptive spacing.
    public init(
        alignment: HorizontalAlignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }


    public var body: some View {
        Group(subviews: content) { subviews in
            LazyVStack(alignment: alignment, spacing: spacing) {
                ForEach(subviews.indices, id: \.self) { index in
                    let subview = subviews[index]
                    TetherRow(
                        front: subview,
                        leading: subview.containerValues.tetherLeadingUnderlay,
                        trailing: subview.containerValues.tetherTrailingUnderlay,
                        offset: drag.offset(for: index)
                    )
                    .onGeometryChange(for: CGRect.self) { proxy in
                        proxy.frame(in: .named(TetherLayout.coordinateSpaceName))
                    } action: { frame in
                        rowCenters[index] = frame.midY
                        rowWidths[index] = frame.width
                    }
                }
            }
            // The gesture lives on the rows' LazyVStack; the coordinate space is
            // declared above on the Group so that converter.location(in:) resolves
            // it as an ancestor of the view the recognizer is attached to.
            .gesture(
                TetherPanGesture(
                    drag: $drag,
                    rowCenters: rowCenters,
                    rowWidths: rowWidths
                )
            )
        }
        .coordinateSpace(.named(TetherLayout.coordinateSpaceName))
    }


}
