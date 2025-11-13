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
            case let tableCell as UITableViewCell:
                tableCell.backgroundColor = AppColors.secondaryBackground
            case let searchBarUI as UISearchBar:
                searchBarUI.barTintColor = AppColors.secondaryBackground
            case let collectionView as UICollectionView:
                collectionView.backgroundColor = AppColors.screen
            case let collectionViewCell as UICollectionViewCell:
                collectionViewCell.backgroundColor = AppColors.screen
            case let selectedSegmentedControl as UISegmentedControl:
                selectedSegmentedControl.selectedSegmentTintColor = AppColors.segmentedControlIndex
            default:
                if subview.tag == 100 {
                    subview.backgroundColor = AppColors.banner
                }
            }
            applyThemeRecursively(to: subview)
        }
    }
}
