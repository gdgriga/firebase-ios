//
//  CardDetailsViewController.swift
//  FirebaseWorkshop
//
//  Created by Romans Karpelcevs on 29/07/16.
//  Copyright © 2016 GDG. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseStorage

class CardDetailsViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var assigneeButton: UIButton!
    @IBOutlet weak var listButton: UIButton!
    @IBOutlet weak var attachmentImageView: UIImageView!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var createButton: UIBarButtonItem!
    @IBOutlet weak var removeAttachmentButton: UIButton!

    var cardItem: [String: String]?
    var cardSnapshot: FIRDataSnapshot?
    var originalCollection: String?
    var isCreating: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()

        if self.isCreating {
            self.navigationItem.setRightBarButtonItems([self.createButton], animated: false)
        } else {
            self.navigationItem.setRightBarButtonItems([self.deleteButton], animated: false)
            self.cardItem = self.cardSnapshot?.value as? [String: String]
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

            if let imageURL = item[ItemKey.Attachment] {
                self.loadImageAttachment(imageURL)
                self.removeAttachmentButton.enabled = true
            } else {
                self.attachmentImageView.image = nil
                self.removeAttachmentButton.enabled = false
            }
        }
    }

    private func loadImageAttachment(imageURL: String) {
        FIRStorage.storage().referenceForURL(imageURL).dataWithMaxSize(INT64_MAX){ (data, error) in
            if let error = error {
                print("Error downloading: \(error)")
                return
            }
            self.attachmentImageView.image = UIImage.init(data: data!)
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

        if !isCreating {
            self.saveDataToExistingCard()
        }
    }

    private func saveDataToExistingCard() {
        if let cardItem = self.cardItem,
            let databaseReference = self.cardSnapshot?.ref {
            self.updateUserKarma()
            databaseReference.setValue(cardItem)
        }
    }

    private func updateUserKarma() {
        if let ownUserID = AppState.sharedInstance.ownUserID,
            let ownUserDict = AppState.sharedInstance.allUsers[ownUserID] {
            let newKarmaValue = self.userKarmaPoints(ownUserDict)

            AppState.sharedInstance.allUsers[ownUserID]?[UserKey.Karma] = newKarmaValue
            let databaseRef = FIRDatabase.database().reference()
            databaseRef.child("users").child(ownUserID).child(UserKey.Karma).setValue(newKarmaValue)
        }
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
        self.deleteAttachmentFromStorage()
        self.cardSnapshot?.ref.removeValue()
        self.cardItem = nil
        self.navigationController?.popViewControllerAnimated(true)
    }

    @IBAction func createTapped(sender: UIBarButtonItem) {
        if let cardItem = self.cardItem {
            let databaseRef = FIRDatabase.database().reference()
            databaseRef.child("tasks").childByAutoId().setValue(cardItem)
        }
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
        if let image = (info[UIImagePickerControllerEditedImage] ?? info[UIImagePickerControllerOriginalImage]) as? UIImage {
            self.deleteAttachmentFromStorage()
            self.uploadImageToStorage(image)
        }
    }

    private func uploadImageToStorage(image: UIImage) {
        let imageData = UIImageJPEGRepresentation(image, 0.8)
        let imagePath = "attachments/" + NSUUID().UUIDString + ".jpg"
        let metadata = FIRStorageMetadata()
        metadata.contentType = "image/jpeg"

        let storageRef = FIRStorage.storage().referenceForURL("gs://firedrill-7e4e5.appspot.com")

        storageRef.child(imagePath).putData(imageData!, metadata: metadata) { (metadata, error) in
            if let error = error {
                print("Error uploading: \(error)")
                return
            } else if let path = metadata?.path {
                self.cardItem?[ItemKey.Attachment] = storageRef.child(path).description
                self.attachmentImageView.image = image
            }
        }
    }

    @IBAction func removeAttachmentTapped(sender: UIButton) {
        self.deleteAttachmentFromStorage()
        self.cardItem?[ItemKey.Attachment] = nil
        self.applyCardContent()
    }

    private func deleteAttachmentFromStorage() {
        if let imageURL = self.cardItem?[ItemKey.Attachment] {
            FIRStorage.storage().referenceForURL(imageURL).deleteWithCompletion() { error in
                if let error = error {
                    print("Removing attachment failed: \(error.localizedDescription)")
                }
            }
        }
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
