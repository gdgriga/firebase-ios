//
//  CardDetailsViewController.swift
//  FirebaseWorkshop
//
//  Created by Romans Karpelcevs on 29/07/16.
//  Copyright © 2016 GDG. All rights reserved.
//

import UIKit

class CardDetailsViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var assigneeButton: UIButton!
    @IBOutlet weak var listButton: UIButton!
    @IBOutlet weak var attachmentImageView: UIImageView!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var createButton: UIBarButtonItem!
    @IBOutlet weak var removeAttachmentButton: UIButton!

    var cardItem: [String: String]?
    var originalCollection: String?
    var isCreating: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        if self.isCreating {
            self.navigationItem.setRightBarButtonItems([self.createButton], animated: false)
        } else {
            self.navigationItem.setRightBarButtonItems([self.deleteButton], animated: false)
            if let collection = self.cardItem?[ItemKey.Collection] {
                self.originalCollection = collection
            }
        }
        self.applyCardContent()
    }

    func applyCardContent() {
        if let item = self.cardItem {
            self.titleTextField.text = item[ItemKey.Title]
            self.assigneeButton.setTitle(self.userDisplayName(item[ItemKey.Assignee]), forState: .Normal)

            if let collection = item[ItemKey.Collection],
                let listTitle = CollectionTitleMap[collection] {
                self.listButton.setTitle(listTitle, forState: .Normal)
            }
        }
    }

    private func userDisplayName(userID: String?) -> String {
        guard let userID = userID,
            let userDict = AppState.sharedInstance.allUsers[userID],
            let email = userDict[UserKey.Email] as? String else {
                return "unassigned"
        }
        return email
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.updateUserKarma()
        // TODO: save changes in storage
    }

    private func updateUserKarma() {
         // use `self.userKarmaPoints(AppState.sharedInstance.allUsers[AppState.sharedInstance.ownUserID!])`
    }

    private func userKarmaPoints(user: [String: AnyObject]) -> Int {
        let karmaDiff = self.karmaDiff()
        if karmaDiff < 0 {
            return -1
        } else {
            let currentKarma = user[UserKey.Karma] as? Int ?? 0
            return currentKarma + karmaDiff
        }
    }

    private func karmaDiff() -> Int {
        guard let oldCollection = self.originalCollection,
            let oldCollectionIndex = Collection.all.indexOf(oldCollection),
            let newCollection = self.cardItem?[ItemKey.Collection],
            let newCollectionIndex = Collection.all.indexOf(newCollection) else { return 0 }
        return min(max(newCollectionIndex - oldCollectionIndex, -1), 1)
    }

    @IBAction func assigneeTapped(sender: UIButton) {
        let alertController = UIAlertController(title: "Assignee", message: nil, preferredStyle: .ActionSheet)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))

        for (userID, userDict) in AppState.sharedInstance.allUsers {
            let userAction = UIAlertAction(title: userDict[UserKey.Email] as? String, style: .Default) { _ in
                self.applyUserChange(userID)
            }
            alertController.addAction(userAction)
        }

        self.presentViewController(alertController, animated: true, completion: nil)
    }

    @IBAction func listTapped(sender: UIButton) {
        let alertController = UIAlertController(title: "List", message: nil, preferredStyle: .ActionSheet)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))

        for collection in Collection.all.map({ $0 }) {
            let userAction = UIAlertAction(title: CollectionTitleMap[collection], style: .Default) { _ in
                self.applyCollectionChange(collection)
            }
            alertController.addAction(userAction)
        }

        self.presentViewController(alertController, animated: true, completion: nil)
    }

    @IBAction func deleteTapped(sender: UIBarButtonItem) {
        // TODO: delete from storage
        self.navigationController?.popViewControllerAnimated(true)
    }

    @IBAction func createTapped(sender: UIBarButtonItem) {
        // TODO: Save data
        self.navigationController?.popViewControllerAnimated(true)
    }

    @IBAction func textFieldDidChangeText(textField: UITextField) {
        self.cardItem?[ItemKey.Title] = self.titleTextField.text
    }

    @IBAction func imageTapped(sender: UITapGestureRecognizer) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        self.presentViewController(picker, animated: true, completion:nil)
    }

    func imagePickerController(picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        picker.dismissViewControllerAnimated(true, completion:nil)
        let image = (info[UIImagePickerControllerEditedImage] ?? info[UIImagePickerControllerOriginalImage]) as? UIImage
        self.attachmentImageView.image = image
    }

    @IBAction func removeAttachmentTapped(sender: UIButton) {
    }

    private func applyUserChange(user: String) {
        self.cardItem?[ItemKey.Assignee] = user
        self.applyCardContent()
    }

    private func applyCollectionChange(collection: String) {
        self.cardItem?[ItemKey.Collection] = collection
        self.applyCardContent()
    }
}
