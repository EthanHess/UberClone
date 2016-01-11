//
//  ViewController.swift
//  UberRedone
//
//  Created by Ethan Hess on 1/8/16.
//  Copyright © 2016 Ethan Hess. All rights reserved.
//

import UIKit
import Parse

class ViewController: UIViewController, UITextFieldDelegate {
    
    var signUpState = true
    
    @IBOutlet var usernameField: UITextField!
    @IBOutlet var passwordField: UITextField!
    @IBOutlet var riderLabel: UILabel!
    @IBOutlet var driverLabel: UILabel!
    @IBOutlet var toggleSwitch: UISwitch!
    @IBOutlet var signUpButton: UIButton!
    @IBOutlet var toggleSignupButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyBoard")
        view.addGestureRecognizer(tapGestureRecognizer)
        
        usernameField.delegate = self
        passwordField.delegate = self
        
    }
    
    func displayAlert(title: String, message: String) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
        
    }
    
    @IBAction func signUp(sender: AnyObject) {
        
        if usernameField.text == "" || passwordField.text == "" {
            
            displayAlert("Missing Field(s)", message: "Username and password are required")
            
        } else {
            
            if signUpState == true {
                
                let user = PFUser()
                user.username = usernameField.text
                user.password = passwordField.text
                user["isDriver"] = toggleSwitch.on
                
                user.signUpInBackgroundWithBlock({ (success, error) -> Void in
                    
                    if let error = error {
                        if let errorString = error.userInfo["error"] as? String {
                            self.displayAlert("Something went wrong", message: errorString)
                        }
                    }
                    
                    else {
                        
                        if self.toggleSwitch.on == true {
                            
                            self.performSegueWithIdentifier("driverSegue", sender: self)
                        }
                        
                        else {
                            
                            self.performSegueWithIdentifier("riderSegue", sender: self)
                        }
                    }
                    
                })
            }
            
            else {
                
                PFUser.logInWithUsernameInBackground(usernameField.text!, password: passwordField.text!, block: { (user, error) -> Void in
                    
                    if let user = user {
                        
                        if user["isDriver"]! as! Bool == true {
                            
                            self.performSegueWithIdentifier("loginDriver", sender: self)
                            
                        } else {
                            
                            self.performSegueWithIdentifier("loginRider", sender: self)
                            
                        }
                        
                    } else {
                        
                        if let errorString = error?.userInfo["error"] as? String {
                            
                            self.displayAlert("Login Failed", message: errorString)
                            
                        }
                    }
                })
            }
        }
    }
    
    @IBAction func toggleSignUp(sender: AnyObject) {
        
        if signUpState == true {
            
            signUpButton.setTitle("Log In", forState: UIControlState.Normal)
            
            toggleSignupButton.setTitle("Switch to signup", forState: UIControlState.Normal)
            
            signUpState = false
            
            riderLabel.alpha = 0
            driverLabel.alpha = 0
            toggleSwitch.alpha = 0
            
        }
            
        else {
            
            signUpButton.setTitle("Sign Up", forState: UIControlState.Normal)
            
            toggleSignupButton.setTitle("Switch to login", forState: UIControlState.Normal)
            
            signUpState = true
            
            riderLabel.alpha = 1
            driverLabel.alpha = 1
            toggleSwitch.alpha = 1
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        
        if PFUser.currentUser()?.username != nil {
            
            if PFUser.currentUser()?["isDriver"]! as! Bool == true {
                
                self.performSegueWithIdentifier("loginDriver", sender: self)
            }
            
            else {
                
                self.performSegueWithIdentifier("loginRider", sender: self)
            }
        }
    }
    
    func dismissKeyBoard() {
        
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        view.endEditing(true)
        
//        textField.resignFirstResponder()
        return false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

