//
//  AppDelegate.swift
//  CryptoWallet
//
//  Created by Лидия Хашина on 21.07.17.
//  Copyright © 2017 Лидия Хашина. All rights reserved.
//

import UIKit
import LocalAuthentication
import KeychainAccess

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let userInfo = UserDefaults.standard
    let DEFAULT_BLOCKEXPLORER_API = TLBlockExplorer.blockchain
    let MAX_CONSECUTIVE_FAILED_STEALTH_CHALLENGE_COUNT = 8
    let SAVE_WALLET_PAYLOAD_DELAY = 2.0
    let RESPOND_TO_STEALTH_PAYMENT_GET_TX_TRIES_MAX_TRIES = 3
    lazy var webSocketNotifiedTxHashSet:NSMutableSet = NSMutableSet()
    var pendingSelfStealthPaymentTxid: String? = nil
    
    var passphrase: String?
    var address: String?
    var privateKey: String?
    var addressBalanceCoin = TLCoin.zero()
    var addressBalanceString: String?
    
    lazy var txFeeAPI = TLTxFeeAPI()
    var godSend:TLSpaghettiGodSend?
    
    class func instance() -> AppDelegate {
        return UIApplication.shared.delegate as! (AppDelegate)
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let DEFAULT_CURRENCY_IDX = "20"
        TLPreferences.setCurrency(DEFAULT_CURRENCY_IDX)
        TLPreferences.setInAppSettingsKitCurrency(DEFAULT_CURRENCY_IDX)
        
        TLPreferences.setSendFromType(.hdWallet)
        TLPreferences.setSendFromIndex(0)
        
        TLPreferences.setInAppSettingsKitEnabledDynamicFee(false)
        TLPreferences.setInAppSettingsKitDynamicFeeSettingIdx(TLDynamicFeeSetting.FastestFee);
        TLPreferences.setInAppSettingsKitTransactionFee(TLWalletUtils.DEFAULT_FEE_AMOUNT_IN_BITCOINS())
        
        // Override point for customization after application launch.
        if let passphraseFromDefaults = self.userInfo.value(forKey: "passphrase") {
            self.address = self.userInfo.value(forKey: "address") as? String
            self.passphrase = passphraseFromDefaults as? String
            self.privateKey = self.userInfo.value(forKey: "privatekey") as? String
            let touch = self.userInfo.value(forKey: "touch") as? Bool
            self.godSend = TLSpaghettiGodSend(address: self.address!)
            self.godSend?.setOnlyFromAddress(self.address!)
            if touch == false{
                self.navToWalletStory()
            } else if touch == true {
                self.useTouchID()
            }
            print("PASSPHRASE STARTS:\n\n\n\n\(String(describing: self.passphrase))\n\n\n\nPRIVATE KET STARTS:\n\n\n\n\(String(describing: self.privateKey))\n\n\n\nBTC Address STARTS:\n\n\n\n\(String(describing: self.address))")
        } else {
          self.checkIfWalletIsStored()
        }

        return true
    }
    
    func navToWalletStory() {
        DispatchQueue.main.async(execute: {
            let storyboard: UIStoryboard = UIStoryboard(name: "Wallet", bundle: Bundle.main)
            let navBarController: UINavigationController = storyboard.instantiateViewController(withIdentifier: "WalletTabBarController") as! UINavigationController
            self.window?.makeKeyAndVisible()
            self.window?.rootViewController = navBarController
        })
    }
    
    func checkIfWalletIsStored() {
        if let givenPassphrase = self.getPassphraseFromKeychain(){
            let alert = UIAlertController(title: "Backup passphrase found in keychain", message: "Do you want to restore from your backup passphrase or start a fresh app?", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Restore", style: .default) { (action) in
                self.passphrase = givenPassphrase
                self.initWallet(passphrase: self.passphrase!)
            })
            alert.addAction(UIAlertAction(title: "Start fresh", style: .destructive) { (action) in
                self.passphrase = TLCoreBitcoinWrapper.generateMnemonicPassphrase()
                self.savePassphraseToKeychain(passphrase: self.passphrase!)
                self.initWallet(passphrase: self.passphrase!)
            })
            let topWindow = UIWindow(frame: UIScreen.main.bounds)
            topWindow.rootViewController = UIViewController()
            topWindow.windowLevel = UIWindowLevelAlert + 1
            //self.window?.rootViewController?.present(alert, animated: true, completion: nil)
            topWindow.makeKeyAndVisible()
            topWindow.rootViewController?.present(alert, animated: true, completion: nil)
        } else {
            self.passphrase = TLCoreBitcoinWrapper.generateMnemonicPassphrase()
            self.savePassphraseToKeychain(passphrase: self.passphrase!)
            self.initWallet(passphrase: self.passphrase!)
        }
    }
    
    func initWallet(passphrase: String) {
        TLPreferences.resetBlockExplorerAPIURL()
        TLPreferences.setBlockExplorerAPI(String(format:"%ld", DEFAULT_BLOCKEXPLORER_API.rawValue))
        TLPreferences.setInAppSettingsKitBlockExplorerAPI(String(format:"%ld", DEFAULT_BLOCKEXPLORER_API.rawValue))
        print("initWallet")
        let masterHex = TLCoreBitcoinWrapper.getMasterHex(passphrase)
        let extendedPrivateKey = TLCoreBitcoinWrapper.getExtendPrivKey(masterHex)
        self.privateKey = TLCoreBitcoinWrapper.getPrivateKey(extendedPrivateKey as NSString, sequence: [0,1], isTestnet: false)
        self.address = TLCoreBitcoinWrapper.getAddress(privateKey!, isTestnet: false)
        self.addressBalanceCoin = self.updateAddressBalance(address: self.address!)!
        self.addressBalanceString = TLCurrencyFormat.getProperAmount(self.addressBalanceCoin) as String
        self.godSend = TLSpaghettiGodSend(address: self.address!)
        print("godSend")
        self.godSend?.setOnlyFromAddress(self.address!)
        print("PASSPHRASE STARTS:\n\n\n\n\(passphrase)\n\n\n\nEXTENDED PRIVATE KET STARTS:\n\n\n\n\(extendedPrivateKey)\n\n\n\nPRIVATE KET STARTS:\n\n\n\n\(String(describing: self.privateKey))\n\n\n\nBTC Address STARTS:\n\n\n\n\(String(describing: self.address))\n\n\n\nBTC Address Balance STARTS:\n\n\n\n\(String(describing: self.addressBalanceString))")
        
        self.userInfo.set(self.passphrase, forKey: "passphrase")
        self.userInfo.set(self.address, forKey: "address")
        self.userInfo.set(self.privateKey, forKey: "privatekey")
        self.showTouchAlert()
    }
    
    func updateAddressBalance(address: String) -> TLCoin? {
        var addresses = [String]()
        addresses.append(address)
        let jsonData = TLBlockExplorerAPI.instance().getAddressesInfoSynchronous(addresses)
        if (jsonData.object(forKey: TLNetworking.STATIC_MEMBERS.HTTP_ERROR_CODE) != nil) {
            DLog("getAccountDataSynchronous error \(jsonData.description)")
            NSException(name: NSExceptionName(rawValue: "Network Error"), reason: "HTTP Error", userInfo: nil).raise()
        }
        let addressesArray = jsonData.object(forKey: "addresses") as! NSArray
        var balance:UInt64 = 0
        //        for _addressDict in addressesArray {
        //            let addressDict = _addressDict as! NSDictionary
        //            let addressBalance = (addressDict.object(forKey: "final_balance") as! NSNumber).uint64Value
        //            balance += addressBalance
        //        }
        if let addressDict = addressesArray[0] as? NSDictionary{
            let addressBalance = (addressDict.object(forKey: "final_balance") as! NSNumber).uint64Value
            balance = addressBalance
        }
        let balanceCoin = TLCoin(uint64: UInt64(balance))
        let balanceString = TLCurrencyFormat.getProperAmount(balanceCoin) as String
        print("balance is updated - \(String(describing: balanceString))")
        
        return balanceCoin
    }
    
    func getPassphraseFromKeychain() -> String? {
        let keychain = Keychain(service: "CryptoWallet").synchronizable(true)
        let passphrase:String? = keychain[string: "passphrase"]
        
        return passphrase
    }
    func savePassphraseToKeychain(passphrase: String){
        let keychain = Keychain(service: "CryptoWallet").synchronizable(true)
        keychain[string: "passphrase"] = passphrase as String
    }
    
    func showTouchAlert() {
        print ("show touch alert")
        let alert = UIAlertController(title: "Enable Touch ID", message: "For secure and quick login please enable Touch ID", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default) { (action) in
            self.userInfo.set(true, forKey: "touch")
            self.useTouchID()
        })
        alert.addAction(UIAlertAction(title: "Continue without Touch ID", style: .destructive) { (action) in
            self.userInfo.set(false, forKey: "touch")
            self.navToWalletStory()
        })
        let topWindow = UIWindow(frame: UIScreen.main.bounds)
        topWindow.rootViewController = UIViewController()
        topWindow.windowLevel = UIWindowLevelAlert + 1
        //self.window?.rootViewController?.present(alert, animated: true, completion: nil)
        topWindow.makeKeyAndVisible()
        topWindow.rootViewController?.present(alert, animated: true, completion: nil)
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
    
    func application(_ application: (UIApplication), open url: URL, sourceApplication: (String)?, annotation:Any) -> Bool {
        return true
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
