//
//  FeedViewController.swift
//  Recipe
//
//  Created by Pranav Wadhwa on 5/2/17.
//  Copyright © 2017 Sixth Key. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth
import SCLAlertView

struct Post {
    var recipeName: String = ""
    var recipe: String = ""
    var pictureURL: UIImage = UIImage()
    var postedByUser: String = ""
    var postedByPage: String = ""
    var date: String = ""
    var postID: String = ""
}

var feedShouldNotReload = false

class FeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var table: UITableView!
    
    var refresher = UIRefreshControl()
    var feed = [Post]()
    
    
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
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! PlayerCell
        let post = feed[indexPath.row]
        cell.dateLabel.text = "  " + post.date
        cell.pageNameLabel.text = post.postedByPage
        cell.recipeNameLabel.text = "  " + post.recipeName
        cell.recipeImageView.contentMode = .scaleAspectFit
        cell.recipeImageView.image = imageWithImage(sourceImage: feed[indexPath.row].pictureURL, scaledToWidth: table.frame.size.width - 16)
        cell.imageViewHeightConstraint.constant = cell.recipeImageView.image!.size.height
        cell.addBorder(.bottom, colour: .legendary(), thickness: 2)
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return feed.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100 + imageWithImage(sourceImage: feed[indexPath.row].pictureURL, scaledToWidth: table.frame.size.width).size.height
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "postDetail") as! DetailViewController
        vc.selectedPost = feed[indexPath.row]
        self.show(vc, sender: true)
        table.deselectRow(at: indexPath, animated: true)
    }
    
    var numberOfPostsLoaded = 0
    
    func refreshFeed() {
        numberOfPostsLoaded = 0
        refresher.beginRefreshing()
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {
            SCLAlertView().showError("Whoops!", subTitle: "We were unable to authorize your account.")
            refresher.endRefreshing()
            return
        }
        var userIDsOfPagesLiked = [String]()
        let pageRef = FIRDatabase.database().reference().child("Pages")
        pageRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if let dict = snapshot.value as? [String: [String: Any]] {
                for value in dict.values {
                    if let likes = value["Likes"] as? [String] {
                        if likes.contains(uid) {
                            userIDsOfPagesLiked.append(value["UserID"] as! String)
                        }
                    } else {
                        SCLAlertView().showError("Whoops!", subTitle: "We were unable to retrieve data. Please try again later or contact us if the error persists.")
                        self.refresher.endRefreshing();self.stopActivity();return
                    }
                }
                if userIDsOfPagesLiked.count == 0 {
                    SCLAlertView().showError("Whoops!", subTitle: "You have not liked any pages yet! Go to the discover tab to like a page")
                    self.refresher.endRefreshing();self.stopActivity();return
                }
            } else {
                SCLAlertView().showError("Whoops!", subTitle: "We were unable to retrieve data. Please try again or contact us if the error persits.")
                self.refresher.endRefreshing();self.stopActivity();return
            }
            
            
            let ref = FIRDatabase.database().reference().child("Posts")
            ref.observeSingleEvent(of: .value, with: { (snap) in
                guard let dict = snap.value as? [String: [String: Any]] else {
                    print("error 3")
                    SCLAlertView().showError("Whoops!", subTitle: "We were unable to retrieve data. Please try again later or contact us if the error persists.")
                    self.refresher.endRefreshing();self.stopActivity();return
                }
                var filteredPosts = [String: [String: Any]]()
                for value in dict {
                    print(value.value)
                    if userIDsOfPagesLiked.contains(value.value["PostedByUser"] as! String) {
                        filteredPosts[value.key] = value.value
                    }
                    
                }
                if filteredPosts.count == 0 {
                    SCLAlertView().showError("Whoops!", subTitle: "You haven't like any pages yet! Tap on the discover (2nd) tab to discover new pages.")
                    self.refresher.endRefreshing();self.stopActivity();return
                }
                var actualPosts = [Post]()
                for i in 0..<filteredPosts.count {
                    let post = filteredPosts[i]
                    guard let user = post.value["PostedByUser"] as? String else {
                        SCLAlertView().showError("Whoops!", subTitle: "We were unable to retrieve data. Please try again later or contact us if the error persists.")
                        self.refresher.endRefreshing();self.stopActivity();return
                    }
                    guard let recipeName = post.value["RecipeName"] as? String else {
                        SCLAlertView().showError("Whoops!", subTitle: "We were unable to retrieve data. Please try again later or contact us if the error persists.")
                        self.refresher.endRefreshing();self.stopActivity();return
                    }
                    guard let recipe = post.value["Recipe"] as? String else {
                        SCLAlertView().showError("Whoops!", subTitle: "We were unable to retrieve data. Please try again later or contact us if the error persists.")
                        self.refresher.endRefreshing();self.stopActivity();return
                    }
                    guard let url = post.value["PictureURL"] as? String else {
                        SCLAlertView().showError("Whoops!", subTitle: "We were unable to retrieve data. Please try again later or contact us if the error persists.")
                        self.refresher.endRefreshing();self.stopActivity();return
                    }
                    let cleanURL = (url.components(separatedBy: "%2F")[1].components(separatedBy: "?alt=")[0])
                    guard let date = post.value["Date"] as? String else {
                        SCLAlertView().showError("Whoops!", subTitle: "We were unable to retrieve data. Please try again later or contact us if the error persists.")
                        self.refresher.endRefreshing();self.stopActivity();return
                    }
                    guard let postedByPage = post.value["PostedByPage"] as? String else {
                        SCLAlertView().showError("Whoops!", subTitle: "We were unable to retrieve data. Please try again later or contact us if the error persists.")
                        self.refresher.endRefreshing();self.stopActivity();return
                    }
                    self.downloadImage(cleanURL: cleanURL, completion: { (image) in
                        let newPost = Post(recipeName: recipeName, recipe: recipe, pictureURL: image, postedByUser: user, postedByPage: postedByPage, date: date, postID: post.key)
                        actualPosts.append(newPost)
                        if actualPosts.count == filteredPosts.count {
                            DispatchQueue.global().async {
                                DispatchQueue.main.sync {
                                    self.feed = actualPosts
                                    self.table.reloadData()
                                    self.refresher.endRefreshing()
                                    self.stopActivity()
                                }
                            }
                            
                        }
                        
                    })
                    
                }
            })
            
            

            
        })
        
    }
    
    func downloadImage(cleanURL: String, completion: @escaping (UIImage) -> ()) {
        let storage = FIRStorage.storage()
        let storageRef = storage.reference()
        
        let locationRef = storageRef.child("posts/" + cleanURL)
        locationRef.data(withMaxSize: 100 * 1024 * 1024) { data, error in
            if let error = error {
                print(error)
                SCLAlertView().showError("Whoops!", subTitle: error.localizedDescription)
            } else {
                guard let data = data else {
                    print("no data")
                    SCLAlertView().showError("Whoops!", subTitle: "We were unable to retrieve data. Please try again later or contact us if the error persists.")
                    self.refresher.endRefreshing();self.stopActivity();return
                }
                guard let image = UIImage(data: data) else {
                    print("no image")
                    SCLAlertView().showError("Whoops!", subTitle: "We were unable to retrieve data. Please try again later or contact us if the error persists.")
                    self.refresher.endRefreshing();self.stopActivity();return
                }
                print("image found")
                
                completion(image)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if UserDefaults.standard.value(forKey: "hasUsedFeed") == nil {
            SCLAlertView().showInfo("Welcome to iBite!", subTitle: "Here's a quick reminder on how to use the app:\n\nFeed - view recent posts from pages you've liked\nDiscover - find new pages and posts\nMy Likes - see all of the posts you've liked\nMy Page - manage your page and add posts\nSettings - manage your account and learn about iBite\n\n We recommend you get started by discovering some pages (2nd tab). Enjoy using iBite!")
            UserDefaults.standard.set(true, forKey: "hasUsedFeed")
            return
        }
        
        if !(feedShouldNotReload) {
            startActivity()
            refreshFeed()
        } else {
            feedShouldNotReload = false
        }
    
        
    }
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont(name: "Futura-Medium", size: 20) as Any, NSForegroundColorAttributeName: UIColor.legendary()]
        self.navigationController?.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.plain, target:nil, action:nil)
        self.navigationController?.navigationItem.backBarButtonItem?.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Futura-Medium", size: 20)!, NSForegroundColorAttributeName: UIColor.legendary()], for: [])
        self.navigationController?.navigationItem.backBarButtonItem?.title = ""
        self.navigationController?.navigationBar.tintColor = .legendary()
        self.navigationItem.backBarButtonItem?.title = ""
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.plain, target:nil, action:nil)
        self.navigationItem.backBarButtonItem?.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Futura-Medium", size: 20)!], for: [])
        
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)
        UINavigationBar.appearance().shadowImage = UIColor.legendary().as1ptImage()
        
        self.navigationItem.hidesBackButton = true
        
        table.delegate = self
        table.dataSource = self
        table.separatorColor = .clear
        table.estimatedRowHeight = UITableViewAutomaticDimension
        table.tintColor = .legendary()
        
        refresher.attributedTitle = NSAttributedString(string: "Refreshing", attributes: [NSFontAttributeName: UIFont(name: "Futura-Medium", size: 20)!])
        refresher.addTarget(self, action: #selector(refreshFeed), for: UIControlEvents.valueChanged)
        table.addSubview(refresher)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

extension UIViewController{
    var previousViewController:UIViewController?{
        if let controllersOnNavStack = self.navigationController?.viewControllers{
            let n = controllersOnNavStack.count
            //if self is still on Navigation stack
            if controllersOnNavStack.last === self, n > 1{
                return controllersOnNavStack[n - 2]
            }else if n > 0{
                return controllersOnNavStack[n - 1]
            }
        }
        return nil
    }
}

extension Date {
    func getString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy"
        let date = formatter.string(from: self)
        return date
    }
}

