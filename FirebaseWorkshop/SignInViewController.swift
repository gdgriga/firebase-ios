//
//  SignInViewController.swift
//  FirebaseWorkshop
//
//  Created by Romans Karpelcevs on 28/07/16.
//  Copyright © 2016 GDG. All rights reserved.
//

import UIKit
import FirebaseAuth

class SignInViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Firebase: Skip screen if logged in
    }

    @IBAction func signInTapped() {
        if let email = self.usernameField.text,
            let password = self.passwordField.text {
            FIRAuth.auth()?.signInWithEmail(email, password: password) { (user, error) in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                self.signInSuccessful()
            }
        }
    }

    @IBAction func signUpTapped() {
        if let email = self.usernameField.text,
            let password = self.passwordField.text {
            FIRAuth.auth()?.createUserWithEmail(email, password: password) { (user, error) in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                self.createUserInCustomDatabase()
                self.signInSuccessful()
            }
        }
    }

    @IBAction func googleSignInTapped() {
        // Firebase: authenticate with Google
    }

    private func signInSuccessful() {
        AppState.sharedInstance.ownUserID = FIRAuth.auth()?.currentUser?.uid
        self.performSegueWithIdentifier("SignedInSegue", sender: self)
    }

    private func createUserInCustomDatabase() {
        // Create a separate entity in non-auth database
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == self.usernameField {
            self.passwordField.becomeFirstResponder()
        } else if textField == self.passwordField {
            self.signInTapped()
        }
        return true
    }
}
