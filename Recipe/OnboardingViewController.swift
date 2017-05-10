//
//  OnboardingViewController.swift
//  Recipe
//
//  Created by Pranav Wadhwa on 5/9/17.
//  Copyright © 2017 Sixth Key. All rights reserved.
//

import UIKit

class OnboardingViewController: UIViewController, PaperOnboardingDataSource, PaperOnboardingDelegate {
    
    
    
    func onboardingDidTransitonToIndex(_ index: Int) {
        
    }
    
    func onboardingWillTransitonToIndex(_ index: Int) {
        
    }
    
    var nextButton = UIButton()
    
    func onboardingConfigurationItem(_ item: OnboardingContentViewItem, index: Int) {
        item.titleLabel?.minimumScaleFactor = 0.5
        item.titleLabel?.numberOfLines = 0
        if index == 0 {
            item.imageView?.layer.cornerRadius = 20
            item.imageView?.clipsToBounds = true
        }
        if index != 4 {
            nextButton.removeFromSuperview()
            return
        }
        nextButton = UIButton(frame: CGRect(x: 25, y: self.view.frame.size.height - 150, width: self.view.frame.size.width - 50, height: 55))
        nextButton.center.y = (self.view.frame.size.height * 4/5)
        nextButton.backgroundColor = UIColor.white
        nextButton.setTitleColor(.black, for: [])
        nextButton.setTitle("Get Started", for: [])
        nextButton.titleLabel?.font = UIFont(name: "Futura-Medium", size: 25)
        nextButton.layer.cornerRadius = 10
        nextButton.addTarget(self, action: #selector(getStarted), for: .touchUpInside)
        nextButton.isUserInteractionEnabled = true
        item.isUserInteractionEnabled = true
        item.addSubview(nextButton)
        self.view.addSubview(nextButton)
        
        
    }
    
    func getStarted() {
        print("get started")
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        
        self.performSegue(withIdentifier: "onboardcomplete", sender: self)
        
    }
    
    func onboardingItemAtIndex(_ index: Int) -> OnboardingItemInfo {
        
        return [
            (#imageLiteral(resourceName: "logo2"), "Welcome to\niBite", "Share recipes with your friends instantly!", #imageLiteral(resourceName: "logo1"), UIColor(red: 57/255, green: 68/255, blue: 102/255, alpha: 1), UIColor.white, UIColor.white, UIFont(name: "Futura-Medium", size: 30)!, UIFont(name: "Futura-Medium", size: 20)!),
            (#imageLiteral(resourceName: "tab4-1"), "Your Own Page", "Post your own homemade recipes so your fanbase can see them.", #imageLiteral(resourceName: "tab4-1"), UIColor(red: 57/255, green: 68/255, blue: 102/255, alpha: 1), UIColor.white, UIColor.white, UIFont(name: "Futura-Medium", size: 30)!, UIFont(name: "Futura-Medium", size: 20)!),
            (#imageLiteral(resourceName: "home"), "Subscribe to Pages", "Like other pages so you can view recipes they've posted.", #imageLiteral(resourceName: "home"), UIColor(red: 57/255, green: 68/255, blue: 102/255, alpha: 1), UIColor.white, UIColor.white, UIFont(name: "Futura-Medium", size: 30)!, UIFont(name: "Futura-Medium", size: 20)!),
            (#imageLiteral(resourceName: "globe"), "Discover", "Find new pages and discover new recipes to try", #imageLiteral(resourceName: "globe"), UIColor(red: 57/255, green: 68/255, blue: 102/255, alpha: 1), UIColor.white, UIColor.white, UIFont(name: "Futura-Medium", size: 30)!, UIFont(name: "Futura-Medium", size: 20)!),
            (#imageLiteral(resourceName: "plane"), "Get Started", "", #imageLiteral(resourceName: "plane"), UIColor(red: 57/255, green: 68/255, blue: 102/255, alpha: 1), UIColor.white, UIColor.white, UIFont(name: "Futura-Medium", size: 30)!, UIFont(name: "Futura-Medium", size: 20)!),
            ][index] as OnboardingItemInfo
    }
    
    func onboardingItemsCount() -> Int {
        return 5
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let onboarding = PaperOnboarding(itemsCount: 4)
        onboarding.dataSource = self
        onboarding.translatesAutoresizingMaskIntoConstraints = false
        onboarding.delegate = self
        onboarding.currentIndex(2, animated: false)
        onboarding.currentIndex(0, animated: false)
        view.addSubview(onboarding)
        
        for attribute: NSLayoutAttribute in [.left, .right, .top, .bottom] {
            let constraint = NSLayoutConstraint(item: onboarding,
                                                attribute: attribute,
                                                relatedBy: .equal,
                                                toItem: view,
                                                attribute: attribute,
                                                multiplier: 1,
                                                constant: 0)
            view.addConstraint(constraint)
        }
        
        
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
