//
//  OtherProfilePage.swift
//  iosproject
//
//  Created by Daniel Levi on 10/22/25.
//

import UIKit
import MapKit
import Firebase
import FirebaseFirestore
import FirebaseAuth
import FirebaseDatabase

class OtherPost: UICollectionViewCell {
    @IBOutlet weak var otherSinglePost: UIImageView!
    
}



class OtherProfilePage: ModeViewController, UICollectionViewDelegate, UICollectionViewDataSource,UICollectionViewDelegateFlowLayout  {

    
    var otherUserNameText = ""
    var otherUserID = ""
    @IBOutlet weak var otherUserName: UILabel!
    
    @IBOutlet weak var otherBio: UILabel!
    
    @IBOutlet weak var otherOptionsBar: UISegmentedControl!
    
    @IBOutlet weak var otherGridOfPosts: UICollectionView!
    
    var posts: [UIImage] = [UIImage(named: "gsWithSoup")!, UIImage(named: "halfEaten")!,UIImage(named: "parisChoco")!,UIImage(named: "parisMatcha")!]
    
    var otherSelectedPostImage: UIImage?
    var otherSelectedPostIndex: Int = 0
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        otherGridOfPosts.dataSource = self
        otherGridOfPosts.delegate = self

        
//        otherUserName.text = otherUserNameText
        let db = Firestore.firestore()
        var ref : DatabaseReference!
        ref = Database.database().reference().child("users").child(otherUserID)
        ref.observeSingleEvent(of: .value) { snapshot in
            if let username = snapshot.childSnapshot(forPath: "userName").value as? String {
                self.otherUserName.text = username
            }
            if let bio = snapshot.childSnapshot(forPath: "bio").value as? String {
                self.otherBio.text = bio
            }
        }
        
        let layout = UICollectionViewFlowLayout()
                layout.minimumInteritemSpacing = 0 // No horizontal spacing
                layout.minimumLineSpacing = 0 // No vertical spacing
                layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0) // No padding
                otherGridOfPosts.collectionViewLayout = layout
                otherOptionsBar.selectedSegmentIndex = 0

    
        
        print(otherUserID)

        // Do any additional setup after loading the view.
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = otherGridOfPosts.dequeueReusableCell(withReuseIdentifier: "OtherPostCell", for: indexPath) as! OtherPost
        cell.otherSinglePost.image = posts[indexPath.item]
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numberOfColumns: CGFloat = 3.0
                let totalSpacing: CGFloat = 0.0
                let width = (collectionView.bounds.width - totalSpacing) / numberOfColumns
                return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        self.otherSelectedPostImage = posts[indexPath.row]
            self.otherSelectedPostIndex = indexPath.row
        performSegue(withIdentifier: "otherProfileToPost", sender: self)
        
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "otherProfileToPost", let vc = segue.destination as? PostPage {
            vc.selectedPostImage = otherSelectedPostImage.self
            vc.selectedPostIndex = otherSelectedPostIndex.self
            vc.userID = "DANIEL"
        }
    
    }
    
    @IBAction func otherChooseTab(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
            case 0:
                otherGridOfPosts.isHidden = false
            otherGridOfPosts.reloadData()
            case 1:
            otherGridOfPosts.isHidden = true
            case 2:
            otherGridOfPosts.isHidden = true
            default:
            otherGridOfPosts.isHidden = false
            }
        
        
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
