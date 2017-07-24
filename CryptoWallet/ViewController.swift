//
//  ViewController.swift
//  CryptoWallet
//
//  Created by Лидия Хашина on 21.07.17.
//  Copyright © 2017 Лидия Хашина. All rights reserved.
//

import UIKit
import LocalAuthentication


class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }
    
    @IBAction func startAuth(_ sender: Any) {
        let context = LAContext()
        
        // Declare a NSError variable.
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Identify yourself!"
            
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
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func unlockCryptoWallet() {
        self.performSegue(withIdentifier: "goToSuccessUI", sender: self)
    }
    
    func saveDataToKeyChain() {
        //  This two values identify the entry, together they become the
        //  primary key in the database
        let myAttrService = "app_name"
        let myAttrAccount = "first_name"
        
        // DELETE keychain item (if present from previous run)
        
        let delete_query: NSDictionary = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: myAttrService,
            kSecAttrAccount: myAttrAccount,
            kSecReturnData: false
        ]
        let delete_status = SecItemDelete(delete_query)
        if delete_status == errSecSuccess {
            print("Deleted successfully.")
        } else if delete_status == errSecItemNotFound {
            print("Nothing to delete.")
        } else {
            print("DELETE Error: \(delete_status).")
        }
        
        // INSERT keychain item
        
        let valueData = "The Top Secret Message V1".data(using: .utf8)!
        let sacObject =
            SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                                            .userPresence,
                                            nil)!
        
        let insert_query: NSDictionary = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccessControl: sacObject,
            kSecValueData: valueData,
            kSecUseAuthenticationUI: kSecUseAuthenticationUIAllow,
            kSecAttrService: myAttrService,
            kSecAttrAccount: myAttrAccount
        ]
        let insert_status = SecItemAdd(insert_query as CFDictionary, nil)
        if insert_status == errSecSuccess {
            print("Inserted successfully.")
        } else {
            print("INSERT Error: \(insert_status).")
        }
        
        DispatchQueue.global().async {
            // RETRIEVE keychain item
            
            let select_query: NSDictionary = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: myAttrService,
                kSecAttrAccount: myAttrAccount,
                kSecReturnData: true,
                kSecUseOperationPrompt: "Authenticate to access secret message"
            ]
            var extractedData: CFTypeRef?
            let select_status = SecItemCopyMatching(select_query, &extractedData)
            if select_status == errSecSuccess {
                if let retrievedData = extractedData as? Data,
                    let secretMessage = String(data: retrievedData, encoding: .utf8) {
                    
                    print("Secret message: \(secretMessage)")
                    
                    // UI updates must be dispatched back to the main thread.
                    
//                    DispatchQueue.main.async {
//                        self.messageLabel.text = secretMessage
//                    }
                    
                } else {
                    print("Invalid data")
                }
            } else if select_status == errSecUserCanceled {
                print("User canceled the operation.")
            } else {
                print("SELECT Error: \(select_status).")
            }
        }
    }


}

