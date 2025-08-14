import SwiftUI

extension View {
    func deviceAwareSheetSizing(
        compactMultiplier: (min: CGFloat, ideal: CGFloat, max: CGFloat),
        regularMultiplier: (min: CGFloat, ideal: CGFloat, max: CGFloat),
        largeMultiplier: (min: CGFloat, ideal: CGFloat, max: CGFloat)
    ) -> some View {
        let screenHeight = UIScreen.main.bounds.height
        let multiplier: (min: CGFloat, ideal: CGFloat, max: CGFloat)
        
        if screenHeight <= 670 { // iPhone SE, iPhone 13 mini
            multiplier = compactMultiplier
        } else if screenHeight <= 750 { // iPhone 14/15
            multiplier = regularMultiplier
        } else { // iPhone Plus/Pro Max
            multiplier = largeMultiplier
        }
        
        let sizing = (
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