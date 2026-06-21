import SwiftUI

// MARK: - Container values

// Контент, лежащий ПОД плашкой с каждой стороны. Передаётся в контейнер через
// механизм container values (iOS 18+, как `.tag` / `.badge`): модификатор вешает
// значение на ряд, а `TetherVStack` читает его при перечислении субвью через
// `Group(subviews:)`. Контейнер при этом ничего не знает про конкретный контент.
extension ContainerValues {
    @Entry var tetherLeadingUnderlay: AnyView? = nil
    @Entry var tetherTrailingUnderlay: AnyView? = nil
}

// MARK: - Public modifier

public extension View {

    /// Декларирует контент, лежащий под плашкой с указанного края; проявляется
    /// при оттягивании плашки в эту сторону.
    ///
    /// Можно повесить независимо на оба края с разным контентом:
    /// ```swift
    /// RowView(item)
    ///     .tetherUnderlay(.leading)  { LeadingContent(item) }
    ///     .tetherUnderlay(.trailing) { TrailingContent(item) }
    /// ```
    ///
    /// `edge` - нативный `HorizontalEdge`; в RTL стороны зеркалятся автоматически
    /// через `\.layoutDirection`, как у `swipeActions(edge:)`. Кастомного enum нет.
    ///
    /// Отсутствие подложки на стороне НЕ отключает оттягивание: плашка всё равно
    /// тянется (однородная физика верёвочной лестницы), просто под ней с этой
    /// стороны ничего не проявляется.
    func tetherUnderlay<Underlay: View>(
        _ edge: HorizontalEdge,
        @ViewBuilder content: () -> Underlay
    ) -> some View {
        let underlay = AnyView(content())
        switch edge {
        case .leading:
            return containerValue(\.tetherLeadingUnderlay, underlay)
        case .trailing:
            return containerValue(\.tetherTrailingUnderlay, underlay)
        }
    }
}
