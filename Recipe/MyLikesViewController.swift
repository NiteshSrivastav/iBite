//
//  MyLikesViewController.swift
//  Recipe
//
//  Created by Pranav Wadhwa on 5/7/17.
//  Copyright © 2017 Sixth Key. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseStorage
import FirebaseDatabase
import SCLAlertView

class MyLikesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
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
        cell.recipeImageView.contentMode = .scaleAspectFit
        cell.addBorder(.bottom, colour: .legendary(), thickness: 2)
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("FEED")
        print(feed.count)
        return feed.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 108 + imageWithImage(sourceImage: feed[indexPath.row].pictureURL, scaledToWidth: table.frame.size.width).size.height
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "postDetail") as! DetailViewController
        vc.selectedPost = feed[indexPath.row]
//        vc.likesPost = true
        vc.shouldSetLike = true
        table.deselectRow(at: indexPath, animated: true)
//        self.performSegue(withIdentifier: "viewDetail", sender: self)
        self.show(vc, sender: true)
        
    }
    
    var numberOfPostsLoaded = 0
    
    func refreshFeed() {
        numberOfPostsLoaded = 0
        refresher.beginRefreshing()
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {
            SCLAlertView().showError("Whoops!", subTitle: "We were unable to authenticate. Please try again later or contact us if the error persists.")
            refresher.endRefreshing()
            return
        }
        myUID = uid
        
        let likesRef = FIRDatabase.database().reference().child("Likes")
        likesRef.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let dict = snapshot.value as? [String: String] else {
                SCLAlertView().showError("Whoops!", subTitle: "An unexpected error occurred. Please try again later or contact us if the error persists.")
                self.refresher.endRefreshing();self.stopActivity();return
            }
            var likedPostIDs = [String]()
            for like in dict {
                if like.value == myUID {
                    likedPostIDs.append(like.key)
                }
            }
            let ref = FIRDatabase.database().reference().child("Posts")
            ref.observeSingleEvent(of: .value, with: { (snap) in
                guard let posts = snap.value as? [String: [String: Any]] else {
                    SCLAlertView().showError("Whoops!", subTitle: "An unexpected error occurred. Please try again later or contact us if the error persists.")
                    self.refresher.endRefreshing();self.stopActivity();return
                }
                
                var likedPosts = [String: [String: Any]]()
                for post in posts {
                    if likedPostIDs.contains(post.key) {
                        likedPosts[post.key] = post.value
                    }
                }
                if likedPostIDs.count == 0 {
                    SCLAlertView().showError("Whoops!", subTitle: "You haven't like any posts yet! Tap on the discover (2nd) tab to discover new posts.")
                    self.refresher.endRefreshing();self.stopActivity();return
                }
                var actualPosts = [Post]()
                for post in likedPosts {
                    let dictionary = post.value
                    guard let user = dictionary["PostedByUser"] as? String else {
                        SCLAlertView().showError("Whoops!", subTitle: "We were unable to retrieve data. Please try again later or contact us if the error persists.")
                        self.refresher.endRefreshing();self.stopActivity();return
                    }
                        guard let recipeName = dictionary["RecipeName"] as? String else {
                            SCLAlertView().showError("Whoops!", subTitle: "We were unable to retrieve data. Please try again later or contact us if the error persists.")
                            self.refresher.endRefreshing();self.stopActivity();return
                        }
                        guard let recipe = dictionary["Recipe"] as? String else {
                            SCLAlertView().showError("Whoops!", subTitle: "We were unable to retrieve data. Please try again later or contact us if the error persists.")
                            self.refresher.endRefreshing();self.stopActivity();return
                        }
                        guard let url = dictionary["PictureURL"] as? String else {
                            SCLAlertView().showError("Whoops!", subTitle: "We were unable to retrieve data. Please try again later or contact us if the error persists.")
                            self.refresher.endRefreshing();self.stopActivity();return
                        }
                        let cleanURL = (url.components(separatedBy: "%2F")[1].components(separatedBy: "?alt=")[0])
                        guard let date = dictionary["Date"] as? String else {
                            SCLAlertView().showError("Whoops!", subTitle: "We were unable to retrieve data. Please try again later or contact us if the error persists.")
                            self.refresher.endRefreshing();self.stopActivity();return
                        }
                        guard let postedByPage = dictionary["PostedByPage"] as? String else {
                            SCLAlertView().showError("Whoops!", subTitle: "We were unable to retrieve data. Please try again later or contact us if the error persists.")
                            self.refresher.endRefreshing();self.stopActivity();return
                        }
                        
                        self.downloadImage(cleanURL: cleanURL, completion: { (image) in
                            let newPost = Post(recipeName: recipeName, recipe: recipe, pictureURL: image, postedByUser: user, postedByPage: postedByPage, date: date, postID: post.key)
                            actualPosts.append(newPost)
                            if actualPosts.count == likedPosts.count {
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
                
                
                
                
                
                
                
//                var filteredPosts = [Post]()//[String: [String: Any]]()
//                var keys = [String]()
//                for post in dict{
//                    keys.append(post.key)
//                }
//                for i in 0..<posts.count - 1 {
//                    let post = posts[i]
//                    print(post)
//                    if likedPostIDs.contains(post.key) {
//                        let dictionary = post.value
//                        if let user = dictionary["PostedByUser"] as? String {
//                            guard let recipeName = dictionary["RecipeName"] as? String else {
//                                SCLAlertView().showError("Whoops!", subTitle: "We were unable to retrieve data. Please try again later or contact us if the error persists.")
//                                self.refresher.endRefreshing();self.stopActivity();return
//                            }
//                            guard let recipe = dictionary["Recipe"] as? String else {
//                                SCLAlertView().showError("Whoops!", subTitle: "We were unable to retrieve data. Please try again later or contact us if the error persists.")
//                                self.refresher.endRefreshing();self.stopActivity();return
//                            }
//                            guard let url = dictionary["PictureURL"] as? String else {
//                                SCLAlertView().showError("Whoops!", subTitle: "We were unable to retrieve data. Please try again later or contact us if the error persists.")
//                                self.refresher.endRefreshing();self.stopActivity();return
//                            }
//                            let cleanURL = (url.components(separatedBy: "%2F")[1].components(separatedBy: "?alt=")[0])
//                            guard let date = dictionary["Date"] as? String else {
//                                SCLAlertView().showError("Whoops!", subTitle: "We were unable to retrieve data. Please try again later or contact us if the error persists.")
//                                self.refresher.endRefreshing();self.stopActivity();return
//                            }
//                            guard let postedByPage = dictionary["PostedByPage"] as? String else {
//                                SCLAlertView().showError("Whoops!", subTitle: "We were unable to retrieve data. Please try again later or contact us if the error persists.")
//                                self.refresher.endRefreshing();self.stopActivity();return
//                            }
//                            
//                            self.downloadImage(cleanURL: cleanURL, completion: { (image) in
//                                let newPost = Post(recipeName: recipeName, recipe: recipe, pictureURL: image, postedByUser: user, postedByPage: postedByPage, date: date, postID: keys[i])
//                                filteredPosts.append(newPost)
//                                self.numberOfPostsLoaded += 1
//                                print(self.numberOfPostsLoaded)
//                                print(likedPostIDs)
//                                if self.numberOfPostsLoaded == likedPostIDs.count {
//                                    print("done")
//                                    self.numberOfPostsLoaded = 0
//                                    print(i)
//                                    print(filteredPosts)
////                                    if i == filteredPosts.count - 1 {
//                                        self.feed = filteredPosts
//                                        self.table.reloadData()
//                                        self.refresher.endRefreshing()
//                                        self.stopActivity()
////                                    }
//                                }
//                                
//                            })
//                        }
//                    }
//                }
//                
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

extension Dictionary {
    subscript(i:Int) -> (key:Key,value:Value) {
        get {
            return self[index(startIndex, offsetBy: i)]
        }
    }
}
