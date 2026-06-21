import CoreGraphics

/// Единый источник физики оттягивания. Наружу не торчит - публичный API
/// не принимает функцию затухания (зафиксировано 2026-06-21).
///
/// Закон затухания - инверс-квадрат (НЕ экспонента), снят с настроенной демки
/// `MultiSwipe`: ведущая плашка идёт за пальцем, соседи затухают по `|i - lead|`.
enum TetherPhysics {

    /// Множитель смещения для ряда на дистанции `d` от ведущего.
    /// `d = |i - leadIndex| >= 0`.
    ///
    /// `falloff(0) = 1`, `falloff(1) = 0.5`, `falloff(2) = 0.2`, `falloff(3) = 0.1`.
    /// Дальние соседи (`d >= cutoff`) обрезаются в ноль - внутренняя оптимизация,
    /// чтобы не гонять весь стек на каждый кадр.
    static func falloff(d: CGFloat) -> CGFloat {
        let distance = abs(d)
        guard distance < cutoff else { return 0 }
        return 1 / (distance * distance + 1)
    }

    /// Палец: ведущая плашка идёт за пальцем как `translation.width / fingerDivisor`
    /// (~0.67), не 1:1. Снято с демки.
    static let fingerDivisor: CGFloat = 1.5

    /// Радиус обрезки соседей. За пределом множитель = 0.
    static let cutoff: CGFloat = 6
}
