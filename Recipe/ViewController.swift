//
//  ViewController.swift
//  Recipe
//
//  Created by Pranav Wadhwa on 5/2/17.
//  Copyright © 2017 Sixth Key. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import SCLAlertView

var myPage = Page()
var myUID = String()


struct Page {
    var title: String = ""
    var userId: String = ""
    var pfp: UIImage = UIImage()
    var tags: [String] = []
    var likes: [String] = []
    var pfpURL: String = ""
}

func delay(_ seconds: Double, completion: @escaping () -> ()) {
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
        completion()
    }
}

class ViewController: UIViewController {
    
//    var background1 = UIImageView()
//    var background2 = UIImageView()
//    var background3 = UIImageView()
//    var background4 = UIImageView()
//    
//    var currentImage = 1
//    
//    func moveBG() {
//        UIView.animate(withDuration: 0.5, animations: {
//            self.background1.frame.origin.x -= self.view.frame.size.width
//        })
//        UIView.animate(withDuration: 0.5, animations: {
//            self.background2.frame.origin.x -= self.view.frame.size.width
//        })
//        UIView.animate(withDuration: 0.5, animations: {
//            self.background3.frame.origin.x -= self.view.frame.size.width
//        })
//        UIView.animate(withDuration: 0.5, animations: {
//            self.background4.frame.origin.x -= self.view.frame.size.width
//        })
//        delay(1) { 
//            for bg in [self.background1, self.background2, self.background3, self.background4] {
//                if bg.frame.origin.x < (self.view.frame.size.width / 2) {
//                    bg.frame.origin.x = self.view.frame.size.width +  (self.view.frame.size.width * 2)
//                }
//            }
//        }
//        
//        
//    }
//    
    