extension UIColor {
    func as1ptImage() -> UIImage {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        let ctx = UIGraphicsGetCurrentContext()
        self.setFill()
        ctx!.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}

extension UIView {
    
    
    func addBorder(_ edges: UIRectEdge, colour: UIColor = UIColor.white, thickness: CGFloat = 1) {
        
        var borders = [UIView]()
        
        func border() -> UIView {
            let border = UIView(frame: CGRect.zero)
            border.backgroundColor = colour
            border.translatesAutoresizingMaskIntoConstraints = false
            return border
        }
        
        if edges.contains(.top) || edges.contains(.all) {
            let top = border()
            addSubview(top)
            addConstraints(
                NSLayoutConstraint.constraints(withVisualFormat: "V:|-(0)-[top(==thickness)]",
                                               options: [],
                                               metrics: ["thickness": thickness],
                                               views: ["top": top]))
            addConstraints(
                NSLayoutConstraint.constraints(withVisualFormat: "H:|-(0)-[top]-(0)-|",
                                               options: [],
                                               metrics: nil,
                                               views: ["top": top]))
            borders.append(top)
        }
        
        if edges.contains(.left) || edges.contains(.all) {
            let left = border()
            addSubview(left)
            addConstraints(
                NSLayoutConstraint.constraints(withVisualFormat: "H:|-(0)-[left(==thickness)]",
                                               options: [],
                                               metrics: ["thickness": thickness],
                                               views: ["left": left]))
            addConstraints(
                NSLayoutConstraint.constraints(withVisualFormat: "V:|-(0)-[left]-(0)-|",
                                               options: [],
                                               metrics: nil,
                                               views: ["left": left]))
            borders.append(left)
        }
        
        if edges.contains(.right) || edges.contains(.all) {
            let right = border()
            addSubview(right)
            addConstraints(
                NSLayoutConstraint.constraints(withVisualFormat: "H:[right(==thickness)]-(0)-|",
                                               options: [],
                                               metrics: ["thickness": thickness],
                                               views: ["right": right]))
            addConstraints(
                NSLayoutConstraint.constraints(withVisualFormat: "V:|-(0)-[right]-(0)-|",
                                               options: [],
                                               metrics: nil,
                                               views: ["right": right]))
            borders.append(right)
        }
        
        if edges.contains(.bottom) || edges.contains(.all) {
            let bottom = border()
            addSubview(bottom)
            addConstraints(
                NSLayoutConstraint.constraints(withVisualFormat: "V:[bottom(==thickness)]-(0)-|",
                                               options: [],
                                               metrics: ["thickness": thickness],
                                               views: ["bottom": bottom]))
            addConstraints(
                NSLayoutConstraint.constraints(withVisualFormat: "H:|-(0)-[bottom]-(0)-|",
                                               options: [],
                                               metrics: nil,
                                               views: ["bottom": bottom]))
            borders.append(bottom)
        }
        
        for border in borders {
            self.addSubview(border)
        }
    }
    
}

class PlayerCell: UITableViewCell {
    
    @IBOutlet weak var recipeImageView: UIImageView!
    @IBOutlet weak var pageNameLabel: UILabel!
    @IBOutlet weak var recipeNameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet var detailButton: UIButton!
    
    @IBOutlet var imageViewHeightConstraint: NSLayoutConstraint!
    
    @IBAction func viewPost(_ sender: Any) {
    }
    
}
