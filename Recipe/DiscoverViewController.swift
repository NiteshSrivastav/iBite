//
//  DiscoverViewController.swift
//  Recipe
//
//  Created by Pranav Wadhwa on 5/2/17.
//  Copyright © 2017 Sixth Key. All rights reserved.
//

import UIKit
import FirebaseDatabase
import SCLAlertView
import FirebaseStorage

class DiscoverViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    @IBOutlet var instructionsLabel: UILabel!
    var filteredPagePostNames = [String]()
    var filteredPagePostIDs = [String]()
    var filteredPageNamesOfPosts = [String]()

    @IBOutlet weak var searchBar: UISearchBar! {
        didSet {
            searchBar.delegate = self
        }
    }
    @IBOutlet weak var table: UITableView!
    @IBOutlet var segmentedControl: UISegmentedControl!
    @IBAction func segmentChanged(_ sender: Any) {
        search()
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        search()
    }
    
    func search() {
        searchBar.endEditing(true)
        if segmentedControl.selectedSegmentIndex == 0 {
            startActivity()
            let ref = FIRDatabase.database().reference().child("Pages")
            ref.observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
                guard let dict = snapshot.value as? [String: [String: Any]] else {
                    self.stopActivity()
                    SCLAlertView().showError("Whoops!", subTitle: "An unexpected error occurred. Please try again later or contact us if the error persists.")
                    return
                }
                self.filteredPagePostIDs.removeAll()
                self.filteredPagePostNames.removeAll()
                
                for value in dict {
                    let name = value.value["PageName"] as! String
                    let uid = value.value["UserID"] as! String
                    var tagString = String()
                    let tags = value.value["Tags"] as! [String]
                    for i  in 0..<(tags.count ) {
                        let tag = tags[i]
                        tagString += tag
                        if i < tags.count - 1 {
                            tagString += ", "
                        }
                    }
                    if name.lowercased().contains(self.searchBar.text!.lowercased()) || tagString.lowercased().contains(self.searchBar.text!.lowercased()){
                        self.filteredPagePostNames.append(name)
                        self.filteredPagePostIDs.append(uid)
                    }
                }
                
                DispatchQueue.global().async {
                    DispatchQueue.main.sync {
                        self.stopActivity()
                        print("reload")
                        self.table.reloadData()
                    }
                }
            })
        } else {
            startActivity()
            let ref = FIRDatabase.database().reference().child("Posts")
            ref.observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
                guard let dict = snapshot.value as? [String: [String: Any]] else {
                    self.stopActivity()
                    SCLAlertView().showError("Whoops!", subTitle: "An unexpected error occurred. Please try again later or contact us if the error persists.")
                    return
                }
                self.filteredPagePostIDs.removeAll()
                self.filteredPagePostNames.removeAll()
                self.filteredPageNamesOfPosts.removeAll()
                for value in dict {
                    let name = value.value["RecipeName"] as! String
                    let recipe = value.value["Recipe"] as! String
                    let pageName = value.value["PostedByPage"] as! String
                    let uid = value.key
                    if name.lowercased().contains(self.searchBar.text!.lowercased()) || recipe.lowercased().contains(self.searchBar.text!.lowercased()) {
                        self.filteredPagePostNames.append(name)
                        self.filteredPagePostIDs.append(uid)
                        self.filteredPageNamesOfPosts.append(pageName)
                    }
                }
                DispatchQueue.global().async {
                    DispatchQueue.main.sync {
                        self.stopActivity()
                        print("reload")
                        self.table.reloadData()
                    }
                }
            })
        }

    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if segmentedControl.selectedSegmentIndex == 0 {
            startActivity()
            
            FIRDatabase.database().reference().child("Pages").queryOrdered(byChild: "UserID").queryEqual(toValue: filteredPagePostIDs[indexPath.row]).observeSingleEvent(of: .value, with: { (snapshot) in
                guard let values = snapshot.value as? [String: [String: Any]] else {
                    SCLAlertView().showError("Whoops!", subTitle: "Something went wrong. Please try again later or contact us if the error persists.")
                    return
                }
                print(values)
                for child in values {
                    let dict = child.value
                    guard let pageID = dict["UserID"] as? String else {
                        continue
                    }
                    guard let likes = dict["Likes"] as? [String] else {
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
                    print(cleanURL)
                    let storageRef = FIRStorage.storage().reference()
                    let locationRef = storageRef.child("pages/" + cleanURL)
                    DispatchQueue.global().async {
                        let _ = DispatchQueue.main.sync{
                            locationRef.data(withMaxSize: 100 * 1024 * 1024) { data, error in
                                if let error = error {
                                    self.stopActivity()
                                    SCLAlertView().showError("Whoops!", subTitle: "An unexpected error occurred. Please try again later or contact us if the error persists. Error code: " + String(error._code))
                                    return//works?
                                } else {
                                    guard let data = data else {
                                        self.stopActivity()
                                        SCLAlertView().showError("Whoops!", subTitle: "Something went wrong. Please try again later or contact us if the error persists.")
                                        return
                                    }
                                    guard let image = UIImage(data: data) else {
                                        self.stopActivity()
                                        SCLAlertView().showError("Whoops!", subTitle: "Something went wrong. Please try again later or contact us if the error persists.")
                                        return
                                    }
                                    self.stopActivity()
                                    let page = Page(title: name, userId: pageID, pfp: image, tags: tags, likes: likes, pfpURL: cleanURL)
                                    let vc = self.storyboard?.instantiateViewController(withIdentifier: "viewPage") as! ViewPageController
                                    vc.currentPage = page
                                    print("show viewPage")
                                    self.show(vc, sender: self)
                                    
                                }
                            }
                        }
                    }
                    
                }
                
            })
        } else {
            
            startActivity()
            let ref = FIRDatabase.database().reference().child("Posts")
            ref.observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
                guard let dict = snapshot.value as? [String: [String: Any]] else {
                    self.stopActivity()
                    SCLAlertView().showError("Whoops!", subTitle: "An unexpected error occurred. Please try again later or contact us if the error persists.")
                    return
                }
                var keys = [String]()
                for value in dict {
                    keys.append(value.key)
                }
                for i in 0..<dict.values.count {
                    let dictionary = dict[keys[i]]!
                    if keys[i] != self.filteredPagePostIDs[indexPath.row] {
                        continue
                    }
                    if let user = dictionary["PostedByUser"] as? String {
                        guard let recipeName = dictionary["RecipeName"] as? String else {
                            SCLAlertView().showError("Whoops!", subTitle: "We were unable to retrieve data. Please try again later or contact us if the error persists.")
                             self.stopActivity();return
                        }
                        guard let recipe = dictionary["Recipe"] as? String else {
                            SCLAlertView().showError("Whoops!", subTitle: "We were unable to retrieve data. Please try again later or contact us if the error persists.")
                             self.stopActivity();return
                        }
                        guard let url = dictionary["PictureURL"] as? String else {
                            SCLAlertView().showError("Whoops!", subTitle: "We were unable to retrieve data. Please try again later or contact us if the error persists.")
                             self.stopActivity();return
                        }
                        let cleanURL = (url.components(separatedBy: "%2F")[1].components(separatedBy: "?alt=")[0])
                        guard let date = dictionary["Date"] as? String else {
                            SCLAlertView().showError("Whoops!", subTitle: "We were unable to retrieve data. Please try again later or contact us if the error persists.")
                             self.stopActivity();return
                        }
                        guard let postedByPage = dictionary["PostedByPage"] as? String else {
                            SCLAlertView().showError("Whoops!", subTitle: "We were unable to retrieve data. Please try again later or contact us if the error persists.")
                             self.stopActivity();return
                        }
                        self.downloadImage(cleanURL: cleanURL, completion: { (image) in
                            self.stopActivity()
                            let newPost = Post(recipeName: recipeName, recipe: recipe, pictureURL: image, postedByUser: user, postedByPage: postedByPage, date: date, postID: keys[i])
                            let vc = self.storyboard?.instantiateViewController(withIdentifier: "postDetail") as! DetailViewController
                            vc.selectedPost = newPost
                            self.show(vc, sender: true)
                        })
                    }
                }
            })
            
            
            
        }
        
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
                    self.stopActivity();return
                }
                guard let image = UIImage(data: data) else {
                    print("no image")
                    SCLAlertView().showError("Whoops!", subTitle: "We were unable to retrieve data. Please try again later or contact us if the error persists.")
                    self.stopActivity();return
                }
                print("image found")
                
                completion(image)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.instructionsLabel.isHidden = !(filteredPagePostNames.count == 0)
        if searchBar.text != "" && searchBar.text != nil {
            self.instructionsLabel.text = "No results found"
        } else {
            self.instructionsLabel.text = "Enter text in the search bar to discover new pages or posts!"
        }
        print(filteredPagePostNames)
        return filteredPagePostNames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        if segmentedControl.selectedSegmentIndex == 0 {
            cell = tableView.dequeueReusableCell(withIdentifier: "searchCell")!
            let label = cell.viewWithTag(1) as! UILabel
            label.text = filteredPagePostNames[indexPath.row]
            cell.accessoryType = .disclosureIndicator
            cell.addBorder(.bottom, colour: .legendary(), thickness: 2)
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: "postCell")!
            let post = cell.viewWithTag(1) as! UILabel
            post.text = filteredPagePostNames[indexPath.row]
            let page = cell.viewWithTag(2) as! UILabel
            page.text = filteredPageNamesOfPosts[indexPath.row]
            cell.accessoryType = .disclosureIndicator
            cell.addBorder(.bottom, colour: .legendary(), thickness: 2)
        }
        return cell
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.hidesBackButton = true
        table.delegate = self
        table.dataSource = self
        table.separatorColor = .clear
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.plain, target:nil, action:nil)
        self.navigationItem.backBarButtonItem?.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Futura-Medium", size: 20)!], for: [])
        
        self.segmentedControl.layer.cornerRadius = 0
        self.segmentedControl.layer.borderColor = segmentedControl.tintColor.cgColor//UIColor.legendary().cgColor
        self.segmentedControl.layer.borderWidth = 1
        self.segmentedControl.layer.masksToBounds = true
        
//        self.segmentedControl.layer.cornerRadius = 15.0;
//        self.segmentedControl.layer.borderColor = [UIColor whiteColor].CGColor;
//        self.segmentedControl.layer.borderWidth = 1.0f;
//        self.segmentedControl.layer.masksToBounds = YES
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}
