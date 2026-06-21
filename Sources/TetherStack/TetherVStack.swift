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
/// инверс-квадратным затуханием по `|i - lead|` (см. `TetherPhysics`). Peek с
/// пружинным возвратом на отпускание.
public struct TetherVStack<Content: View>: View {

    private let alignment: HorizontalAlignment
    private let spacing: CGFloat?
    private let content: Content

    @State private var drag = TetherDragState()

    /// Вертикальные центры рядов в системе координат контейнера - нужны слою
    /// жеста, чтобы по точке касания определить ведущую плашку.
    @State private var rowCenters: [Int: CGFloat] = [:]

    /// Ширины рядов - нужны жесту для резинки трансляции ведущего ряда.
    @State private var rowWidths: [Int: CGFloat] = [:]

    /// - Parameters:
    ///   - alignment: горизонтальное выравнивание рядов, как у `LazyVStack`.
    ///     По умолчанию `.center`. Имеет смысл для рядов уже контейнера; ряды
    ///     во всю ширину (например `.frame(maxWidth:)` на front) выравнивать
    ///     нечего.
    ///   - spacing: по умолчанию `nil` - как у нативного `VStack`/`LazyVStack`
    ///     (системный адаптивный интервал), а не фиксированный ноль.
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
            // Жест - на LazyVStack рядов; координатное пространство объявлено
            // выше, на Group, чтобы converter.location(in:) резолвил его как
            // предка вью, к которой привязан recognizer.
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

/// Один ряд: front-плашка над подложками. Front сдвигается на `offset`, подложки
/// стоят на месте - так из-под плашки проявляется reveal-контент.
private struct TetherRow<Front: View>: View, @MainActor Animatable {

    let front: Front
    let leading: TetherUnderlayContent?
    let trailing: TetherUnderlayContent?
    var offset: CGFloat

    @State private var width: CGFloat = 0

    // Все эффекты ряда (offset плашки, opacity/blur/параллакс подложки) считаются
    // из `offset`. Делаем его animatableData, чтобы на возврате `withAnimation`
    // интерполировал ОДНО значение и пересчитывал body покадрово - тогда подложка
    // уезжает синхронно с плашкой, а не дёргается независимыми модификаторами
    // (иначе на отпускании она схлопывается не в ногу - «исчезает мгновенно»).
    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }

    var body: some View {
        // Высоту ряда задаёт ТОЛЬКО front (плашка). Подложки вешаются как
        // .background оффсетнутого front'а - background-семантика: сайзятся по
        // хосту, overflow разрешён, в лейаут ряда НЕ входят (как .background /
        // .overlay в SwiftUI). Высокий underlay не растит ряд и не клипается.
        //
        // .offset не меняет layout-фрейм, поэтому background остаётся статичным,
        // пока плашка едет over него - это и есть reveal. Обе подложки в фоне
        // всегда; раскрытие стороны - непрерывная функция offset (reveal), на
        // перелёте пружины противоположная сторона раскрыта ~0, мигать нечему.
        //
        // Ширину front НЕ форсим: ряд занимает натуральную ширину контента, а
        // позиционирует его горизонтальный alignment контейнера (как нативный
        // LazyVStack). Подложки перекрыты при любой ширине - они background'и
        // самого front'а. Нужен full-width - ставь .frame(maxWidth:) на front.
        front
            .offset(x: offset)
            .background {
                if let leading {
                    underlay(leading, horizontal: .leading, parallaxSign: -1,
                             progress: reveal(forSignedOffset: offset))
                }
            }
            .background {
                if let trailing {
                    underlay(trailing, horizontal: .trailing, parallaxSign: 1,
                             progress: reveal(forSignedOffset: -offset))
                }
            }
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
    }

    /// Прогресс раскрытия стороны. Положителен только когда плашка ушла в эту
    /// сторону (`signedOffset > 0`). `progress = 1` при сдвиге на `revealFraction`
    /// ширины; может быть `> 1` при оттягивании дальше (для будущего эффекта).
    private func reveal(forSignedOffset signedOffset: CGFloat) -> CGFloat {
        guard signedOffset > 0, width > 0 else { return 0 }
        return signedOffset / (TetherLayout.revealFraction * width)
    }

    private func underlay(
        _ content: TetherUnderlayContent,
        horizontal: HorizontalAlignment,
        parallaxSign: CGFloat,
        progress: CGFloat
    ) -> some View {
        // Reveal-эффект, всё от progress:
        // - blur: гипербола с клампом; в нуле доопределена пределом maxBlur,
        //   чтобы функция была непрерывной (без разрыва на progress=0).
        // - opacity: progress, клампленный в 1.
        // - параллакс: при progress=0 утоплено на долю ширины, к progress=1
        //   приезжает на место (home), при >1 продолжает уезжать.
        //
        // Горизонталь якоря - сторона раскрытия (функциональная ось), вертикаль -
        // пользовательский verticalAlignment (косметическая, дефолт .center).
        let blurRadius: CGFloat = progress > 0
            ? min(TetherLayout.maxBlur, TetherLayout.blurAtFullReveal / progress)
            : TetherLayout.maxBlur
        let dx = parallaxSign * TetherLayout.parallaxTuckFraction * width * (1 - progress)

        return content.view
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: Alignment(horizontal: horizontal, vertical: content.verticalAlignment.resolved)
            )
            .blur(radius: blurRadius)
            .opacity(Double(min(progress, 1)))
            .offset(x: dx)
    }
}
