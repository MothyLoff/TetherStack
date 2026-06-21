import SwiftUI

/// Вертикальный контейнер, раздающий связанное горизонтальное оттягивание с
/// затуханием по дуге (эффект верёвочной лестницы на резиночке).
///
/// Ведёт себя как `LazyVStack`: своим скроллом НЕ владеет, кладётся во внешний
/// `ScrollView`, сам сообщает высоту наверх.
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
/// Тянешь одну плашку вбок - она идёт за пальцем, соседи выше и ниже следуют с
/// экспоненциальным... нет, инверс-квадратным затуханием по `|i - lead|`
/// (см. `TetherPhysics`). Peek с пружинным возвратом на отпускание.
public struct TetherVStack<Content: View>: View {

    private let spacing: CGFloat
    private let content: Content

    @State private var drag = TetherDragState()

    /// Вертикальные центры рядов в системе координат контейнера - нужны слою
    /// жеста, чтобы по точке касания определить ведущую плашку.
    @State private var rowCenters: [Int: CGFloat] = [:]

    public init(spacing: CGFloat = 0, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        Group(subviews: content) { subviews in
            VStack(spacing: spacing) {
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
                    }
                }
            }
            // Жест - на VStack рядов; координатное пространство объявлено выше,
            // на Group, чтобы converter.location(in:) резолвил его как предка
            // вью, к которой привязан recognizer.
            .gesture(
                TetherPanGesture(
                    drag: $drag,
                    rowCenters: rowCenters
                )
            )
        }
        .coordinateSpace(.named(TetherLayout.coordinateSpaceName))
    }
}

/// Один ряд: front-плашка над подложками. Front сдвигается на `offset`, подложки
/// стоят на месте - так из-под плашки проявляется reveal-контент.
private struct TetherRow<Front: View>: View {

    let front: Front
    let leading: AnyView?
    let trailing: AnyView?
    let offset: CGFloat

    var body: some View {
        ZStack {
            // Под плашкой - подложка той стороны, в которую сейчас тянем.
            // offset > 0: front уехал вправо, обнажился ЛЕВЫЙ (leading) край.
            // offset < 0: front уехал влево, обнажился ПРАВЫЙ (trailing) край.
            if offset > 0, let leading {
                underlay(leading, alignment: .leading)
            } else if offset < 0, let trailing {
                underlay(trailing, alignment: .trailing)
            }

            front
                .offset(x: offset)
        }
    }

    private func underlay(_ view: AnyView, alignment: Alignment) -> some View {
        view
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
            // TODO(физика): кламп блюра при порте reveal-рецепта из демки -
            // в оригинале blur(radius: 1/oC * 30) взрывался при малом oC.
    }
}
