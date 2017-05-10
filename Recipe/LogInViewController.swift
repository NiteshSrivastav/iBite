//
//  LogInViewController.swift
//  Recipe
//
//  Created by Pranav Wadhwa on 5/2/17.
//  Copyright © 2017 Sixth Key. All rights reserved.
//

import UIKit
import SCLAlertView
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

class LogInViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var emailAddressField: UITextField! {
        didSet {
            emailAddressField.delegate = self
        }
    }
    @IBOutlet weak var passwordField: UITextField! {
        didSet {
            passwordField.delegate = self
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailAddressField {
            passwordField.becomeFirstResponder()
        } else if passwordField == textField {
            self.view.endEditing(true)
            logIn(textField)
        }
        return true
    }
    
    @IBAction func resetPassword(_ sender: Any) {
        let appearance = SCLAlertView.SCLAppearance(
            
            showCloseButton: false
        )
        let alert = SCLAlertView(appearance: appearance)
        let textField = alert.addTextField()
        textField.font  = UIFont(name: "Futura-Medium", size: 17)
        textField.placeholder = "Email Address"
        textField.keyboardType = .emailAddress
        textField.autocapitalizationType = .none
        alert.addButton("Reset") {
            if textField.text == "" {
                let error = SCLAlertView(appearance: appearance)
                error.addButton("Ok", action: {
                    self.resetPassword(error)
                })
                error.showError("Whoops!", subTitle: "Please enter your email address so we can reset your password.")
                return
            }
            FIRAuth.auth()?.sendPasswordReset(withEmail: textField.text!, completion: { (er) in
                if let eror = er {
                    let error = SCLAlertView()
                    error.showError("Whoops!", subTitle: "An unexpected error occurred. Please try again later or contact us if the error persists. Error code: " + String(eror._code))
                    return
                }
                SCLAlertView().showSuccess("Password Reset Sent!", subTitle: "Check your email and follow the instructions to reset your password")
            })
        }
        alert.addButton("Cancel") { 
            
        }
        alert.showInfo("Password Reset", subTitle: "Enter your email address and we will send you instructions to reset your password")
        
    }
    
    func errorAndContinue() {
        let appearance = SCLAlertView.SCLAppearance(
            
            showCloseButton: false
        )
        let alert = SCLAlertView(appearance: appearance)
        alert.addButton("Ok") {
            self.performSegue(withIdentifier: "successfulLogIn", sender: self)
        }
        SCLAlertView().showError("Whoops!", subTitle: "We were unable to completely load all of your data. Please try again later or contact us if the error persists.")
    }
    
    @IBAction func logIn(_ sender: Any) {
        
        for field in [emailAddressField, passwordField] {
            if field?.text == "" {
                SCLAlertView().showError("Whoops!", subTitle: "Please fill out all of the fields")
                return
            }
        }
        
        
        guard let auth = FIRAuth.auth() else {
            SCLAlertView().showError("Whoops!", subTitle: "Something went wrong. Please try again later")
            return
        }
        startActivity()
        auth.signIn(withEmail: emailAddressField.text!, password: passwordField.text!, completion: { (user, error) in
            
            if error == nil {
                
                guard let uid = FIRAuth.auth()?.currentUser?.uid else {
                    //SCLAlertView().showError("Whoops!", subTitle: "Unable to authenticate.")
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
                        guard let pageID = value["UserID"] as? String else {
                            continue
                        }
                        guard let likes = value["Likes"] as? [String] else {
                            continue
                        }
                        if pageID != myUID {
                            continue
                        }
                        guard let name = value["PageName"] as? String else {
                            continue
                        }
                        guard let tags = value["Tags"] as? [String] else {
                            continue
                        }
                        guard let pfpUrl = value["PFPURL"] as? String else {
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
                                        self.stopActivity()
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
                                        self.stopActivity()
                                        UserDefaults.standard.set("completed sign up", forKey: "signUpComplete")
                                        UserDefaults.standard.set("completed sign up", forKey: "setUpComplete")
                                        self.performSegue(withIdentifier: "successfulLogIn", sender: self)
                                        
                                    }
                                }
                            }
                            
                            
                        }
                    }
                })
                
            } else {
                SCLAlertView().showError("Whoops!", subTitle: "An unexpected error occurred. Please try again later or contact us if the error persists. Error code: " + String(error!._code))
            }
        })
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