    @IBOutlet var coverView: UIView!
    func errorAndContinue() {
        let appearance = SCLAlertView.SCLAppearance(
            
            showCloseButton: false
        )
        let alert = SCLAlertView(appearance: appearance)
        alert.addButton("Ok") { 
            self.performSegue(withIdentifier: "goToFeed", sender: self)
        }
        SCLAlertView().showError("Whoops!", subTitle: "We were unable to completely load all of your data. Please try again later. If the error persists, please contact us.")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if UserDefaults.standard.value(forKey: "hasCompletedOnboarding") == nil {
            self.performSegue(withIdentifier: "onboard", sender: self)
            return
        }
        
        if UserDefaults.standard.value(forKey: "signUpComplete") == nil {
            UIView.animate(withDuration: 0.5, animations: {
                self.coverView.alpha = 0
            })
            return
        } else {
            if UserDefaults.standard.value(forKey: "setUpComplete") != nil {
//                self.performSegue(withIdentifier: "goToFeed", sender: self)
            } else {
                self.performSegue(withIdentifier: "goToSetUp", sender: self)
                return
            }
        }
        print("start")
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {
            //SCLAlertView().showError("Error", subTitle: "Unable to authenticate.")
            self.errorAndContinue()
            return
        }
        myUID = uid
        print(myUID)
        let pageRef = FIRDatabase.database().reference().child("Pages").queryOrdered(byChild: "UserID").queryEqual(toValue: myUID)
        pageRef.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let dict = snapshot.value as? [String: [String: Any]] else {
                self.errorAndContinue()
                return
            }
            print(dict)
            for value in dict.values {
                print("1")
                print(value)
                    guard let pageID = value["UserID"] as? String else {
                        continue
                    }
                    guard let likes = value["Likes"] as? [String] else {
                        continue
                    }
                    if pageID != myUID {
                        print("continue")
                        continue
                    }
                    guard let name = value["PageName"] as? String else {
                        print(".3")
                        continue
                    }
                    guard let tags = value["Tags"] as? [String] else {
                        print(".4")
                        continue
                    }
                    guard let pfpUrl = value["PFPURL"] as? String else {
                        print(".5")
                        continue
                    }
                    print("2")
                    let cleanURL = (pfpUrl.components(separatedBy: "%2F")[1].components(separatedBy: "?alt=")[0])
                    let storageRef = FIRStorage.storage().reference()
                    let locationRef = storageRef.child("pages/" + cleanURL)
                    //possible reason the below may not work; although its running the code synchronously, the data retrieval is still asynchronous so it may not continue before the data is retrieved
                    DispatchQueue.global().async {
                        let _ = DispatchQueue.main.sync{
                            locationRef.data(withMaxSize: 100 * 1024 * 1024) { data, error in
                                if let _ = error {
                                    self.errorAndContinue()
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
                                    
                                    self.performSegue(withIdentifier: "goToFeed", sender: self)
                                    
                                }
                            }
                        }
                    
                    
                }
            }
        })
        
        
        
        
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
//        for i in 1...[background1, background2, background3, background4].count {
//            let image = [background1, background2, background3, background4][i - 1]
//            image.image = UIImage(named: "bg" + String(i))
//            
//            image.contentMode = .scaleAspectFill
//            image.frame = self.view.frame
//            image.frame.origin.x += self.view.frame.size.width * (CGFloat(i))
//            image.addBorder(.all, colour: .green, thickness: 10)
//            image.clipsToBounds = true
//            self.view.addSubview(image)
//        }
//        moveBG()
//        Timer.scheduledTimer(timeInterval: 4, target: self, selector: #selector(moveBG), userInfo: nil, repeats: true)
        
        
        
    }
    
    func didSwipe() {
        self.performSegue(withIdentifier: "swipeAbout", sender: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        coverView.alpha = 1
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(didSwipe))
        swipe.direction = .up
        self.view.addGestureRecognizer(swipe)
//        guard let uid = FIRAuth.auth()?.currentUser?.uid else {
//            //SCLAlertView().showError("Error", subTitle: "Unable to authenticate.")
//            return
//        }
//        myUID = uid
//        var userIDsOfPagesLiked = [String]()
//        let pageRef = FIRDatabase.database().reference().child("Pages")
//        pageRef.observeSingleEvent(of: .value, with: { (snapshot) in
//            userIDsOfPagesLiked.removeAll()
//            for child in snapshot.children {
//                if let dict = child as? [String: Any] {
//                    guard let pageID = dict["UserID"] as? String else {
//                        continue
//                    }
//                    guard let likes = dict["Likes"] as? [String] else {
//                        continue
//                    }
//                    if pageID != myUID {
//                        continue
//                    }
//                    guard let name = dict["PageName"] as? String else {
//                        continue
//                    }
//                    guard let tags = dict["Tags"] as? [String] else {
//                        continue
//                    }
//                    guard let pfpUrl = dict["PFPURL"] as? String else {
//                        continue
//                    }
//                    let cleanURL = (pfpUrl.components(separatedBy: "%2F")[1].components(separatedBy: "?alt=")[0])
//                    let storageRef = FIRStorage.storage().reference()
//                    let locationRef = storageRef.child("posts/" + cleanURL)
//                    //possible reason the below may not work; although its running the code synchronously, the data retrieval is still asynchronous so it may not continue before the data is retrieved
//                    DispatchQueue.global().async {
//                        let _ = DispatchQueue.main.sync{
//                            locationRef.data(withMaxSize: 100 * 1024 * 1024) { data, error in
//                                if let _ = error {
//                                    self.errorAndContinue()
//                                    return//works?
//                                } else {
//                                    guard let data = data else {
//                                        self.errorAndContinue()
//                                        return
//                                    }
//                                    guard let image = UIImage(data: data) else {
//                                        self.errorAndContinue()
//                                        return
//                                    }
//                                    let page = Page(title: name, userId: pageID, pfp: image, tags: tags, likes: likes, pfpURL: pfpUrl)
//                                    myPage = page
//                                    
//                                    
//                                }
//                            }
//                        }
//                    }
//                    
//                    
//                }
//            }
//        })

        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

var holderView = UIView()

var customActivityIndicator = STLoadingGroup(side: 50, style: STLoadingStyle.zhihu)
var customActivityIndicator2 = STLoadingGroup(side: 60, style: STLoadingStyle.zhihu)

extension UIColor {
    
    class func legendary() -> UIColor {
        return UIColor(red: 57/255, green: 68/255, blue: 102/255, alpha: 1)
    }
    
}

extension UIViewController {
        
    func startActivity(shouldStopInteraction: Bool = true) {
        
        holderView.removeFromSuperview()
        
        holderView = UIView(frame: CGRect(x: self.view.center.x, y: self.view.center.y, width: 80, height: 80))
        
        holderView.backgroundColor = UIColor.darkGray.withAlphaComponent(0.75)
        holderView.alpha = 1
        holderView.frame = self.view.frame
        self.view.addSubview(holderView)
        self.view.bringSubview(toFront: holderView)
        
        customActivityIndicator.show(self.view)
        customActivityIndicator.startLoading()
        
        customActivityIndicator2.show(self.view)
        customActivityIndicator2.startLoading()
        
        if shouldStopInteraction == true {
            UIApplication.shared.beginIgnoringInteractionEvents()
        }
        
        
        
    }

    func stopActivity() {
        
        customActivityIndicator.stopLoading()
        customActivityIndicator2.stopLoading()
        if holderView.isHidden == false {
            holderView.isHidden = true
        }
        if UIApplication.shared.isIgnoringInteractionEvents == true {
            UIApplication.shared.endIgnoringInteractionEvents()
        }
        UIApplication.shared.endIgnoringInteractionEvents()
        
    }

}

class TabButton: UIButton {
    
    fileprivate var buttonCurrent: Bool = false
    
    override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        let originalRect = contentRect
        var newRect = contentRect
        newRect.size.width *= CGFloat(0.7)
        newRect.size.height *= 0.7
        newRect.origin.x = (originalRect.width / 2) - (newRect.size.width / 2)
        newRect.origin.y = (originalRect.height / 2) - (newRect.size.height / 2)
        
        return newRect
    }
    
    @IBInspectable var current: Bool {
        get {
            return self.current
        }
        set(newValue) {
            self.buttonCurrent = newValue
            imageView?.image = imageView?.image!.withRenderingMode(.alwaysTemplate)
            if newValue {
                self.isUserInteractionEnabled = false
                imageView?.image = UIImage(named: "tab" + String(describing: tag) + "-1")
                imageView?.backgroundColor = .legendary()
                self.backgroundColor = .legendary()
            } else {
                self.isUserInteractionEnabled = true
                
                imageView?.image = UIImage(named: "tab" + String(describing: tag) + "-2")
                imageView?.backgroundColor = .white
                self.backgroundColor = .white
            }
            
            
        }
    }
    
    override func awakeFromNib() {
        self.imageView?.contentMode = .scaleAspectFit
        self.addBorder(.top, colour: .legendary(), thickness: 2)
//        self.layer.borderColor = UIColor.legendary().cgColor
//        self.layer.borderWidth = 2
//        addTarget(self, action: #selector(switchVC), for: .touchUpInside)
    }
    
}

extension UIView {
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}


