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

    private let spacing: CGFloat?
    private let content: Content

    @State private var drag = TetherDragState()

    /// Вертикальные центры рядов в системе координат контейнера - нужны слою
    /// жеста, чтобы по точке касания определить ведущую плашку.
    @State private var rowCenters: [Int: CGFloat] = [:]

    /// `spacing` по умолчанию `nil` - как у нативного `VStack` (системный
    /// адаптивный интервал), а не фиксированный ноль.
    public init(spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {
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
    let leading: TetherUnderlayContent?
    let trailing: TetherUnderlayContent?
    let offset: CGFloat

    @State private var width: CGFloat = 0

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
        // front тянется на всю ширину силами контейнера (.frame(maxWidth:)), а не
        // за счёт растягивающейся фигуры внутри; padding пользователь добавляет
        // сверху сам.
        front
            .frame(maxWidth: .infinity)
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
    /// сторону (`o > 0`). `progress = 1` при сдвиге на `revealFraction` ширины;
    /// может быть `> 1` при оттягивании дальше (для будущего эффекта).
    private func reveal(forSignedOffset o: CGFloat) -> CGFloat {
        guard o > 0, width > 0 else { return 0 }
        return o / (TetherLayout.revealFraction * width)
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
            ? min(TetherLayout.maxBlur, TetherLayout.revealBlurK / progress)
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
