import UIKit

struct AppColors {
    static var screen: UIColor {
        ThemeManager.shared.currentMode == .dark ? UIColor(hex: "#B66F32") : UIColor.white
    }
    static var banner: UIColor {
        ThemeManager.shared.currentMode == .dark ? UIColor.black : UIColor(hex: "#B66F32")
    }
    static var secondaryBackground: UIColor {
        ThemeManager.shared.currentMode == .dark ? UIColor(hex: "#B66F32") : UIColor.white
    }
    static var text: UIColor {
        ThemeManager.shared.currentMode == .dark ? UIColor.white : UIColor.black
    }
    static var segmentedControlIndex: UIColor {
        ThemeManager.shared.currentMode == .dark ? UIColor.black : UIColor.white
    }
}
