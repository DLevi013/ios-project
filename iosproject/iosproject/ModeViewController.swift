//
//  ModeViewController.swift
//  iosproject
//
//  Created by Austin Nguyen on 10/22/25.
//

import UIKit

class ModeViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        applyTheme()
        NotificationCenter.default.addObserver(self, selector: #selector(applyTheme), name: .themeChanged, object: nil)
    }

    @objc func applyTheme() {
        view.backgroundColor = AppColors.screen
        applyThemeRecursively(to: view)
    }

    private func applyThemeRecursively(to view: UIView) {
        for subview in view.subviews {
            switch subview {
            case let label as UILabel:
                label.textColor = AppColors.text
            case let button as UIButton:
                button.tintColor = AppColors.text
            case let table as UITableView:
                table.backgroundColor = AppColors.secondaryBackground
            case let TableCell as UITableViewCell:
                TableCell.backgroundColor = AppColors.secondaryBackground
            case let SearchBarUI as UISearchBar:
                SearchBarUI.barTintColor = AppColors.secondaryBackground
            case let CollectionView as UICollectionView:
                CollectionView.backgroundColor = AppColors.screen
            case let CollectionViewCell as UICollectionViewCell:
                CollectionViewCell.backgroundColor = AppColors.screen
            case let SelectedSegmentedControl as UISegmentedControl:
                SelectedSegmentedControl.selectedSegmentTintColor = AppColors.segmentedControlIndex
        
            default:
                if subview.tag == 100 {
                    subview.backgroundColor = AppColors.banner
                }
            }
            applyThemeRecursively(to: subview)
        }
    }
}

struct AppColors {
    static var screen: UIColor {
        ThemeManager.shared.currentMode == .dark ? UIColor(hex: "#B66F32") : UIColor.white
    }
    static var banner: UIColor { // banner stays orange
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

extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255
        let b = CGFloat(rgb & 0x0000FF) / 255

        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

