//
//  BoardViewController.swift
//  FirebaseWorkshop
//
//  Created by Romans Karpelcevs on 29/07/16.
//  Copyright © 2016 GDG. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class BoardViewController: UIViewController {

    private var pagerController: PagerController!
    private var listViewControllers: [ListViewController]!

    @IBOutlet private weak var addButton: UIBarButtonItem!
    @IBOutlet private weak var avatarImage: UIImageView!

    private var databaseRef: FIRDatabaseReference?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.databaseRef = FIRDatabase.database().reference()
        self.loadUsersFromDatabase()

        self.listViewControllers = Collection.all.map() { key in
            let lvc = self.storyboard?.instantiateViewControllerWithIdentifier("ListViewController") as! ListViewController
            lvc.model = MockListModel.filter() { item in item[ItemKey.Collection] == key }
            return lvc
        }

        self.pagerController = PagerController(viewControllers: self.listViewControllers,
                                               titles: Collection.titles)
        self.pagerController.selectedPageChangedBlock = { index in
            self.addButton.enabled = index <= 1
        }
        self.addPager()
    }

    private func loadUsersFromDatabase() {
        self.databaseRef?.child("users").observeEventType(.Value) { (snapshot: FIRDataSnapshot) -> Void in
            if let users = snapshot.value as? UsersDictionary {
                AppState.sharedInstance.allUsers = users
            }
            self.displayAvatar()
        }
    }

    private func addPager() {
        self.addChildViewController(self.pagerController)
        self.view.addSubview(self.pagerController.view)
        self.view.sendSubviewToBack(self.pagerController.view)
        self.pagerController.view.frame = self.view.bounds
    }

    private func displayAvatar() {
        let authorizedUser = AppState.sharedInstance.allUsers[AppState.sharedInstance.ownUserID!]
        let karma = authorizedUser?[UserKey.Karma] as? Int ?? 0
        if karma < 0 {
            self.applyPigAvatar()
        } else if karma > 9 {
            self.applyUnicornAvatar()
        } else if let avatarURL = authorizedUser?[UserKey.Avatar] as? String where avatarURL.characters.count > 0 {
            self.loadAvatar(avatarURL)
        } else if let email = authorizedUser?[UserKey.Email] as? String {
            self.loadGravatar(email)
        }
    }

    private func applyPigAvatar() {
        self.avatarImage.image = UIImage(named: "pig")
        self.cropAvatarToRound()
    }

    private func applyUnicornAvatar() {
        self.avatarImage.image = UIImage(named: "unicorn")
        self.resetAvatarCrop()
    }

    private func loadGravatar(email: String) {
        let gravatarUrl = String(format: "https://www.gravatar.com/avatar/%@?d=404&s=200", email.gravatarHash())
        self.loadAvatar(gravatarUrl)
    }

    private func loadAvatar(urlString: String) {
        guard let url = NSURL(string: urlString) else { return }

        let request = NSURLRequest(URL: url)
        NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) in
            dispatch_async(dispatch_get_main_queue()) {
                if let data = data,
                    let image = UIImage(data: data) {
                    self.avatarImage.image = image
                    self.cropAvatarToRound()
                }
            }
        }.resume()
    }

    private func cropAvatarToRound() {
        self.avatarImage.layer.cornerRadius = CGRectGetWidth(self.avatarImage.frame) / 2;
        self.avatarImage.layer.masksToBounds = true;
    }

    private func resetAvatarCrop() {
        self.avatarImage.layer.masksToBounds = false;
    }

    @IBAction func signOutTapped() {
        try! FIRAuth.auth()?.signOut()
        GIDSignIn.sharedInstance().signOut()
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let destination = segue.destinationViewController as? CardDetailsViewController {
            destination.cardItem = [ItemKey.Collection: Collection.all[self.pagerController.selectedPageIndex]]
            destination.isCreating = true
        }
    }
}

private extension String {
    private func gravatarHash() -> String {
        return self
            .lowercaseString
            .stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            .md5()
    }

    private func md5() -> String {
        var digest = [UInt8](count: Int(CC_MD5_DIGEST_LENGTH), repeatedValue: 0)
        if let data = self.dataUsingEncoding(NSUTF8StringEncoding) {
            CC_MD5(data.bytes, CC_LONG(data.length), &digest)
        }

        var digestHex = ""
        for index in 0..<Int(CC_MD5_DIGEST_LENGTH) {
            digestHex += String(format: "%02x", digest[index])
        }
        
        return digestHex
    }
}
