import SwiftUI

/// Общие константы раскладки и анимации - один источник для тюнинга.
/// Имя координатного пространства должно совпадать в `TetherVStack` (где оно
/// объявлено и где меряются центры рядов) и в `TetherPanGesture` (где точка
/// касания конвертится в это же пространство).
enum TetherLayout {
    static let coordinateSpaceName = "TetherVStack"

    /// Насколько горизонталь должна доминировать над вертикалью, чтобы жест
    /// забрал касание себе (иначе - уступка внешнему скроллу). >1 смещает
    /// приоритет в пользу скролла. Подбирается на устройстве.
    static let horizontalBias: CGFloat = 1.3

    /// Доля ширины ряда, на которой подложка раскрыта полностью (progress = 1).
    /// Сдвиг дальше даёт progress > 1 (оттягивание сверх раскрытия).
    static let revealFraction: CGFloat = 0.55

    /// Масштаб сопротивления гладкой резинки трансляции как доля ширины ряда:
    /// `d = resistanceFraction · width` в `TetherPhysics.resist`. Меньше → плашка
    /// начинает тормозить раньше и ход короче; больше → дольше идёт почти 1:1.
    static let resistanceFraction: CGFloat = 0.7

    /// Пружина возврата плашки после отпускания. Пресет и длительность как в
    /// эталоне (MultiSwipe): `.bouncy` = spring с bounce ~0.3.
    static let returnAnimation: Animation = .bouncy(duration: 0.35)

    /// Reveal-блюр: подложка выплывает из расфокуса по мере оттягивания.
    /// `radius = min(maxBlur, revealBlurK / progress)`, гипербола - сильный
    /// расфокус в начале, быстрый сход к резкости. `revealBlurK` - радиус на
    /// `progress = 1` (мал → резко на полном раскрытии); `maxBlur` - потолок.
    /// В нуле гипербола доопределена пределом `maxBlur` (а не 0), чтобы
    /// функция была непрерывной; на `opacity = 0` blur-пасс система скипает.
    static let maxBlur: CGFloat = 24
    static let revealBlurK: CGFloat = 0.2

    /// Параллакс подложки как доля ширины ряда. При `progress = 0` подложка
    /// утоплена на `parallaxTuckFraction · width` в сторону края, при `1` - ровно
    /// на месте (home), при `> 1` продолжает уезжать дальше («тянется»).
    static let parallaxTuckFraction: CGFloat = 0.04
}
