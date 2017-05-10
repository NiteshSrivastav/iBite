//
//  SetupViewController.swift
//  Recipe
//
//  Created by Pranav Wadhwa on 5/3/17.
//  Copyright © 2017 Sixth Key. All rights reserved.
//

import UIKit
import SCLAlertView
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth
import RSKImageCropper

class SetupViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextViewDelegate, UITextFieldDelegate, RSKImageCropViewControllerDelegate {
    
    var tags = [String]()
    
    @IBAction func question(_ sender: Any) {
        SCLAlertView().showInfo("Edit your page", subTitle: "Your page is where you post your recipes. Come up with an original, creative name for your page as well as a beautiful profile picture and tags so users can find your page easily!")
    }
    
    @IBOutlet weak var pageTitle: UITextField! {
        didSet {
            pageTitle.delegate = self
        }
    }
    @IBOutlet weak var imageView: UIImageView!
    
    var shouldHideQuestion = false
    @IBAction func editProfilePic(_ sender: Any) {
        
        shouldHideQuestion = true
        
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false//turn on and edit options
        self.present(picker, animated: true, completion: nil)
    }
    
    var tagAlert = SCLAlertView()
    
    @IBAction func editPageTags(_ sender: Any) {
        tagAlert = SCLAlertView()
        self.automaticallyAdjustsScrollViewInsets = false
        let textField = tagAlert.addTextView()
        textField.text = toString(arr: tags)
        textField.font = UIFont(name: "Futura-Medium", size: 20)
        textField.delegate = self
        textField.textAlignment = .center
        tagAlert.showTitle("Edit Tags", subTitle: "Add up to 15 tag so people can find your page easily! Separate each tag by line.", style: SCLAlertViewStyle.edit)
    }
    
    
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
            alert.showTitle("Whoops!", subTitle: "You cannot have more than 15 tags. Please type in 15 tags or less.", style: .error)
            tagAlert.hideView()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !shouldHideQuestion {
            question(self)
        }
        shouldHideQuestion = false
        
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
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        guard let image = info[UIImagePickerControllerOriginalImage] as?  UIImage else {
            self.dismiss(animated: true, completion: nil)
            SCLAlertView().showError("Whoops!", subTitle: "We were unable to upload your image. Please try again later or contact us if the error persists.")
            return
        }
        
