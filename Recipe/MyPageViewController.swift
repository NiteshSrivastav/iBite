//
//  MyPageViewController.swift
//  Recipe
//
//  Created by Pranav Wadhwa on 5/2/17.
//  Copyright © 2017 Sixth Key. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseStorage
import SCLAlertView
import RSKImageCropper

class MyPageViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, RSKImageCropViewControllerDelegate, UITextViewDelegate {
    
    @IBOutlet weak var pfpImageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var heightConstraintImageView: NSLayoutConstraint!
    
    @IBAction func editProfilePicture(_ sender: Any) {
        
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        self.present(picker, animated: true, completion: nil)
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        guard let image = info[UIImagePickerControllerOriginalImage] as?  UIImage else {
            self.dismiss(animated: true, completion: nil)
            SCLAlertView().showError("Whoops!", subTitle: "We were unable to upload image. Please try again or contact us if the error persists.")
            return
        }
        
        self.dismiss(animated: true) {
            self.pfpImageView.image = image
            
            let vc = RSKImageCropViewController(image: self.pfpImageView.image!, cropMode: .circle)
            vc.avoidEmptySpaceAroundImage = true
            vc.isRotationEnabled = true
            vc.delegate = self
            self.show(vc, sender: true)
        }
        
    }
    
    func imageCropViewController(_ controller: RSKImageCropViewController, willCropImage originalImage: UIImage) {
        
    }
    
    func imageCropViewController(_ controller: RSKImageCropViewController, didCropImage croppedImage: UIImage, usingCropRect cropRect: CGRect, rotationAngle: CGFloat) {
        self.pfpImageView.image = croppedImage
        self.dismiss(animated: true, completion: nil)
        updatePFP()
    }
    
    func imageCropViewController(_ controller: RSKImageCropViewController, didCropImage croppedImage: UIImage, usingCropRect cropRect: CGRect) {
        self.pfpImageView.image = croppedImage
        self.dismiss(animated: true, completion: nil)
    }
    
