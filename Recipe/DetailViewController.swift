//
//  DetailViewController.swift
//  Recipe
//
//  Created by Pranav Wadhwa on 5/5/17.
//  Copyright © 2017 Sixth Key. All rights reserved.
//

import UIKit
import FirebaseStorage
import FirebaseDatabase
import SCLAlertView

class DetailViewController: UIViewController {

    @IBOutlet var pageButton: UIButton!
    @IBOutlet var likeButton: UIButton!
    @IBOutlet var recipeImageView: UIImageView!
    @IBOutlet var recipeNameLabel: UILabel!
    @IBOutlet var recipeTextView: UITextView!
    @IBOutlet var dateLabel: UILabel!
    
    var shouldSetLike: Bool?
    
    var selectedPost = Post()
    var likesPost: Bool? {
        didSet {
            if likesPost != nil {
                if likesPost! {
                    likeButton.setTitle("Liked", for: [])
                } else {
                    likeButton.setTitle("Like", for: [])
                }
            }
        }
    }
    
    @IBAction func goToPage(_ sender: Any) {
        print("go to page")
        startActivity()
        FIRDatabase.database().reference().child("Pages").queryOrdered(byChild: "UserID").queryEqual(toValue: selectedPost.postedByUser).observeSingleEvent(of: .value, with: { (snapshot) in
            guard let values = snapshot.value as? [String: [String: Any]] else {
                SCLAlertView().showError("Whoops!", subTitle: "Something went wrong. Please try again later or contact us if the error persists.")
                return
            }
            for child in values {
                 let dict = child.value
                    guard let pageID = dict["UserID"] as? String else {
                        continue
                    }
                    guard let likes = dict["Likes"] as? [String] else {
                        continue
                    }
                    if pageID != myUID {
                        continue
                    }
                    guard let name = dict["PageName"] as? String else {
                        continue
                    }
                    guard let tags = dict["Tags"] as? [String] else {
                        continue
                    }
                    guard let pfpUrl = dict["PFPURL"] as? String else {
                        continue
                    }
                    let cleanURL = (pfpUrl.components(separatedBy: "%2F")[1].components(separatedBy: "?alt=")[0])
                print(cleanURL)
                    let storageRef = FIRStorage.storage().reference()
                    let locationRef = storageRef.child("pages/" + cleanURL)
                    DispatchQueue.global().async {
                        let _ = DispatchQueue.main.sync{
                            locationRef.data(withMaxSize: 100 * 1024 * 1024) { data, error in
                                if let error = error {
                                    self.stopActivity()
                                    SCLAlertView().showError("Whoops!", subTitle: "An unexpected error occurred. Please try again later or contact us if the error persists. Error code: " + String(error._code))
                                    return//works?
                                } else {
                                    guard let data = data else {
                                        self.stopActivity()
                                        SCLAlertView().showError("Whoops!", subTitle: "Something went wrong. Please try again later or contact us if the error persists.")
                                        return
                                    }
                                    guard let image = UIImage(data: data) else {
                                        self.stopActivity()
                                        SCLAlertView().showError("Whoops!", subTitle: "Something went wrong. Please try again later or contact us if the error persists.")
                                        return
                                    }
                                    self.stopActivity()
                                    let page = Page(title: name, userId: pageID, pfp: image, tags: tags, likes: likes, pfpURL: cleanURL)
                                    let vc = self.storyboard?.instantiateViewController(withIdentifier: "viewPage") as! ViewPageController
                                    vc.currentPage = page
                                    print("show viewPage")
                                    self.show(vc, sender: self)
                                    
                                }
                            }
                        }
                    }
                
            }
            
        })
        
        
        
    }
    
    @IBAction func likePost(_ sender: Any) {
        self.likeButton.setTitle("", for: [])
        let indicator = UIActivityIndicatorView(frame: self.likeButton.frame)
        indicator.color = UIColor.legendary()
        self.view.addSubview(indicator)
        indicator.startAnimating()
        
        if likesPost == nil {
            let ref = FIRDatabase.database().reference().child("Likes")//child("Likes")//queryOrdered(byChild: "Likes").queryEqual(toValue: myUID)
            ref.observeSingleEvent(of: .value, with: { (snap) in
                guard let dict = snap.value as? [String: String] else {
                    indicator.stopAnimating()
                    print("snap value is nil")
                    self.likesPost = false
                    self.performLike()
                    print("perform like")
                    return
                }
                for value in dict {
                    //&& value.value == self.selectedPost.postedByUser
                    if value.key == self.selectedPost.postID && value.value == myUID  {
                        self.likesPost = true
                    }
                }
                if self.likesPost == nil {
                    
                    self.likesPost = false
                }
                indicator.stopAnimating()
                self.performLike()
            })
        } else {
            indicator.stopAnimating()
            performLike()
        }
        
        
    }
    
