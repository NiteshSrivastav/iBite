//
//  SignUpViewController.swift
//  Recipe
//
//  Created by Pranav Wadhwa on 5/2/17.
//  Copyright © 2017 Sixth Key. All rights reserved.
//

import UIKit
import SCLAlertView
import FirebaseAuth
import FirebaseDatabase

class SignUpViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var emailAddressField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var confirmPasswordField: UITextField!
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailAddressField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            confirmPasswordField.becomeFirstResponder()
        } else if confirmPasswordField == textField {
            self.view.endEditing(true)
            signUp(textField)
        }
        return true
    }
    
    @IBAction func signUp(_ sender: Any) {
        
        for field in [emailAddressField, passwordField, confirmPasswordField] {
            if field?.text == "" {
                SCLAlertView().showError("Whoops!", subTitle: "Please fill out all of your information to sign up.")
                return
            }
        }
        
        if passwordField.text != confirmPasswordField.text {
            SCLAlertView().showError("Whoops!", subTitle: "Your two passwords don't match.")
            return
        }
        guard let auth = FIRAuth.auth() else {
            SCLAlertView().showError("Whoops!", subTitle: "Unable to connect to the server. Please try again later. If the error persists, please contact us.")
            return
        }
        startActivity()
        auth.createUser(withEmail: emailAddressField.text!, password: passwordField.text!) { (user, error) in
            if error == nil {
                
                    self.stopActivity()
                UserDefaults.standard.set("completed sign up", forKey: "signUpComplete")
                    self.performSegue(withIdentifier: "successfulSignUp", sender: self)
                
                
            } else {
                self.stopActivity()
                SCLAlertView().showError("Whoops!", subTitle: "An unexpected error occurred. Please try again later or contact us if the error persists. Error code: " + String(error!._code))
            }
        }
        
    }
    
//    @IBAction func question(_ sender: Any) {
//        SCLAlertView().showInfo("Username", subTitle: "This is how the name that will display publically when you post your recipes.")
//    }
//    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        SCLAlertView().showInfo("Sign Up", subTitle: "Welcome to iBite! Please enter your email and create a password to sign up. Later, we will guide you through the process of signing up.")//remember when changing the name - ask papa to buy firebase database space just incase
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        for field in [emailAddressField, passwordField, confirmPasswordField] {
            field?.delegate = self
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}
