#if os(iOS)
import SwiftUI

// MARK: - UIVisualEffectView+Representable

extension UIVisualEffectView {
    
    /// A UIVisualEffect SwiftUI Representable View
    struct Representable: UIViewRepresentable {
        
        // MARK: Properties
        
        /// The UIVisualEffect. Default value `UIBlurEffect(style: .regular)`
        var effect: UIVisualEffect = UIBlurEffect(style: .regular)
        
        // MARK: UIViewRepresentable
        
        /// Make UIVisualEffectView
        /// - Parameter context: The Context
        func makeUIView(
            context: Context
        ) -> UIVisualEffectView {
            .init(
                effect: self.effect
            )
        }
        
        /// Update UIVisualEffectView
        /// - Parameters:
        ///   - visualEffectView: The UIVisualEffectView
        ///   - context: The Context
        func updateUIView(
            _ visualEffectView: UIVisualEffectView,
            context: Context
        ) {
            visualEffectView.effect = self.effect
        }
        
    }
    
}
#endif
