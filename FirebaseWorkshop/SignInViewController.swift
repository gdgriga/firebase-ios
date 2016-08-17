//
//  SignInViewController.swift
//  FirebaseWorkshop
//
//  Created by Romans Karpelcevs on 28/07/16.
//  Copyright © 2016 GDG. All rights reserved.
//

import UIKit
import FirebaseAuth

class SignInViewController: UIViewController, UITextFieldDelegate, GIDSignInDelegate, GIDSignInUIDelegate {

    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().signInSilently()
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

    func signIn(signIn: GIDSignIn!, presentViewController viewController: UIViewController!) {
        self.presentViewController(viewController, animated: true, completion: nil)
    }

    func signIn(signIn: GIDSignIn!, dismissViewController viewController: UIViewController!) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    func signIn(signIn: GIDSignIn!, didSignInForUser user: GIDGoogleUser!,
                withError error: NSError!) {
        if let error = error {
            print(error.localizedDescription)
            return
        }

        let authentication = user.authentication
        let credential = FIRGoogleAuthProvider.credentialWithIDToken(authentication.idToken,
                                                                     accessToken: authentication.accessToken)
        FIRAuth.auth()?.signInWithCredential(credential) { (user, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            self.createUserInCustomDatabase()
            self.signInSuccessful()
        }
    }

    func signIn(signIn: GIDSignIn!, didDisconnectWithUser user:GIDGoogleUser!,
                withError error: NSError!) {
        // Perform any operations when the user disconnects from app here.
        // ...
    }
}