        self.dismiss(animated: true) { 
            self.imageView.image = image
            
            let vc = RSKImageCropViewController(image: self.imageView.image!, cropMode: .circle)
            vc.avoidEmptySpaceAroundImage = true
            vc.isRotationEnabled = true
            vc.delegate = self
            self.show(vc, sender: true)
        }
        
    }
    
    func imageCropViewController(_ controller: RSKImageCropViewController, willCropImage originalImage: UIImage) {
        
    }
    
    func imageCropViewController(_ controller: RSKImageCropViewController, didCropImage croppedImage: UIImage, usingCropRect cropRect: CGRect, rotationAngle: CGFloat) {
        self.imageView.image = croppedImage
        shouldHideQuestion = true
        self.dismiss(animated: true, completion: nil)
    }
    
    func imageCropViewController(_ controller: RSKImageCropViewController, didCropImage croppedImage: UIImage, usingCropRect cropRect: CGRect) {
        self.imageView.image = croppedImage
        shouldHideQuestion = true
        self.dismiss(animated: true, completion: nil)
    }
    
    func imageCropViewControllerDidCancelCrop(_ controller: RSKImageCropViewController) {
        shouldHideQuestion = true
        self.dismiss(animated: true, completion: nil)
    }
    
    func errorAndContinue() {
        let appearance = SCLAlertView.SCLAppearance(
            
            showCloseButton: false
        )
        let alert = SCLAlertView(appearance: appearance)
        alert.addButton("Ok") {
            self.performSegue(withIdentifier: "goToFeed", sender: self)
        }
        SCLAlertView().showError("Whoops!", subTitle: "We were unable to completely load all data. Please try again later or contact us if the error persists.")
    }
    
    func imageWithImage (sourceImage:UIImage, scaledToWidth: CGFloat) -> UIImage {
        let oldWidth = sourceImage.size.width
        let scaleFactor = scaledToWidth / oldWidth
        
        let newHeight = sourceImage.size.height * scaleFactor
        let newWidth = oldWidth * scaleFactor
        
        UIGraphicsBeginImageContext(CGSize(width:newWidth, height:newHeight))
        sourceImage.draw(in: CGRect(x:0, y:0, width:newWidth, height:newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }

    @IBAction func done(_ sender: Any) {
        if pageTitle.text == "" {
            SCLAlertView().showError("Whoops!", subTitle: "Please set the title of your page")
            return
        }
        if (pageTitle.text?.characters.count)! > 35 {
            SCLAlertView().showError("Whoops!", subTitle: "Your page name is invalid. It may not be over 35 characters long.")
            return
        }
        guard let image = imageView.image else {
            SCLAlertView().showError("Whoops!", subTitle: "Please upload a profile picture")
            return
        }
        if tags.count == 0 {
            SCLAlertView().showError("Whoops!", subTitle: "Please add tags to your page")
            return
        }
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {
            SCLAlertView().showError("Whoops!", subTitle: "Unable to authenticate. Please try again later or contact us if the error persists.")
            return
        }
        startActivity()
        let nameRef = FIRDatabase.database().reference().child("PageNames")
        nameRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if var name = snapshot.value as? [String] {
                if name.contains(self.pageTitle.text!) {
                    self.stopActivity()
                    SCLAlertView().showError("Whoops!", subTitle: "A page with the name \"" +  (self.pageTitle.text!) + "\" already exists. Please choose a different name.")
                    return
                }
                name.append(self.pageTitle.text!)
                nameRef.setValue(name, withCompletionBlock: { (err, referenc) in
                    if let error = err {
                        self.stopActivity()
                        SCLAlertView().showError("Whoops!", subTitle: "An unexpected error occurred. Please try again later or contact us if the error persists. Error code: " + String(error._code))
                        return
                    }
                    let storageRef = FIRStorage.storage().reference()
                    let fileRef = storageRef.child("pages/").child(UUID().uuidString + ".jpg")
                    
                    _ = fileRef.put(UIImageJPEGRepresentation(self.imageWithImage(sourceImage: image, scaledToWidth: self.view.frame.size.width), 1)!, metadata: nil) { (metadata, error) in
                        if let error = error {
                            self.stopActivity()
                            SCLAlertView().showError("Whoops!", subTitle: "An unexpected error occurred. Please try again later or contact us if the error persists. Error code: " + String(error._code))
                            return
                        } else {
                            let downloadURL = metadata!.downloadURL()
                            let  dictionary: [String: Any] = ["UserID": uid, "PageName": self.pageTitle.text!, "PFPURL": downloadURL!.absoluteString, "Tags": self.tags, "Likes": [uid]]
                            
                            let reference = FIRDatabase.database().reference().child("Pages").childByAutoId()
                            reference.setValue(dictionary, withCompletionBlock: { (error, ref) in
                                if let error = error {
                                    self.stopActivity()
                                    SCLAlertView().showError("Whoops!", subTitle: error.localizedDescription)
                                    return
                                }
                                self.stopActivity()
                                guard let uid = FIRAuth.auth()?.currentUser?.uid else {
                                    //SCLAlertView().showError("Whoops!", subTitle: "Unable to authenticate.")
                                    self.errorAndContinue()
                                    return
                                }
                                myUID = uid
                                myPage = Page(title: dictionary["PageName"] as! String, userId: dictionary["UserID"] as! String, pfp: self.imageWithImage(sourceImage: image, scaledToWidth: self.view.frame.size.width), tags: dictionary["Tags"] as! [String], likes: dictionary["Likes"] as! [String], pfpURL: dictionary["PFPURL"] as! String)
                                UserDefaults.standard.set("completed sign up", forKey: "setUpComplete")
                                self.performSegue(withIdentifier: "setupComplete", sender: self)
                            })
                            
                        }
                    }
                })
            }
            
            
        })
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}
