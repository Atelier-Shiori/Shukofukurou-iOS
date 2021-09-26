//
//  UIColor+Defaults.swift
//  WhatsNewKit-iOS
//
//  Created by Sven Tiigi on 25.05.18.
//  Copyright © 2018 WhatsNewKit. All rights reserved.
//

import UIKit

// MARK: - isLight

extension UIColor {
    
    /// Retrieve Boolean if UIColor is light
    var isLight: Bool {
        var white: CGFloat = 0
        self.getWhite(&white, alpha: nil)
        return white > 0.5
    }
    
}

// MARK: - Template Colors

public extension UIColor {
    
    /// The WhatsNewKit background color
    static var whatsNewKitBackground: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { traitCollection in
                switch traitCollection.userInterfaceStyle {
                case .light, .unspecified:
                    return .whatsNewKitWhite
                case .dark:
                    return .whatsNewKitDark
                @unknown default:
                    return .whatsNewKitWhite
                }
            }
        } else {
            return .whatsNewKitWhite
        }
    }
    
    /// The WhatsNewKit background color
    static var whatsNewKitForeground: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { traitCollection in
                switch traitCollection.userInterfaceStyle {
                case .light, .unspecified:
                    return .whatsNewKitBlack
                case .dark:
                    return .whatsNewKitWhite
                @unknown default:
                    return .whatsNewKitBlack
                }
            }
        } else {
            return .whatsNewKitBlack
        }
    }
    
    /// The WhatsNewKit white color
    static let whatsNewKitWhite = UIColor(
        red: 1,
        green: 1,
        blue: 1,
        alpha: 1
    )
    
    /// The WhatsNewKit black color
    static let whatsNewKitBlack = UIColor(
        red: 0,
        green: 0,
        blue: 0,
        alpha: 1
    )
    
    /// The WhatsNewKit blue color
    static let whatsNewKitBlue = UIColor(
        red: 0,
        green: 122 / 255,
        blue: 1,
        alpha: 1
    )
    
    /// The WhatsNewKit light blue color
    static let whatsNewKitLightBlue = UIColor(
        red: 95 / 255,
        green: 200 / 255,
        blue: 248 / 255,
        alpha: 1
    )
    
    /// The WhatsNewKit dark color
    static let whatsNewKitDark = UIColor(
        red: 20 / 255,
        green: 29 / 255,
        blue: 38 / 255,
        alpha: 1
    )
    
    /// The WhatsNewKit purple color
    static let whatsNewKitPurple = UIColor(
        red: 183 / 255,
        green: 35 / 255,
        blue: 1,
        alpha: 1
    )
    
    /// The WhatsNewKit red color
    static let whatsNewKitRed = UIColor(
        red: 1,
        green: 45 / 255,
        blue: 85 / 255,
        alpha: 1
    )
    
    /// The WhatsNewKit green color
    static let whatsNewKitGreen = UIColor(
        red: 76 / 255,
        green: 217 / 255,
        blue: 100 / 255,
        alpha: 1
    )
    
}
