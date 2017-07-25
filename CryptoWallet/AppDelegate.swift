//
//  AppDelegate.swift
//  CryptoWallet
//
//  Created by Лидия Хашина on 21.07.17.
//  Copyright © 2017 Лидия Хашина. All rights reserved.
//

import UIKit
import LocalAuthentication

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let userInfo = UserDefaults.standard



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        let userToken = userInfo.object(forKey: "token") as? String
        let touch = userInfo.object(forKey: "touch") as? Bool
        //print(userToken)
        
        if userToken == nil {
            self.navToLoginStory()
        } else {
            if touch! {
                self.useTouchID()
            } else {
                self.navToWalletStory()
            }
            
        }

        return true
    }
    
    func navToLoginStory() {
        DispatchQueue.main.async(execute: {
            let mainStoryboardIpad : UIStoryboard = UIStoryboard(name: "Login", bundle: nil)
            let initialViewControlleripad : UIViewController = mainStoryboardIpad.instantiateViewController(withIdentifier: "SignUp") as UIViewController
            self.window = UIWindow(frame: UIScreen.main.bounds)
            self.window?.rootViewController = initialViewControlleripad
            self.window?.makeKeyAndVisible()
            
            
        })
    }
    
    func navToWalletStory() {
        DispatchQueue.main.async(execute: {
            let mainStoryboardIpad : UIStoryboard = UIStoryboard(name: "Wallet", bundle: nil)
            let initialViewControlleripad : UIViewController = mainStoryboardIpad.instantiateViewController(withIdentifier: "Welcome") as UIViewController
            self.window = UIWindow(frame: UIScreen.main.bounds)
            self.window?.rootViewController = initialViewControlleripad
            self.window?.makeKeyAndVisible()
        })
    }
    
    func useTouchID() {
        // Declare a NSError variable.
        var error: NSError?
        let context = LAContext()
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Only awesome people are welcome!"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
                [unowned self] (success, authenticationError) in
                
                DispatchQueue.main.async {
                    if success {
                        self.navToWalletStory()
                    } else {
                        let ac = UIAlertController(title: "Authentication failed", message: "Your fingerprint could not be verified; please try again.", preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default))
                        self.window?.rootViewController?.present(ac, animated: true, completion: nil)
                    }
                }
            }
        } else {
            let ac = UIAlertController(title: "Touch ID not available", message: "Your device is not configured for Touch ID.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            self.window?.rootViewController?.present(ac, animated: true, completion: nil)
        }
        
    }


    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

