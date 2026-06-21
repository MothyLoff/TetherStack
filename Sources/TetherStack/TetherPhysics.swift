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

    /// Трансляция пальца в смещение ведущей плашки: 1:1 до `edge`, дальше -
    /// резинка `UIScrollView` (реверс-инженерная формула overscroll), асимптота
    /// `edge + dim`. На границе наклон падает с 1 до `c` - тот же излом, что у
    /// нативного iOS overscroll на краю контента.
    /// - edge: длина 1:1-региона (у нас `revealFraction · width`).
    /// - dim: размер по оси сопротивления (ширина).
    /// - c: жёсткость резинки у границы (iOS ≈ 0.55).
    static func rubberBand(_ x: CGFloat, edge: CGFloat, dim: CGFloat, c: CGFloat) -> CGFloat {
        let m = abs(x)
        guard m > edge, dim > 0 else { return x }
        let over = m - edge
        let resisted = (1 - 1 / (c * over / dim + 1)) * dim
        return (x < 0 ? -1 : 1) * (edge + resisted)
    }

    /// Радиус обрезки соседей. За пределом множитель = 0.
    static let cutoff: CGFloat = 6
}
