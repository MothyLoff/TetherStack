import SwiftUI



/// A single row: the front plate over its underlays. The front shifts by
/// `offset` while the underlays stay put - that is how the reveal content
/// emerges from beneath the plate.
struct TetherRow<Front: View>: View, @MainActor Animatable {

    let front: Front

    let leading: TetherUnderlayContent?

    let trailing: TetherUnderlayContent?

    var offset: CGFloat

    @State private var width: CGFloat = 0

    // All of the row's effects (plate offset, underlay opacity/blur/parallax) are
    // computed from `offset`. We make it animatableData so that on the return
    // `withAnimation` interpolates ONE value and recomputes the body frame by
    // frame - then the underlay moves in lockstep with the plate, rather than
    // jerking via independent modifiers (otherwise on release it collapses out of
    // sync - reads as "disappears instantly").
    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }

    var body: some View {
        // Only the front (plate) sets the row's height. The underlays are attached
        // as .background of the offset front - background semantics: they size to
        // the host, overflow is allowed, and they do NOT enter the row's layout
        // (like .background / .overlay in SwiftUI). A tall underlay neither grows
        // the row nor gets clipped.
        //
        // .offset doesn't change the layout frame, so the background stays static
        // while the plate moves over it - that is the reveal. Both underlays are
        // always in the background; a side's reveal is a continuous function of
        // offset (reveal), and on a spring overshoot the opposite side is revealed
        // ~0, so nothing flickers.
        //
        // We do NOT force the front's width: the row takes the content's natural
        // width and is positioned by the container's horizontal alignment (like
        // native LazyVStack). The underlays are covered at any width - they are
        // backgrounds of the front itself. Need full width - put .frame(maxWidth:)
        // on the front.
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

    /// Reveal progress for a side. Positive only when the plate has moved toward
    /// that side (`signedOffset > 0`). `progress = 1` at a shift of `revealFraction`
    /// of the width; may be `> 1` when pulled further (for a future effect).
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
        // Reveal effect, all driven by progress:
        // - blur: a clamped hyperbola; at zero it is defined by the limit maxBlur
        //   so the function stays continuous (no discontinuity at progress=0).
        // - opacity: progress, clamped to 1.
        // - parallax: at progress=0 it is tucked by a fraction of width, by
        //   progress=1 it arrives home, beyond 1 it keeps sliding out.
        //
        // The anchor's horizontal is the reveal side (functional axis), the
        // vertical is the user's verticalAlignment (cosmetic, default .center).
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
