import CoreGraphics

/// Состояние активного оттягивания. Живёт как `@State` в `TetherVStack`,
/// мутируется слоем жеста, читается раскладкой рядов.
struct TetherDragState: Equatable {

    /// Индекс ведущей плашки (под которой начался жест). `nil` - оттягивания нет.
    var leadIndex: Int?

    /// Горизонтальное смещение ведущей плашки в точках (уже пропущено через
    /// `TetherPhysics.resist`). Знак: + вправо, - влево.
    var leadTranslation: CGFloat = 0

    /// Смещение ряда `index` с учётом затухания по дистанции до ведущего.
    func offset(for index: Int) -> CGFloat {
        guard let lead = leadIndex else { return 0 }
        let distance = CGFloat(index - lead)
        return leadTranslation * TetherPhysics.falloff(d: distance)
    }
}
