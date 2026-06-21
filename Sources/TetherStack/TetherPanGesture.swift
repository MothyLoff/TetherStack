import SwiftUI
import UIKit

/// Мост между UIKit-жестом и SwiftUI-состоянием контейнера.
///
/// `UIGestureRecognizerRepresentable` (iOS 18+) навешивает НАСТОЯЩИЙ UIKit
/// recognizer прямо на SwiftUI-вью - без оборачивания всего контейнера в
/// `UIViewRepresentable`. Это и есть вариант A: контейнер остаётся нативным
/// SwiftUI, а реальный recognizer даёт directional lock, недоступный в чистом
/// SwiftUI `Gesture`.
///
/// Directional lock реализован НЕ сабклассом с `state = .failed`, а делегатным
/// `gestureRecognizerShouldBegin(_:)` на границе `possible -> began`: меряем
/// `velocity`, явная горизонталь -> begin (забираем), иначе -> провал (касание
/// уходит внешнему скроллу). Так нет гонки began/failed.
struct TetherPanGesture: UIGestureRecognizerRepresentable {

    @Binding var drag: TetherDragState

    /// Вертикальные центры рядов в координатах `TetherLayout.coordinateSpaceName`.
    let rowCenters: [Int: CGFloat]

    /// Ширины рядов по индексу - для резинки трансляции (edge/dim ведущего ряда).
    let rowWidths: [Int: CGFloat]

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator()
    }

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let recognizer = UIPanGestureRecognizer()
        recognizer.delegate = context.coordinator
        return recognizer
    }

    func handleUIGestureRecognizerAction(
        _ recognizer: UIPanGestureRecognizer,
        context: Context
    ) {
        let space = NamedCoordinateSpace.named(TetherLayout.coordinateSpaceName)

        switch recognizer.state {
        case .began:
            // Точку касания берём через converter -> в той же системе координат,
            // где меряются центры рядов. Иначе внутри ScrollView lead-детекция
            // промахивается на величину скролл-оффсета.
            let y = context.converter.location(in: space).y
            drag.leadIndex = nearestRow(toY: y)
            drag.leadTranslation = 0

        case .changed:
            let dx = context.converter.localTranslation?.x ?? 0
            // Гладкая резинка трансляции (arctan): 1:1 в начале, плавно тормозит.
            // Масштаб сопротивления d = resistanceFraction · ширина ведущего ряда.
            // Если ширина ещё не измерена (0) - resist вернёт dx (1:1).
            let w = drag.leadIndex.flatMap { rowWidths[$0] } ?? 0
            drag.leadTranslation = TetherPhysics.resist(
                dx,
                d: TetherLayout.resistanceFraction * w
            )

        case .ended, .cancelled, .failed:
            // Peek: пружинный возврат в ноль. Перелёт через ноль разрешён -
            // раскрытие подложки непрерывно по offset (TetherRow.reveal), на
            // перелёте противоположная сторона раскрыта ~0, мигать нечему.
            //
            // leadIndex НЕ зануляем: offset = leadTranslation · falloff, а
            // leadTranslation и так уходит в 0 анимацией; следующий .began его
            // перезапишет. Раньше тут был completion { leadIndex = nil } - он
            // срабатывал асинхронно через ~0.3с и при быстром повторном захвате
            // ряда занулял leadIndex посреди нового драга (гонка, «1 из 10»).
            // TODO(физика): инъекция начальной скорости из localVelocity -
            // SwiftUI-анимация её напрямую не берёт; вариант B даст это через
            // UISpringTimingParameters.
            withAnimation(TetherLayout.returnAnimation) {
                drag.leadTranslation = 0
            }

        default:
            break
        }
    }

    /// Ближайший по вертикали ряд к точке касания.
    private func nearestRow(toY y: CGFloat) -> Int? {
        rowCenters.min { abs($0.value - y) < abs($1.value - y) }?.key
    }

    /// Координатор-делегат: directional lock + реактивная координация со скроллом.
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {

        /// Решение на границе possible -> began: забираем касание только при
        /// явном горизонтальном доминировании, иначе уступаем скроллу.
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
            let v = pan.velocity(in: pan.view)
            return abs(v.x) > abs(v.y) * TetherLayout.horizontalBias
        }

        /// Чужой recognizer передают параметром - не нужен обход иерархии.
        /// Просим pan скролла дождаться, пока мы определимся с направлением
        /// (закрываем тайминговую щель в первые миллиметры).
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldBeRequiredToFailBy other: UIGestureRecognizer
        ) -> Bool {
            other.view is UIScrollView
        }
    }
}
