//
//  SettingsViewController.swift
//  Recipe
//
//  Created by Pranav Wadhwa on 5/5/17.
//  Copyright © 2017 Sixth Key. All rights reserved.
//

import UIKit
import FirebaseAuth
import SCLAlertView
import MessageUI

class SettingsViewController: UIViewController, MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        print("should dismiss")
        self.dismiss(animated: true, completion: nil)
        if result == .sent {
            SCLAlertView().showSuccess("Sent!", subTitle: "Thank you. We will try to get back to you as soon as possible!")
        } else if result == .failed || error != nil {
            SCLAlertView().showSuccess("Whoops!", subTitle: "An unexpected error occurred. Please try again later. Error code: " + String(error!._code))
        }
    }
    
    @IBAction func aboutRecipe(_ sender: Any) {
    }
    @IBAction func howToUse(_ sender: Any) {
        
            SCLAlertView().showInfo("Welcome to iBite!", subTitle: "Here's a quick reminder on how to use the app:\n\nFeed - view recent posts from pages you've liked\nDiscover - find new pages and posts\nMy Likes - see all of the posts you've liked\nMy Page - manage your page and add posts\nSettings - manage your account and learn about iBite\n\n We recommend you get started by discovering some pages (2nd tab). Enjoy using iBite!")
        
    }
    @IBAction func contactUs(_ sender: Any) {
        let mail = MFMailComposeViewController()
        mail.mailComposeDelegate = self
        mail.setToRecipients(["contact.sixthkey@gmail.com"])
        mail.setSubject("iBite Support")
        mail.setMessageBody("", isHTML: false)
        self.present(mail, animated: true, completion: nil)
    }
    
    @IBAction func logOut(_ sender: Any) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { (action) in
            do {
               try FIRAuth.auth()?.signOut()
                UserDefaults.standard.removeObject(forKey: "hasUsedFeed")
                UserDefaults.standard.removeObject(forKey: "signUpComplete")
                UserDefaults.standard.removeObject(forKey: "setUpComplete")
                self.performSegue(withIdentifier: "logOut", sender: self)
            } catch {
                SCLAlertView().showError("Whoops!", subTitle: "An unexpected error occurred. Please try again later or contact us if the error persists. Error code: " + String(error._code))
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.hidesBackButton = true
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
