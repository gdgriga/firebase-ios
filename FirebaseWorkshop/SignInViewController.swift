//
//  SignInViewController.swift
//  FirebaseWorkshop
//
//  Created by Romans Karpelcevs on 28/07/16.
//  Copyright © 2016 GDG. All rights reserved.
//

import UIKit

class SignInViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Firebase: Skip screen if logged in
    }

    @IBAction func signInTapped() {
        // Firebase: perform auth
        self.signInSuccessful()
    }

    @IBAction func signUpTapped() {
        // Firebase: perform sign up
        self.createUserInCustomDatabase()
        self.signInSuccessful()
    }

    @IBAction func googleSignInTapped() {
        // Firebase: authenticate with Google
    }

    private func signInSuccessful() {
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
