import SwiftUI

// MARK: - Public vertical alignment

/// Вертикальное выравнивание контента подложки в высоте ряда.
///
/// Намеренно НЕ `SwiftUI.VerticalAlignment`: тот тащит `firstTextBaseline` /
/// `lastTextBaseline`, которые в прямоугольнике ряда не имеют смысла, плюс
/// протокольный шум в автодополнении. Здесь только три осмысленных варианта -
/// тот же принцип, что у `HorizontalEdge` для стороны: невалидное состояние
/// непредставимо.
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

/// Контент подложки + его вертикальное выравнивание в ряду. Горизонтальная ось
/// (сторона раскрытия) здесь НЕ хранится - её несёт сам ключ контейнера
/// (`leading`/`trailing`), это функциональная ось, а не косметическая.
struct TetherUnderlayContent {
    let view: AnyView
    let verticalAlignment: TetherVerticalAlignment
}

// MARK: - Container values

// Контент подложки каждой стороны. Передаётся в контейнер через container values
// (iOS 18+, как `.tag` / `.badge`): модификатор вешает значение на ряд, а
// `TetherVStack` читает его при перечислении субвью через `Group(subviews:)`.
extension ContainerValues {
    @Entry var tetherLeadingUnderlay: TetherUnderlayContent? = nil
    @Entry var tetherTrailingUnderlay: TetherUnderlayContent? = nil
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
    /// - Parameters:
    ///   - edge: сторона раскрытия. Нативный `HorizontalEdge`; в RTL стороны и
    ///     свайпы зеркалятся автоматически через `\.layoutDirection`, как у
    ///     `swipeActions(edge:)`. Функциональная ось - «центрального» раскрытия
    ///     не бывает, поэтому она типобезопасна, а не часть `Alignment`.
    ///   - verticalAlignment: вертикальное выравнивание контента в высоте ряда
    ///     (высоту задаёт front-плашка). По умолчанию `.center`; `.top` совместит
    ///     верх подложки с верхом плашки. Косметическая ось.
    ///
    /// Отсутствие подложки на стороне НЕ отключает оттягивание: плашка всё равно
    /// тянется (однородная физика верёвочной лестницы), просто под ней с этой
    /// стороны ничего не проявляется.
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
