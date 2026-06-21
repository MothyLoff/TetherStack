import Foundation



/// Single source of the pull physics. Not exposed - the public API does not
/// accept a falloff function (decided 2026-06-21).
///
/// The falloff law is inverse-square (NOT exponential), lifted from the tuned
/// `MultiSwipe` demo: the lead plate follows the finger, neighbors attenuate by
/// `|i - lead|`.
enum TetherPhysics {

    /// Offset multiplier for a row at distance `d` from the lead.
    /// `d = |i - leadIndex| >= 0`.
    ///
    /// `falloff(0) = 1`, `falloff(1) = 0.5`, `falloff(2) = 0.2`, `falloff(3) = 0.1`.
    /// Far neighbors (`d >= cutoff`) are clamped to zero - an internal
    /// optimization so the whole stack isn't walked every frame.
    static func falloff(d: CGFloat) -> CGFloat {
        let distance = abs(d)
        guard distance < cutoff else { return 0 }
        return 1 / (distance * distance + 1)
    }

    /// Maps finger translation to lead-plate offset - a SMOOTH rubber band with
    /// no threshold.
    ///
    /// `f(x) = sign(x) · d · atan(|x| / d)`. Slope `f'(x) = 1/(1 + (x/d)²)`:
    /// exactly 1 at zero (finger and plate move 1:1), stays near 1 while `x ≪ d`,
    /// then eases off - resistance `1 − f'` grows like `(x/d)²` (slow at first,
    /// sharper near `x ~ d`). No derivative kink, unlike the piecewise
    /// "1:1 + rubber band". Travel asymptote ≈ `d · π/2`.
    /// - d: resistance scale (where the plate starts to brake noticeably).
    static func resist(_ x: CGFloat, d: CGFloat) -> CGFloat {
        guard d > 0 else { return x }
        return (x < 0 ? -1 : 1) * d * CGFloat(atan(Double(abs(x) / d)))
    }

    /// Neighbor cutoff radius. Beyond it the multiplier is 0.
    static let cutoff: CGFloat = 6
    
}
