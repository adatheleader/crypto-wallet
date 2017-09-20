//
//  SignUpTableViewController.swift
//  CryptoWallet
//
//  Created by Лидия Хашина on 24.07.17.
//  Copyright © 2017 Лидия Хашина. All rights reserved.
//

import UIKit
import LocalAuthentication

class SignUpTableViewController: UITableViewController, UITextFieldDelegate {
    
    let userInfo = UserDefaults.standard
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var signupButton: UIButton!
    
    var activityIndicator = UIActivityIndicatorView()
    
    var email:String = ""
    
    var doesUserWantToUseTouchID: Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.emailField.delegate = self
        self.passwordField.delegate = self
        
        self.signupButton.layer.cornerRadius = 4.0
        self.signupButton.layer.borderColor = #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1).cgColor
        self.signupButton.layer.borderWidth = 1.5
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SignUpTableViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
    }
    
    //MARK: - Keyboard disappears on touching anywhere
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 6
    }
    
    //MARK: - Configure view
    func configureView() {
        self.title = "Registration"
        self.navigationController?.navigationBar.barTintColor = UIColor.white
        self.navigationController?.navigationBar.isTranslucent = false
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        
        self.signupButton.layer.cornerRadius = 4.0
        self.signupButton.layer.borderColor = UIColor(red: 218/255, green: 68/255, blue: 83/255, alpha: 1.0).cgColor
        self.signupButton.layer.borderWidth = 1.5
    }
    
    
    @IBAction func signUp(_ sender: Any) {
        self.email = self.emailField!.text!
//        let password = self.passwordField!.text
        self.startLoading()
        self.showTouchAlert()
    }
    
    
    //MARK: - UI Changes on Start Loading and Stop loading
    func startLoading() {
        DispatchQueue.main.async(execute: {
            self.signupButton.backgroundColor = #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)
            self.activityIndicator.activityIndicatorViewStyle = .white
            let halfButtonHeight: CGFloat = self.signupButton.bounds.size.height/2
            let halfButtonWidth: CGFloat = self.signupButton.bounds.size.width/2
            self.activityIndicator.center = CGPoint(x: halfButtonWidth, y: halfButtonHeight)
            self.signupButton.addSubview(self.activityIndicator)
            self.activityIndicator.startAnimating()
            self.signupButton.isEnabled = false
        })
    }
    
    func stopLoading() {
        DispatchQueue.main.async(execute: {
            self.activityIndicator.stopAnimating()
            self.signupButton.backgroundColor = UIColor.white
            self.signupButton.isEnabled = true
        })
    }
    
    func showTouchAlert() {
        let alert = UIAlertController(title: "Enable Touch ID", message: "For secure and quick login please enable Touch ID", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default) { (action) in
            self.doesUserWantToUseTouchID = true
            self.stopLoading()
            self.enableTouchID()
        })
        alert.addAction(UIAlertAction(title: "Continue without Touch ID", style: .destructive) { (action) in
            self.doesUserWantToUseTouchID = false
            self.stopLoading()
            self.unlockCryptoWallet()
        })
        self.present(alert, animated: true, completion: nil)
        //self.navigateToSuccessViewController()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func enableTouchID() {
        // Declare a NSError variable.
        var error: NSError?
        let context = LAContext()
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Only awesome people are welcome!"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
                [unowned self] (success, authenticationError) in
                
                DispatchQueue.main.async {
                    if success {
                        self.unlockCryptoWallet()
                    } else {
                        let ac = UIAlertController(title: "Authentication failed", message: "Your fingerprint could not be verified; please try again.", preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(ac, animated: true)
                    }
                }
            }
        } else {
            let ac = UIAlertController(title: "Touch ID not available", message: "Your device is not configured for Touch ID.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(ac, animated: true)
        }

    }
    
    
    func unlockCryptoWallet() {
        self.userInfo.set(self.email, forKey: "token")
        self.userInfo.set(self.doesUserWantToUseTouchID, forKey: "touch")
        self.performSegue(withIdentifier: "goToWallet", sender: self)
    }
}
