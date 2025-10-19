//
//  ProfilePage.swift
//  iosproject
//
//  Created by Daniel Levi on 10/17/25.
//

import UIKit


import UIKit

class Post: UICollectionViewCell {
    @IBOutlet weak var singlePost: UIImageView!
    
}



class ProfilePage: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var optionsBar: UISegmentedControl!
    
    @IBOutlet weak var gridOfPosts: UICollectionView!
    
    var posts: [UIImage] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        
        gridOfPosts.dataSource = self
        gridOfPosts.delegate = self
        let layout = UICollectionViewFlowLayout()
            let itemWidth = (gridOfPosts.bounds.width - 20) / 3
            layout.itemSize = CGSize(width: itemWidth - 5, height: itemWidth - 5)
            layout.minimumInteritemSpacing = 5
            layout.minimumLineSpacing = 5
            layout.sectionInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        gridOfPosts.collectionViewLayout = layout
            loadSamplePosts()
        optionsBar.selectedSegmentIndex = 0

        // Do any additional setup after loading the view.
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = gridOfPosts.dequeueReusableCell(withReuseIdentifier: "PostCell", for: indexPath) as! Post
        cell.singlePost.image = posts[indexPath.item]
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 20) / 3 - 5
        return CGSize(width: width, height: width)
    }
  
    
    @IBAction func choosingTab(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
            case 0:
                gridOfPosts.isHidden = false
            gridOfPosts.reloadData()
            default:
            gridOfPosts.isHidden = true
            }
    }
    
    
    func loadSamplePosts() {
        // Add your images to Assets.xcassets first
        posts = [UIImage(named: "foocation logo")!, UIImage(named: "houseLogo")!]
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