    func imageCropViewControllerDidCancelCrop(_ controller: RSKImageCropViewController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func returnToOldImage(completion: @escaping () -> Void) {
        FIRStorage.storage().reference().child("pages").child(myPage.pfpURL).put(UIImageJPEGRepresentation(myPage.pfp, 0.75)!, metadata: nil) { (metadata, error) in
            self.stopActivity()
            if let error = error {
                SCLAlertView().showError("Whoops!", subTitle: "An unexpected error occurred. Please try again later or contact us if the error persists. Error code: " + String(error._code))
                self.pfpImageView.image = myPage.pfp
                return
            }
            DispatchQueue.main.sync(execute: completion)
        }
    }
    
    func updatePFP() {
        startActivity()
        
        let storage = FIRStorage.storage().reference().child("pages").child(myPage.pfpURL)//add the field pictureURL to struct page so u can delete
        storage.delete { (err) in
            if let error = err {
                self.stopActivity()
                SCLAlertView().showError("Whoops!", subTitle: "An unexpected error occurred. Please try again later or contact us if the error persists. Error code: " + String(error._code))
                self.pfpImageView.image = myPage.pfp
                return
            }
            let storageRef = FIRStorage.storage().reference()
            let fileRef = storageRef.child("pages/").child(UUID().uuidString + ".jpg")
            
            _ = fileRef.put(UIImageJPEGRepresentation(self.pfpImageView.image!, 0.75)!, metadata: nil) { (metadata, error) in
                if let error = error {
                    self.returnToOldImage {
                        SCLAlertView().showError("Whoops!", subTitle: "An unexpected error occurred. Please try again later or contact us if the error persists. Error code: " + String(error._code))
                        self.pfpImageView.image = myPage.pfp
                    }
                    return
                }
                let locRef = FIRDatabase.database().reference().child("Pages")
                let query = locRef.queryOrdered(byChild: "UserID").queryEqual(toValue: myPage.userId).ref
                guard let meta = metadata else {
                    self.returnToOldImage {
                        SCLAlertView().showError("Whoops!", subTitle: "Something went wrong. Please try again later.")
                    }
                    return
                }
                guard let downloadURL = meta.downloadURL() else {
                    self.returnToOldImage {
                        SCLAlertView().showError("Whoops!", subTitle: "Something went wrong. Please try again later.")
                    }
                    return
                }
                query.child("PFPURL").updateChildValues(["PFPURL": downloadURL as Any], withCompletionBlock: { (error, reference) in
                    if let error = error {
                        self.returnToOldImage {
                            SCLAlertView().showError("Whoops!", subTitle: "An unexpected error occurred. Please try again later or contact us if the error persists. Error code: " + String(error._code))
                            self.pfpImageView.image = myPage.pfp
                        }
                        return
                    }
                    DispatchQueue.global().async {
                        DispatchQueue.main.sync {
                            self.stopActivity()
                            myPage.pfp = self.pfpImageView.image!
                            myPage.pfpURL = (downloadURL.absoluteString.components(separatedBy: "%2F")[1].components(separatedBy: "?alt=")[0])
                        }
                    }
                })
            
                
            }
        }
        
    }
    
    var tagAlert = SCLAlertView()
    var tags = [String]()
    
    func textViewDidChange(_ textView: UITextView) {
        let text = textView.text.components(separatedBy: "\n")
        tags = text
        if tags.count > 15 {
            
            let appearance = SCLAlertView.SCLAppearance(
                
                showCloseButton: false
            )
            let alert = SCLAlertView(appearance: appearance)
            alert.addButton("Ok", action: {
                self.editPageTags(alert)
            })
            alert.showTitle("Whoops!", subTitle: "You cannot have more than 15 tags", style: .error)
            tagAlert.hideView()
        }
    }
    
    func toString(arr: [String]) -> String {
        var r = ""
        for element in arr {
            r += element
            if arr.index(of: r) != arr.count - 1 {
                r += "\n"
            }
        }
        return r
    }
    
    @IBAction func editPageTags(_ sender: Any) {
        
        let appearance = SCLAlertView.SCLAppearance(
            
            showCloseButton: false
        )
        tagAlert = SCLAlertView(appearance: appearance)
        self.automaticallyAdjustsScrollViewInsets = false
        let textField = tagAlert.addTextView()
        textField.text = toString(arr: tags)
        textField.font = UIFont(name: "Futura-Medium", size: 20)
        textField.delegate = self
        textField.textAlignment = .center
        tagAlert.addButton("Update") { 
            self.dismiss(animated: true, completion: nil)
            self.startActivity()
            let locRef = FIRDatabase.database().reference().child("Pages")
            let query = locRef.queryOrdered(byChild: "UserID").queryEqual(toValue: myPage.userId).ref
            query.updateChildValues(["Tags": self.tags], withCompletionBlock: { (e, refe) in
                if let error = e {
                    self.stopActivity()
                    SCLAlertView().showError("Whoops!", subTitle: "An unexpected error occurred. Please try again later or contact us if the error persists. Error code: " + String(error._code))
                    return
                }
                self.stopActivity()
                myPage.tags = self.tags
            })
        }
        tagAlert.addButton("Cancel") { 
            self.dismiss(animated: true, completion: nil)
        }
        tagAlert.showTitle("Edit Tags", subTitle: "Add up to 15 tag so people can find your page easily! Separate each tag by line.", style: SCLAlertViewStyle.edit)
        
    }
    
    
    @IBAction func viewPage(_ sender: Any) {
        
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "viewPage") as! ViewPageController
        vc.currentPage = myPage
        self.show(vc, sender: self)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        print(self.view.frame.size.height)
        
        if self.view.frame.size.height > 570 {
            heightConstraintImageView.constant = 250
            if self.view.frame.size.height > 670 {
                heightConstraintImageView.constant = 300
            }
        }
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.hidesBackButton = true
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.plain, target:nil, action:nil)
        self.navigationItem.backBarButtonItem?.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Futura-Medium", size: 20)!], for: [])
        print(myPage.title == "")
//        if myPage.title == "" {
//            var userIDsOfPagesLiked = [String]()
//            let pageRef = FIRDatabase.database().reference().child("Pages").queryOrdered(byChild: "UserID")
//            pageRef.observeSingleEvent(of: .value, with: { (snapshot) in
//                userIDsOfPagesLiked.removeAll()
//                if let dict = snapshot.value as? [String: [String: Any]] {
//                    print("snapshot to dict")
//                }
//                for child in snapshot.children {
//                    if let dict = child as? [String: [String: Any]] {
//                        print("dict")
//                        print(dict)
//                        guard let pageID = dict["UserID"] as? String else {
//                            continue
//                        }
//                        guard let likes = dict["Likes"] as? [String] else {
//                            continue
//                        }
//                        if likes.contains(myUID) {
//                            userIDsOfPagesLiked.append(pageID)
//                            myLikes = userIDsOfPagesLiked
//                        }
//                        if pageID != myUID {
//                            continue
//                        }
//                        guard let name = dict["PageName"] as? String else {
//                            continue
//                        }
//                        guard let tags = dict["Tags"] as? [String] else {
//                            continue
//                        }
//                        guard let pfpUrl = dict["PFPURL"] as? String else {
//                            continue
//                        }
//                        let storageRef = FIRStorage.storage().reference()
//                        let locationRef = storageRef.child("posts/" + pfpUrl)
//                        //possible reason the below may not work; although its running the code synchronously, the data retrieval is still asynchronous so it may not continue before the data is retrieved
//                        
//                        let _ = DispatchQueue.main.sync{
//                            locationRef.data(withMaxSize: 100 * 1024 * 1024) { data, error in
//                                if let _ = error {
//                                    return//works?
//                                } else {
//                                    guard let data = data else {
//                                        return
//                                    }
//                                    guard let image = UIImage(data: data) else {
//                                        return
//                                    }
//                                    let page = Page(title: name, userId: pageID, pfp: image, tags: tags, likes: likes, pfpURL: pfpUrl)
//                                    myPage = page
//                                    print(page)
//                                    self.pfpImageView.image = myPage.pfp
//                                    self.nameLabel.text = myPage.title
//                                    self.tags = myPage.tags
//                                }
//                            }
//                        }
//                        
//                    }
//                }
//                myLikes = userIDsOfPagesLiked
//            })
//        }
        
        
        pfpImageView.image = myPage.pfp
        nameLabel.text = myPage.title
        tags = myPage.tags
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
