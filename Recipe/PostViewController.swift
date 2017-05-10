//
//  PostViewController.swift
//  Recipe
//
//  Created by Pranav Wadhwa on 5/2/17.
//  Copyright © 2017 Sixth Key. All rights reserved.
//

import UIKit
import FirebaseStorage
import SCLAlertView
import FirebaseDatabase
import FirebaseAuth

class PostViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate {
    
    @IBOutlet weak var nameLabel: PlaceholderTextView! {
        didSet {
            nameLabel.delegate = self
        }
    }
    @IBOutlet weak var recipeLabel: PlaceholderTextView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet var invalidLabel: UIButton!
    @IBAction func invalid(_ sender: Any) {
        SCLAlertView().showError("Whoops!", subTitle: "In order to make the name displayable, please keep the number of characters under 35. ")
        let text = nameLabel.text
        nameLabel.text = ""
        for i in 0...34 {
            nameLabel.text = nameLabel.text + String((text?[i])!)
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if (textView.text.characters.count > 35)  {
            invalidLabel.isUserInteractionEnabled = true
            invalidLabel.isHidden = false
        } else {
            invalidLabel.isUserInteractionEnabled = false
            invalidLabel.isHidden = true
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        for textView in [nameLabel, recipeLabel] {
            textView?.setContentOffset(CGPoint.zero, animated: false)
        }
        
    }
    
    @IBAction func uploadImage(_ sender: Any) {
        
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        self.present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        self.dismiss(animated: true, completion: nil)
        guard let image = info[UIImagePickerControllerOriginalImage] as?  UIImage else {
            SCLAlertView().showError("Whoops!", subTitle: "We were unable to upload your image. Please try again or contact us if the error persists.")
            return
        }
        imageView.image = image
        
    }
    
    
    @IBAction func postRecipe(_ sender: Any) {
        if nameLabel.text == "" || recipeLabel.text == "" {
            SCLAlertView().showError("Whoops!", subTitle: "Please enter the recipe name and instructions")
            return
        }
        if nameLabel.text.characters.count > 35 {
            SCLAlertView().showError("Whoops!", subTitle: "Your recipe name is invalid. It may not be over 35 characters long.")
            return
        }
        guard let image = imageView.image else {
            SCLAlertView().showError("Whoops!", subTitle: "Please upload an image")
            return
        }
        if imageView.image == #imageLiteral(resourceName: "placeholder1") {
            SCLAlertView().showError("Whoops!", subTitle: "Please upload an image")
            return
        }
        startActivity()
        let storage = FIRStorage.storage()
        let storageRef = storage.reference()
        
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {
            stopActivity()
            SCLAlertView().showError("Whoops!", subTitle: "We were unable to authenticate. Please try again or contact us if the error persists.")
            return
        }
        
        let fileRef = storageRef.child("posts/").child(UUID().uuidString + ".jpg")
        
        _ = fileRef.put(UIImageJPEGRepresentation(imageWithImage(sourceImage: image, scaledToWidth: self.view.frame.size.width), 1)!, metadata: nil) { (metadata, error) in
            if let error = error {
                self.stopActivity()
                SCLAlertView().showError("Whoops!", subTitle: "An unexpected error occurred. Please try again later or contact us if the error persists. Error code: " + String(error._code))
                return
            } else {
                let downloadURL = metadata!.downloadURL()
                if myPage.title == "" {
                    getMyPage()
                }
                let  dictionary: [String: Any] = ["RecipeName": self.nameLabel.text, "Recipe": self.recipeLabel.text, "PictureURL": downloadURL!.absoluteString, "PostedByPage": myPage.title, "PostedByUser": uid, "Date": Date().getString()]
                
                let reference = FIRDatabase.database().reference().child("Posts").childByAutoId()
                reference.setValue(dictionary, withCompletionBlock: { (error, ref) in
                    if let error = error {
                        self.stopActivity()
                        SCLAlertView().showError("Whoops!", subTitle: "An unexpected error occurred. Please try again later or contact us if the error persists. Error code: " + String(error._code))
                        return
                    }
                    self.stopActivity()
                    self.performSegue(withIdentifier: "posted", sender: self)
                })
                
            }
        }
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
    
    func hideKeyboard(){
        self.view.endEditing(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let button = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(hideKeyboard))
        self.navigationItem.rightBarButtonItem = button
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.plain, target:nil, action:nil)
        self.navigationItem.backBarButtonItem?.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Futura-Medium", size: 20)!], for: [])
        
        
        nameLabel.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

func getMyPage() {
    DispatchQueue.global().async {
        DispatchQueue.main.sync {
            guard let uid = FIRAuth.auth()?.currentUser?.uid else {
                //SCLAlertView().showError("Whoops!", subTitle: "Unable to authenticate.")
                return
            }
            myUID = uid
            var userIDsOfPagesLiked = [String]()
            let pageRef = FIRDatabase.database().reference().child("Pages")
            pageRef.observeSingleEvent(of: .value, with: { (snapshot) in
                userIDsOfPagesLiked.removeAll()
                for child in snapshot.children {
                    if let dict = child as? [String: Any] {
                        guard let pageID = dict["UserID"] as? String else {
                            continue
                        }
                        guard let likes = dict["Likes"] as? [String] else {
                            continue
                        }
                        if likes.contains(myUID) {
                            userIDsOfPagesLiked.append(pageID)
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
                        let storageRef = FIRStorage.storage().reference()
                        let locationRef = storageRef.child("posts/" + cleanURL)
                        //possible reason the below may not work; although its running the code synchronously, the data retrieval is still asynchronous so it may not continue before the data is retrieved
                        DispatchQueue.global().async {
                            let _ = DispatchQueue.main.sync{
                                locationRef.data(withMaxSize: 100 * 1024 * 1024) { data, error in
                                    if let _ = error {
                                        return//works?
                                    } else {
                                        guard let data = data else {
                                            return
                                        }
                                        guard let image = UIImage(data: data) else {
                                            return
                                        }
                                        let page = Page(title: name, userId: pageID, pfp: image, tags: tags, likes: likes, pfpURL: pfpUrl)
                                        myPage = page
                                        
                                    }
                                }
                            }
                        }
                        
                        
                    }
                }
            })
            
        }
    }
}

extension String {
    
    subscript (i: Int) -> Character {
        return self[index(startIndex, offsetBy: i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    subscript (r: Range<Int>) -> String {
        let start = index(startIndex, offsetBy: r.lowerBound)
        let end = index(startIndex, offsetBy: r.upperBound - r.lowerBound)
        return self[Range(start ..< end)]
    }
}

extension UIViewController {
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
}

protocol PlaceholderTextViewDelegate {
    func placeholderTextViewDidChangeText(_ text:String)
    func placeholderTextViewDidEndEditing(_ text:String)
}

final class PlaceholderTextView: UITextView {
    
    var notifier:PlaceholderTextViewDelegate?
    
    var placeholder: String? {
        didSet {
            placeholderLabel?.text = placeholder
        }
    }
    var placeholderColor = UIColor.lightGray
    var placeholderFont = UIFont(name: "Futura-Medium", size: 17) {
        didSet {
            placeholderLabel?.font = placeholderFont
        }
    }
    
    @IBInspectable var ibPlaceholder: String? {
        get {
            return self.placeholder
        }
        set (value) {
            self.placeholder = value
        }
    }
    
    fileprivate var placeholderLabel: UILabel?
    
    // MARK: - LifeCycle
    
    init() {
        super.init(frame: CGRect.zero, textContainer: nil)
        awakeFromNib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(PlaceholderTextView.textDidChangeHandler(notification:)), name: .UITextViewTextDidChange, object: nil)
        
        placeholderLabel = UILabel()
        placeholderLabel?.textColor = placeholderColor
        placeholderLabel?.text = placeholder
        placeholderLabel?.textAlignment = .left
        placeholderLabel?.numberOfLines = 0
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        placeholderLabel?.font = placeholderFont
        
        var height:CGFloat = placeholderFont!.lineHeight
        if let data = placeholderLabel?.text {
            
            let expectedDefaultWidth:CGFloat = bounds.size.width
            let fontSize:CGFloat = placeholderFont!.pointSize
            
            let textView = UITextView()
            textView.text = data
            textView.font = UIFont(name: "Futura-Medium", size: fontSize)//UIFont.appMainFontForSize(fontSize)
            let sizeForTextView = textView.sizeThatFits(CGSize(width: expectedDefaultWidth,
                                                               height: CGFloat.greatestFiniteMagnitude))
            let expectedTextViewHeight = sizeForTextView.height
            
            if expectedTextViewHeight > height {
                height = expectedTextViewHeight
            }
        }
        
        placeholderLabel?.frame = CGRect(x: 5, y: 0, width: bounds.size.width - 16, height: height)
        
        if text.isEmpty {
            addSubview(placeholderLabel!)
            bringSubview(toFront: placeholderLabel!)
        } else {
            placeholderLabel?.removeFromSuperview()
        }
    }
    
    func textDidChangeHandler(notification: Notification) {
        layoutSubviews()
    }
    
}

extension PlaceholderTextView : UITextViewDelegate {
    // MARK: - UITextViewDelegate
//    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
//        if(text == "\n") {
//            textView.resignFirstResponder()
//            return false
//        }
//        return true
//    }
    
    func textViewDidChange(_ textView: UITextView) {
        notifier?.placeholderTextViewDidChangeText(textView.text)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        notifier?.placeholderTextViewDidEndEditing(textView.text)
    }
}

//class PlaceholderTextView: UITextView {
//    
//    func textChanged() {
//        
//    }
//    
//    var placeholder: String = ""
//    
//    @IBInspectable var ibPlaceholder: String {
//        get {
//            return self.placeholder
//        }
//        set {
//            self.placeholder = ibPlaceholder
//        }
//    }
//    
//    override func awakeFromNib() {
//        let label = UILabel(frame: CGRect(x: 5, y: 0, width: self.frame.size.width - 5, height: 30))
//        label.font = self.font
//        label.textColor = .lightGray
//        label.text = self.placeholder
//        self.addSubview(label)
//        
//    }
//    
//}
