import CoreGraphics



/// State of an active pull. Lives as `@State` in `TetherVStack`, mutated by the
/// gesture layer, read by the row layout.
struct TetherDragState: Equatable {


    /// Index of the lead plate (the one the gesture started under). `nil` - no pull.
    var leadIndex: Int?


    /// Horizontal offset of the lead plate in points (already passed through
    /// `TetherPhysics.resist`). Sign: + right, - left.
    var leadTranslation: CGFloat = 0


    /// Offset of row `index`, attenuated by its distance to the lead.
    func offset(for index: Int) -> CGFloat {
        guard let lead = leadIndex else { return 0 }
        let distance = CGFloat(index - lead)
        return leadTranslation * TetherPhysics.falloff(d: distance)
    }


}