    func performLike() {
        
        self.likesPost = !self.likesPost!
        if self.likesPost! {
            self.likeButton.setTitle("", for: [])
            let indicator = UIActivityIndicatorView(frame: self.likeButton.frame)
            indicator.color = UIColor.legendary()
            self.view.addSubview(indicator)
            indicator.startAnimating()
            let ref = FIRDatabase.database().reference().child("Likes").child(self.selectedPost.postID)
            ref.setValue(myUID, withCompletionBlock: { (e, refe) in
                indicator.stopAnimating()
                print("retreived")
                if let error = e {
                    self.likesPost = !self.likesPost!
                    self.likeButton.setTitle("Like", for: .normal)
                    indicator.stopAnimating()
                    SCLAlertView().showError("Whoops!", subTitle: "An unexpected error occurred. Please try again later or contact us if the error persists. Error code: " + String(error._code))
                    return
                }
                indicator.stopAnimating()
                self.likesPost = true
                self.likeButton.setTitle("Liked", for: .normal)
            })
            
            
        } else {
            
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Unlike", style: .destructive, handler: { (action) in
                self.likeButton.setTitle("", for: [])
                let indicator = UIActivityIndicatorView(frame: self.likeButton.frame)
                indicator.color = UIColor.legendary()
                self.view.addSubview(indicator)
                indicator.startAnimating()
                self.likeButton.setTitle("", for: [])
                let ref = FIRDatabase.database().reference().child("Likes").child(self.selectedPost.postID)
                ref.removeValue(completionBlock: { (e, refe) in
                    indicator.stopAnimating()
                    print("4")
                    if let error = e {
                        indicator.stopAnimating()
                        self.likesPost = !self.likesPost!
                        self.likeButton.setTitle("Liked", for: .normal)
                        SCLAlertView().showError("Whoops!", subTitle: "An unexpected error occurred. Please try again later or contact us if the error persists. Error code: " + String(error._code))
                        return
                    }
                    indicator.stopAnimating()
                    self.likesPost = false
                    self.likeButton.setTitle("Like", for: .normal)
                })
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
                self.likeButton.setTitle("Liked", for: [])
            }))
            self.present(alert, animated: true, completion: nil)
            
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if shouldSetLike != nil {
            likesPost = shouldSetLike
            shouldSetLike = nil
        }
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        pageButton.setTitle(selectedPost.postedByPage, for: [])
        recipeImageView.image = selectedPost.pictureURL
        recipeNameLabel.text = selectedPost.recipeName
        recipeTextView.text = selectedPost.recipe
        dateLabel.text = selectedPost.date
        
        
        if likesPost == nil {
            let ref = FIRDatabase.database().reference().child("Likes")//child("Likes")//queryOrdered(byChild: "Likes").queryEqual(toValue: myUID)
            ref.observeSingleEvent(of: .value, with: { (snap) in
                guard let dict = snap.value as? [String: String] else {
//                    indicator.stopAnimating()
                    print("snap value is nil")
                    self.likesPost = false
                    print("perform like")
                    return
                }
                for value in dict {
                    //&& value.value == self.selectedPost.postedByUser
                    if value.key == self.selectedPost.postID && value.value == myUID  {
                        self.likesPost = true
                    }
                }
                if self.likesPost == nil {
                    
                    self.likesPost = false
                }
//                indicator.stopAnimating()
//                self.performLike()
//                guard let dict = snap.value as? [String: String] else {
//                    return
//                }
//                for value in dict {
//                    if value.key == myUID && value.value == self.selectedPost.postedByUser {
//                        self.likesPost = true
//                    }
//                }
//                if self.likesPost == nil {
//                    self.likesPost = false
//                }
//                print("ater")
//                print(self.likesPost)
            })
        }
        
    }
    
    override func willMove(toParentViewController parent: UIViewController?) {
        if parent == nil {
            print("goes back")
            feedShouldNotReload = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        likeButton.addBorder(.top, colour: UIColor.legendary(), thickness: 2)
        
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.plain, target:nil, action:nil)
        self.navigationItem.backBarButtonItem?.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Futura-Medium", size: 20)!], for: [])
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

extension UIButton {
    open override func awakeFromNib() {
        super.awakeFromNib()
        
        self.titleLabel?.minimumScaleFactor = 0.5
    }
}


