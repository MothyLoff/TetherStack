import SwiftUI



/// Shared layout and animation constants.
enum TetherLayout {


    /// Name of the container's coordinate space. Must match in `TetherVStack`
    /// (which declares the space and measures row centers) and in
    /// `TetherPanGesture` (which converts the touch point into this same space).
    static let coordinateSpaceName = "TetherVStack"


    /// How much horizontal must dominate vertical for the gesture to claim the
    /// touch (otherwise it yields to the outer scroll). >1 biases the priority
    /// toward scrolling.
    static let horizontalBias: CGFloat = 1.3


    /// Fraction of row width at which the underlay is fully revealed (progress = 1).
    /// Pulling further yields progress > 1 (overdrag beyond full reveal).
    static let revealFraction: CGFloat = 0.55


    /// Resistance scale of the smooth translation rubber band, as a fraction of
    /// row width: `d = resistanceFraction * width` in `TetherPhysics.resist`.
    /// Smaller -> the plate brakes sooner and travels less; larger -> it stays
    /// near 1:1 for longer.
    static let resistanceFraction: CGFloat = 0.7


    /// Spring used to return the plate after release.
    static let returnAnimation: Animation = .bouncy(duration: 0.35)


    /// Reveal-blur ceiling: the largest blur radius the underlay takes, applied
    /// at low reveal so it surfaces out of defocus.
    static let maxBlur: CGFloat = 24


    /// Reveal-blur radius at full reveal (`progress = 1`).
    /// Smaller -> the underlay is already sharp at full reveal.
    static let blurAtFullReveal: CGFloat = 0.2


    /// Underlay parallax as a fraction of row width. At `progress = 0` the
    /// underlay is tucked `parallaxTuckFraction * width` toward the edge, at `1`
    /// it sits exactly home, and beyond `1` it keeps sliding out.
    static let parallaxTuckFraction: CGFloat = 0.04


}
