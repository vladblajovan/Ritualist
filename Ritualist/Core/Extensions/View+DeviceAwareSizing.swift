import SwiftUI

struct SizeMultiplier {
    let min: CGFloat
    let ideal: CGFloat
    let max: CGFloat
}

extension View {
    func deviceAwareSheetSizing(
        compactMultiplier: SizeMultiplier,
        regularMultiplier: SizeMultiplier,
        largeMultiplier: SizeMultiplier
    ) -> some View {
        let screenHeight = UIScreen.main.bounds.height
        let multiplier: SizeMultiplier
        
        if screenHeight <= 670 { // iPhone SE, iPhone 13 mini
            multiplier = compactMultiplier
        } else if screenHeight <= 750 { // iPhone 14/15
            multiplier = regularMultiplier
        } else { // iPhone Plus/Pro Max
            multiplier = largeMultiplier
        }
        
        let sizing = SizeMultiplier(
            min: screenHeight * multiplier.min,
            ideal: screenHeight * multiplier.ideal,
            max: screenHeight * multiplier.max
        )
        
        return self.responsiveSheetSizing(
            .adaptive(min: sizing.min, ideal: sizing.ideal, max: sizing.max),
            minHeight: sizing.min
        )
    }
}