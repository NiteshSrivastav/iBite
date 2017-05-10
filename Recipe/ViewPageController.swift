//
//  ViewPageController.swift
//  Recipe
//
//  Created by Pranav Wadhwa on 5/4/17.
//  Copyright © 2017 Sixth Key. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseStorage
import SCLAlertView

class ViewPageController: UIViewController {
    
    var pageId: String?
    
    var currentPage = Page()
    
    var actualGeneratedIdPage: String?
    
    func heightForView(text:String, font:UIFont, width:CGFloat) -> CGFloat{
        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = font
        label.text = text
        
        label.sizeToFit()
        return label.frame.height
    }
    
    @IBOutlet var tagHeightConstraint: NSLayoutConstraint!
    @IBOutlet var tagCenterConstraint: NSLayoutConstraint!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var pfpImageView: UIImageView!
    @IBOutlet var tagLabel: UILabel!
    @IBOutlet var numberOfLikesLabel: UILabel!
    @IBOutlet var likePageButton: UIButton!
    var goingRight = false
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        
        
    }
    
//    func rotate() {
//        if !goingRight {
//            UIView.animate(withDuration: 0.35) {
//                self.tagCenterConstraint.constant -= 5
//                self.view.layoutIfNeeded()
//                print(self.tagCenterConstraint.constant)
//                if self.tagCenterConstraint.constant  == -(self.view.frame.size.width) {
//                    self.goingRight = true
//                }
//            }
//        } else {
//            UIView.animate(withDuration: 0.35) {
//                self.tagCenterConstraint.constant += 5
//                self.view.layoutIfNeeded()
//                print(self.tagCenterConstraint.constant)
//                if self.tagCenterConstraint.constant  == (self.view.frame.size.width) {
//                    self.goingRight = false
//                }
//            }
//        }
//        
//        
////        tagLabel.text.substringWithRange(NSRange(location: 0, length: 3))
////        tagLabel.text = tagLabel.text.substringWithRange(Range<String.Index>(start: 1, end: tagLabel.text.endIndex - 1))
//    }
    
    var likesPage: Bool = false {
        didSet {
            if likesPage {
                likePageButton.setTitle("Liked", for: [])
                likePageButton.backgroundColor = .legendary()//UIColor.init(red: 52/255, green: 120/255, blue: 246/255, alpha: 1)
                likePageButton.setTitleColor(UIColor.white, for: [])
            } else {
                likePageButton.setTitle("Like", for: [])
                likePageButton.backgroundColor = .white
                likePageButton.setTitleColor(UIColor.legendary(), for: [])
            }
        }
    }
    
    func unlikePage() {
        print("unlike page")
        let indicator = UIActivityIndicatorView(frame: likePageButton.frame)
        indicator.color = UIColor.white
        self.view.addSubview(indicator)
        indicator.startAnimating()
        likePageButton.setTitle("", for: [])
        
        var hasObserved = false
        
        let pageRef = FIRDatabase.database().reference().child("Pages")
        pageRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if !hasObserved {
                hasObserved = true
            } else {
                return
            }
            
            guard let pages = snapshot.value as? [String: [String: Any]] else {
                indicator.stopAnimating()
                self.likePageButton.setTitle("Liked", for: [])
                SCLAlertView().showError("Whoops!", subTitle: "Something went wrong. Please try again later or contact us if the error persists.")
                return
            }
            for page in pages {
                guard var likes = page.value["Likes"] as? [String] else {
                    continue
                }
                if likes.contains(myUID) {
                    let index = likes.index(of: myUID)!
                    likes.remove(at: index)
                    print("DID REMOVE")
                } else {
                    print("2")
                    indicator.stopAnimating()
                    self.likePageButton.setTitle("Liked", for: [])
                    SCLAlertView().showError("Whoops!", subTitle: "Something went wrong. Please try again later or contact us if the error persists.")
                    return
                }
                print("new like")
                print(likes)
                let likeRef = pageRef.child(page.key).child("Likes")
                likeRef.removeValue()
                likeRef.setValue(likes, withCompletionBlock: { (err, reference) in
                    if let error = err {
                        indicator.stopAnimating()
                        SCLAlertView().showError("Whoops!", subTitle: "An unexpected error occurred. Please try again later or contact us if the error persists. Error code: " + String(error._code))
                        return
                    }
                    indicator.stopAnimating()
                    self.likesPage = false
                    self.currentPage.likes = likes
                    self.numberOfLikesLabel.text = String(self.currentPage.likes.count) + " people like this page"
                })
            }
        })

        
    }
    
    func likePage() {
        print("like page")
        let indicator = UIActivityIndicatorView(frame: likePageButton.frame)
        indicator.color = UIColor.white
        self.view.addSubview(indicator)
        indicator.startAnimating()
        likePageButton.setTitle("", for: [])
        
        
        let pageRef = FIRDatabase.database().reference().child("Pages")
        pageRef.observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard let pages = snapshot.value as? [String: [String: Any]] else {
                indicator.stopAnimating()
                self.likePageButton.setTitle("Like", for: [])
                self.likesPage = false
                print("error 1")
                SCLAlertView().showError("Whoops!", subTitle: "Something went wrong. Please try again later or contact us if the error persists.")
                return
            }
            for page in pages {
                if page.value["UserID"] as! String != self.currentPage.userId {
                    print(self.currentPage.userId)
                    continue
                }
                guard var likes = page.value["Likes"] as? [String] else {
                    continue
                }
                print(likes)
                print(myUID)
                if !likes.contains(myUID) {
                    likes.append(myUID)
                } else {
                    indicator.stopAnimating()
                    self.likePageButton.setTitle("Like", for: [])
                    self.likesPage = false
                    print("error 2")
                    SCLAlertView().showError("Whoops!", subTitle: "Something went wrong. Please try again later or contact us if the error persists.")
                    return
                }
                let likeRef = pageRef.child(page.key).child("Likes")
                likeRef.removeValue()
                likeRef.setValue(likes, withCompletionBlock: { (err, reference) in
                    if let error = err {
                        indicator.stopAnimating()
                        self.likePageButton.setTitle("Like", for: [])
                        self.likesPage = false
                        SCLAlertView().showError("Whoops!", subTitle: "An unexpected error occurred. Please try again later or contact us if the error persists. Error code: " + String(error._code))
                        return
                    }
                    indicator.stopAnimating()
                    self.likesPage = true
                    self.currentPage.likes = likes
                    self.numberOfLikesLabel.text = String(self.currentPage.likes.count) + " people like this page"
                })
            }
        })
        
        
    }
    
    
    @IBAction func likePage(_ sender: Any) {
        if likesPage {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Unlike", style: .destructive, handler: { (actun) in
                self.unlikePage()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            likePage()
        }
    }
    
    func contains(arr: [String], str: String) -> Bool {
        for i in 0..<arr.count {
            if arr[i] == str {
                return true
            }
        }
        return false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.titleLabel.text = self.currentPage.title
        self.pfpImageView.image = self.currentPage.pfp
        print(currentPage.likes)
        print(myUID)
        if currentPage.likes.contains(myUID) {
            print("contains")
            self.likesPage = true
        } else {
            self.likesPage = false
        }
        self.numberOfLikesLabel.text = String(currentPage.likes.count) + " people like this page"
        var tagString = String()
        for i  in 0..<(currentPage.tags.count ) {
            let tag = currentPage.tags[i]
            tagString += tag
            if i < currentPage.tags.count - 1 {
                tagString += ", "
            } else {
                tagString += "           "
            }
            tagLabel.text = "Tags: " + tagString
            tagHeightConstraint.constant = min(CGFloat(80), (heightForView(text: tagString, font: tagLabel.font, width: self.view.frame.size.width - 40)))
        }

        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
