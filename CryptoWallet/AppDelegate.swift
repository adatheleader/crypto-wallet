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
    
    var appWallet = TLWallet(walletName: "App Wallet", walletConfig: TLWalletConfig(isTestnet: false))
    var accounts:TLAccounts?
    var coldWalletAccounts:TLAccounts?
    var importedAccounts:TLAccounts?
    var importedWatchAccounts:TLAccounts?
    var importedAddresses:TLImportedAddresses?
    var importedWatchAddresses:TLImportedAddresses?
    var godSend:TLSpaghettiGodSend?
    var receiveSelectedObject:TLSelectedObject?
    var historySelectedObject:TLSelectedObject?
    var bitcoinURIOptionsDict:NSDictionary?
    var justSetupHDWallet = false
    var giveExitAppNoticeForBlockExplorerAPIToTakeEffect = false
    fileprivate var isAccountsAndImportsLoaded = false
    var saveWalletJSONEnabled = true
    var consecutiveFailedStealthChallengeCount = 0
    fileprivate var hasFinishLaunching = false
    fileprivate var respondToStealthPaymentGetTxTries = 0
    var scannedEncryptedPrivateKey:String? = nil
    var scannedAddressBookAddress:String? = nil
    let pendingOperations = PendingOperations()
    var pendingSelfStealthPaymentTxid: String? = nil
    lazy var txFeeAPI = TLTxFeeAPI();
    
    
    class func instance() -> AppDelegate {
        return UIApplication.shared.delegate as! (AppDelegate)
    }
    
    func aAccountNeedsRecovering() -> Bool {
        for i in stride(from: 0, to: AppDelegate.instance().accounts!.getNumberOfAccounts(), by: 1) {
            let accountObject = AppDelegate.instance().accounts!.getAccountObjectForIdx(i)
            if (accountObject.needsRecovering()) {
                return true
            }
        }
        
        for i in stride(from: 0, to: AppDelegate.instance().coldWalletAccounts!.getNumberOfAccounts(), by: 1) {
            let accountObject = AppDelegate.instance().coldWalletAccounts!.getAccountObjectForIdx(i)
            if (accountObject.needsRecovering()) {
                return true
            }
        }
        
        for i in stride(from: 0, to: AppDelegate.instance().importedAccounts!.getNumberOfAccounts(), by: 1) {
            let accountObject = AppDelegate.instance().importedAccounts!.getAccountObjectForIdx(i)
            if (accountObject.needsRecovering()) {
                return true
            }
        }
        
        for i in stride(from: 0, to: AppDelegate.instance().importedWatchAccounts!.getNumberOfAccounts(), by: 1) {
            let accountObject = AppDelegate.instance().importedWatchAccounts!.getAccountObjectForIdx(i)
            if (accountObject.needsRecovering()) {
                return true
            }
        }
        return false
    }
    
    func checkToRecoverAccounts() {
        for i in stride(from: 0, to: AppDelegate.instance().accounts!.getNumberOfAccounts(), by: 1) {
            let accountObject = AppDelegate.instance().accounts!.getAccountObjectForIdx(i)
            if (accountObject.needsRecovering()) {
                accountObject.clearAllAddresses()
                accountObject.recoverAccount(false, recoverStealthPayments: true)
            }
        }
        
        for i in stride(from: 0, to: AppDelegate.instance().coldWalletAccounts!.getNumberOfAccounts(), by: 1) {
            let accountObject = AppDelegate.instance().coldWalletAccounts!.getAccountObjectForIdx(i)
            if (accountObject.needsRecovering()) {
                accountObject.clearAllAddresses()
                accountObject.recoverAccount(false, recoverStealthPayments: true)
            }
        }
        
        for i in stride(from: 0, to: AppDelegate.instance().importedAccounts!.getNumberOfAccounts(), by: 1) {
            let accountObject = AppDelegate.instance().importedAccounts!.getAccountObjectForIdx(i)
            if (accountObject.needsRecovering()) {
                accountObject.clearAllAddresses()
                accountObject.recoverAccount(false, recoverStealthPayments: true)
            }
        }
        
        for i in stride(from: 0, to: AppDelegate.instance().importedWatchAccounts!.getNumberOfAccounts(), by: 1) {
            let accountObject = AppDelegate.instance().importedWatchAccounts!.getAccountObjectForIdx(i)
            if (accountObject.needsRecovering()) {
                accountObject.clearAllAddresses()
                accountObject.recoverAccount(false, recoverStealthPayments: true)
            }
        }
    }
    
    func updateGodSend() {
        var sendFromType = TLPreferences.getSendFromType()
        var sendFromIndex = Int(TLPreferences.getSendFromIndex())
        
        if (sendFromType == .hdWallet) {
            if (sendFromIndex > self.accounts!.getNumberOfAccounts() - 1 ) {
                sendFromType = TLSendFromType.hdWallet
                sendFromIndex = 0
            }
        } else if (sendFromType == .coldWalletAccount) {
            if (sendFromIndex > self.coldWalletAccounts!.getNumberOfAccounts() - 1) {
                sendFromType = TLSendFromType.hdWallet
                sendFromIndex = 0
            }
        } else if (sendFromType == .importedAccount) {
            if (sendFromIndex > self.importedAccounts!.getNumberOfAccounts() - 1) {
                sendFromType = TLSendFromType.hdWallet
                sendFromIndex = 0
            }
        } else if (sendFromType == .importedWatchAccount) {
            if (sendFromIndex > self.importedWatchAccounts!.getNumberOfAccounts() - 1) {
                sendFromType = TLSendFromType.hdWallet
                sendFromIndex = 0
            }
        } else if (sendFromType == .importedAddress) {
            if (sendFromIndex > self.importedAddresses!.getCount() - 1 ) {
                sendFromType = TLSendFromType.hdWallet
                sendFromIndex = 0
            }
        } else if (sendFromType == .importedWatchAddress) {
            if (sendFromIndex > self.importedWatchAddresses!.getCount() - 1) {
                sendFromType = TLSendFromType.hdWallet
                sendFromIndex = 0
            }
        }
        
        self.updateGodSend(sendFromType, sendFromIndex:sendFromIndex)
    }
    
    func updateGodSend(_ sendFromType: TLSendFromType, sendFromIndex: Int) {
        TLPreferences.setSendFromType(sendFromType)
        TLPreferences.setSendFromIndex(UInt(sendFromIndex))
        
        if (sendFromType == .hdWallet) {
            let accountObject = self.accounts!.getAccountObjectForIdx(sendFromIndex)
            self.godSend?.setOnlyFromAccount(accountObject)
        } else if (sendFromType == .coldWalletAccount) {
            let accountObject = self.coldWalletAccounts!.getAccountObjectForIdx(sendFromIndex)
            self.godSend?.setOnlyFromAccount(accountObject)
        } else if (sendFromType == .importedAccount) {
            let accountObject = self.importedAccounts!.getAccountObjectForIdx(sendFromIndex)
            self.godSend?.setOnlyFromAccount(accountObject)
        } else if (sendFromType == .importedWatchAccount) {
            let accountObject = self.importedWatchAccounts!.getAccountObjectForIdx(sendFromIndex)
            self.godSend?.setOnlyFromAccount(accountObject)
        } else if (sendFromType == .importedAddress) {
            let importedAddress = self.importedAddresses!.getAddressObjectAtIdx(sendFromIndex)
            self.godSend?.setOnlyFromAddress(importedAddress)
        } else if (sendFromType == .importedWatchAddress) {
            let importedAddress = self.importedWatchAddresses!.getAddressObjectAtIdx(sendFromIndex)
            self.godSend?.setOnlyFromAddress(importedAddress)
        }
    }
    
    func updateReceiveSelectedObject(_ sendFromType: TLSendFromType, sendFromIndex: Int) {
        if (sendFromType == .hdWallet) {
            let accountObject = self.accounts!.getAccountObjectForIdx(sendFromIndex)
            self.receiveSelectedObject!.setSelectedAccount(accountObject)
        } else if (sendFromType == .coldWalletAccount) {
            let accountObject = self.coldWalletAccounts!.getAccountObjectForIdx(sendFromIndex)
            self.receiveSelectedObject!.setSelectedAccount(accountObject)
        } else if (sendFromType == .importedAccount) {
            let accountObject = self.importedAccounts!.getAccountObjectForIdx(sendFromIndex)
            self.receiveSelectedObject!.setSelectedAccount(accountObject)
        } else if (sendFromType == .importedWatchAccount) {
            let accountObject = self.importedWatchAccounts!.getAccountObjectForIdx(sendFromIndex)
            self.receiveSelectedObject!.setSelectedAccount(accountObject)
        } else if (sendFromType == .importedAddress) {
            let importedAddress = self.importedAddresses!.getAddressObjectAtIdx(sendFromIndex)
            self.receiveSelectedObject!.setSelectedAddress(importedAddress)
        } else if (sendFromType == .importedWatchAddress) {
            let importedAddress = self.importedWatchAddresses!.getAddressObjectAtIdx(sendFromIndex)
            self.receiveSelectedObject!.setSelectedAddress(importedAddress)
        }
    }
    
    func updateHistorySelectedObject(_ sendFromType: TLSendFromType, sendFromIndex: Int) {
        if (sendFromType == .hdWallet) {
            let accountObject = self.accounts!.getAccountObjectForIdx(sendFromIndex)
            self.historySelectedObject!.setSelectedAccount(accountObject)
        } else if (sendFromType == .coldWalletAccount) {
            let accountObject = self.coldWalletAccounts!.getAccountObjectForIdx(sendFromIndex)
            self.historySelectedObject!.setSelectedAccount(accountObject)
        } else if (sendFromType == .importedAccount) {
            let accountObject = self.importedAccounts!.getAccountObjectForIdx(sendFromIndex)
            self.historySelectedObject!.setSelectedAccount(accountObject)
        } else if (sendFromType == .importedWatchAccount) {
            let accountObject = self.importedWatchAccounts!.getAccountObjectForIdx(sendFromIndex)
            self.historySelectedObject!.setSelectedAccount(accountObject)
        } else if (sendFromType == .importedAddress) {
            let importedAddress = self.importedAddresses!.getAddressObjectAtIdx(sendFromIndex)
            self.historySelectedObject!.setSelectedAddress(importedAddress)
        } else if (sendFromType == .importedWatchAddress) {
            let importedAddress = self.importedWatchAddresses!.getAddressObjectAtIdx(sendFromIndex)
            self.historySelectedObject!.setSelectedAddress(importedAddress)
        }
    }
    
    
    func recoverHDWallet(_ mnemonic: String, shouldRefreshApp: Bool = true) {
        if shouldRefreshApp {
            self.refreshApp(mnemonic)
        } else {
            let masterHex = TLHDWalletWrapper.getMasterHex(mnemonic)
            self.appWallet.createInitialWalletPayload(mnemonic, masterHex:masterHex)
            
            self.accounts = TLAccounts(appWallet: self.appWallet, accountsArray:self.appWallet.getAccountObjectArray(), accountType:.hdWallet)
            self.coldWalletAccounts = TLAccounts(appWallet: self.appWallet, accountsArray:self.appWallet.getColdWalletAccountArray(), accountType:.coldWallet)
            self.importedAccounts = TLAccounts(appWallet: self.appWallet, accountsArray:self.appWallet.getImportedAccountArray(), accountType:.imported)
            self.importedWatchAccounts = TLAccounts(appWallet: self.appWallet, accountsArray:self.appWallet.getWatchOnlyAccountArray(), accountType:.importedWatch)
            self.importedAddresses = TLImportedAddresses(appWallet: self.appWallet, importedAddresses:self.appWallet.getImportedPrivateKeyArray(), accountAddressType:.imported)
            self.importedWatchAddresses = TLImportedAddresses(appWallet: self.appWallet, importedAddresses:self.appWallet.getWatchOnlyAddressArray(), accountAddressType:.importedWatch)
        }
        
        var accountIdx = 0
        var consecutiveUnusedAccountCount = 0
        let MAX_CONSECUTIVE_UNUSED_ACCOUNT_LOOK_AHEAD_COUNT = 4
        
        while (true) {
            let accountName = String(format:"Account %lu", (accountIdx + 1))
            let accountObject = self.accounts!.createNewAccount(accountName, accountType:.normal, preloadStartingAddresses:false)
            
            DLog("recoverHDWalletaccountName \(accountName)")
            
            let sumMainAndChangeAddressMaxIdx = accountObject.recoverAccount(false)
            DLog(String(format: "accountName \(accountName) sumMainAndChangeAddressMaxIdx: \(sumMainAndChangeAddressMaxIdx)"))
            if sumMainAndChangeAddressMaxIdx > -2 || accountObject.stealthWallet!.checkIfHaveStealthPayments() {
                consecutiveUnusedAccountCount = 0
            } else {
                consecutiveUnusedAccountCount += 1
                if (consecutiveUnusedAccountCount == MAX_CONSECUTIVE_UNUSED_ACCOUNT_LOOK_AHEAD_COUNT) {
                    break
                }
            }
            
            accountIdx += 1
        }
        
        DLog("recoverHDWallet getNumberOfAccounts: \(self.accounts!.getNumberOfAccounts())")
        if (self.accounts!.getNumberOfAccounts() == 0) {
            self.accounts!.createNewAccount("Account 1", accountType:.normal)
        } else if (self.accounts!.getNumberOfAccounts() > 1) {
            while (self.accounts!.getNumberOfAccounts() > 1 && consecutiveUnusedAccountCount > 0) {
                self.accounts!.popTopAccount()
                consecutiveUnusedAccountCount -= 1
            }
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        self.justSetupHDWallet = false
        let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        if (TLPreferences.getInstallDate() == nil) {
            if TLPreferences.getAppVersion() == "0" {
                TLPreferences.setHasSetupHDWallet(false)
                TLPreferences.setInstallDate()
                DLog("set InstallDate \(String(describing: TLPreferences.getInstallDate()))")
                TLPreferences.setAppVersion(appVersion)
            } else {
                TLPreferences.setInstallDate()
                DLog("set fake InstallDate \(String(describing: TLPreferences.getInstallDate()))")
                if appVersion != TLPreferences.getAppVersion() {
                    TLUpdateAppData.instance().beforeUpdatedAppVersion = TLPreferences.getAppVersion()
                    DLog("set new appVersion \(appVersion)")
                    TLPreferences.setAppVersion(appVersion)
                    TLPreferences.setDisabledPromptRateApp(false)
                }
            }
            
        } else if appVersion != TLPreferences.getAppVersion() {
            TLUpdateAppData.instance().beforeUpdatedAppVersion = TLPreferences.getAppVersion()
            DLog("set new appVersion \(appVersion)")
            TLPreferences.setAppVersion(appVersion)
            TLPreferences.setDisabledPromptRateApp(false)
        }
        self.checkIfWalletIsStored()

        return true
    }
    
    func navToWalletStory() {
        let mainStoryboardIpad : UIStoryboard = UIStoryboard(name: "Wallet", bundle: nil)
        let initialViewControlleripad : UIViewController = mainStoryboardIpad.instantiateViewController(withIdentifier: "Welcome") as UIViewController
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = initialViewControlleripad
        self.window?.makeKeyAndVisible()
    }
    
    func checkIfWalletIsStored() {
        let passphrase = TLWalletPassphrase.getDecryptedWalletPassphrase()
        if (TLPreferences.canRestoreDeletedApp() && !TLPreferences.hasSetupHDWallet() && passphrase != nil) {
            // is fresh app but not first time installing
            
            let alert = UIAlertController(title: "Backup passphrase found in keychain", message: "Do you want to restore from your backup passphrase or start a fresh app?", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Restore", style: .default) { (action) in
//                TLHUDWrapper.showHUDAddedTo(self.view, labelText: "Restoring Wallet".localized, animated: true)
                AppDelegate.instance().saveWalletJSONEnabled = false
                
                DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.high).async {
                    AppDelegate.instance().initializeWalletAppAndShowInitialScreen(true, walletPayload: nil)
                    AppDelegate.instance().refreshHDWalletAccounts(true)
                    DispatchQueue.main.async {
                        AppDelegate.instance().saveWalletJSONEnabled = true
                        AppDelegate.instance().saveWalletJsonCloud()
                        TLTransactionListener.instance().reconnect()
//                        TLHUDWrapper.hideHUDForView(self.view, animated: true)
//                        self.slidingViewController()!.topViewController = self.storyboard!.instantiateViewController(withIdentifier: "SendNav")
                    }
                }
            })
            alert.addAction(UIAlertAction(title: "Start fresh", style: .destructive) { (action) in
                AppDelegate.instance().initializeWalletAppAndShowInitialScreen(false, walletPayload: nil)
//                self.navToWalletStory()
                self.initializeWalletAppAndShowInitialScreenAndGoToMainScreen(nil)
            })
            let topWindow = UIWindow(frame: UIScreen.main.bounds)
            topWindow.rootViewController = UIViewController()
            topWindow.windowLevel = UIWindowLevelAlert + 1
            //self.window?.rootViewController?.present(alert, animated: true, completion: nil)
            topWindow.makeKeyAndVisible()
            topWindow.rootViewController?.present(alert, animated: true, completion: nil)
            
        } else {
            self.checkToLoadFromLocal()
        }
        
    }
    
    func refreshHDWalletAccounts(_ isRestoringWallet: Bool) {
        let group = DispatchGroup()
        for i in stride(from: 0, to: self.accounts!.getNumberOfAccounts(), by: 1) {
            let accountObject = self.accounts!.getAccountObjectForIdx(i)
            group.enter()
            
            // if account needs recovering dont fetch account data
            if (accountObject.needsRecovering()) {
                return
            }
            
            var activeAddresses = accountObject.getActiveMainAddresses()! as! [String]
            activeAddresses += accountObject.getActiveChangeAddresses()! as! [String]
            
            if accountObject.stealthWallet != nil {
                activeAddresses += accountObject.stealthWallet!.getPaymentAddresses()
            }
            
            if accountObject.stealthWallet != nil {
                group.enter()
                DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async {
                    accountObject.fetchNewStealthPayments(isRestoringWallet)
                    group.leave()
                }
            }
            
            accountObject.getAccountData(activeAddresses, shouldResetAccountBalance: true, success: {
                () in
                group.leave()
                
            }, failure: {
                () in
                group.leave()
            })
        }
        group.wait(timeout: DispatchTime.distantFuture)
    }
    
    func checkToLoadFromLocal() -> () {
        if (TLWalletJson.getDecryptedEncryptedWalletJSONPassphrase() != nil) {
            let localWalletPayload = AppDelegate.instance().getLocalWalletJsonDict()
            self.initializeWalletAppAndShowInitialScreenAndGoToMainScreen(localWalletPayload)
        } else {
            self.initializeWalletAppAndShowInitialScreenAndGoToMainScreen(nil)
        }
    }
    func initializeWalletAppAndShowInitialScreenAndGoToMainScreen(_ walletPayload: NSDictionary?) -> () {
        AppDelegate.instance().initializeWalletAppAndShowInitialScreen(false, walletPayload: walletPayload)
        TLTransactionListener.instance().reconnect()
        
//        self.navToWalletStory()
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
    
    func initializeWalletAppAndShowInitialScreen(_ recoverHDWalletIfNewlyInstalledApp:(Bool), walletPayload:(NSDictionary?)) {
        if (TLPreferences.getEnableBackupWithiCloud()) {
            TLCloudDocumentSyncWrapper.instance().checkCloudAvailability()
        }
        TLAnalytics.instance()
        
        NotificationCenter.default.addObserver(self
            ,selector:#selector(AppDelegate.saveWalletPayloadDelay(_:)),
             name:NSNotification.Name(rawValue: TLNotificationEvents.EVENT_WALLET_PAYLOAD_UPDATED()), object:nil)
        NotificationCenter.default.addObserver(self
            ,selector:#selector(AppDelegate.updateModelWithNewTransaction(_:)),
             name:NSNotification.Name(rawValue: TLNotificationEvents.EVENT_NEW_UNCONFIRMED_TRANSACTION()), object:nil)
        NotificationCenter.default.addObserver(self
            ,selector:#selector(AppDelegate.updateModelWithNewBlock(_:)),
             name:NSNotification.Name(rawValue: TLNotificationEvents.EVENT_NEW_BLOCK()), object:nil)
        NotificationCenter.default.addObserver(self
            ,selector:#selector(AppDelegate.listenToIncomingTransactionForGeneratedAddress(_:)),
             name:NSNotification.Name(rawValue: TLNotificationEvents.EVENT_NEW_ADDRESS_GENERATED()), object:nil)
        NotificationCenter.default.addObserver(self
            ,selector:#selector(AppDelegate.setWalletTransactionListenerClosed),
             name:NSNotification.Name(rawValue: TLNotificationEvents.EVENT_TRANSACTION_LISTENER_CLOSE()), object:nil)
        NotificationCenter.default.addObserver(self
            ,selector:#selector(AppDelegate.listenToIncomingTransactionForWallet),
             name:NSNotification.Name(rawValue: TLNotificationEvents.EVENT_TRANSACTION_LISTENER_OPEN()), object:nil)
        
        NotificationCenter.default.addObserver(self
            ,selector:#selector(AppDelegate.setAccountsListeningToStealthPaymentsToFalse),
             name:NSNotification.Name(rawValue: TLNotificationEvents.EVENT_STEALTH_PAYMENT_LISTENER_CLOSE()), object:nil)
        
        var passphrase = TLWalletPassphrase.getDecryptedWalletPassphrase()
        
        if (recoverHDWalletIfNewlyInstalledApp) {
            self.recoverHDWallet(passphrase!)
        } else {
            passphrase = TLHDWalletWrapper.generateMnemonicPassphrase()
            print("PASSPHRASE: \(passphrase)")
            self.refreshApp(passphrase!)
            let accountObject = self.accounts!.createNewAccount("Account 1", accountType:.normal, preloadStartingAddresses:true)
            accountObject.updateAccountNeedsRecovering(false)
            AppDelegate.instance().updateGodSend(TLSendFromType.hdWallet, sendFromIndex:0)
            AppDelegate.instance().updateReceiveSelectedObject(TLSendFromType.hdWallet, sendFromIndex:0)
            AppDelegate.instance().updateHistorySelectedObject(TLSendFromType.hdWallet, sendFromIndex:0)
        }
        self.justSetupHDWallet = true
        let encryptedWalletJson = TLWalletJson.getEncryptedWalletJsonContainer(self.appWallet.getWalletsJson()!,
                                                                               password:TLWalletJson.getDecryptedEncryptedWalletJSONPassphrase()!)
        let success = self.saveWalletJson(encryptedWalletJson as (NSString), date:Date())
        if success {
            TLPreferences.setHasSetupHDWallet(true)
        } else {
            NSException(name: NSExceptionName(rawValue: "Error".localized), reason: "Error saving wallet JSON file".localized, userInfo: nil).raise()
        }
        
        self.accounts = TLAccounts(appWallet: self.appWallet, accountsArray:self.appWallet.getAccountObjectArray(), accountType:.hdWallet)
        self.coldWalletAccounts = TLAccounts(appWallet:self.appWallet, accountsArray:self.appWallet.getColdWalletAccountArray(), accountType:.coldWallet)
        self.importedAccounts = TLAccounts(appWallet:self.appWallet, accountsArray:self.appWallet.getImportedAccountArray(), accountType:.imported)
        self.importedWatchAccounts = TLAccounts(appWallet: self.appWallet, accountsArray:self.appWallet.getWatchOnlyAccountArray(), accountType:.importedWatch)
        self.importedAddresses = TLImportedAddresses(appWallet: self.appWallet, importedAddresses:self.appWallet.getImportedPrivateKeyArray(), accountAddressType:TLAccountAddressType.imported)
        self.importedWatchAddresses = TLImportedAddresses(appWallet: self.appWallet, importedAddresses:self.appWallet.getWatchOnlyAddressArray(), accountAddressType:TLAccountAddressType.importedWatch)
        
        self.isAccountsAndImportsLoaded = true
        
        self.godSend = TLSpaghettiGodSend(appWallet: self.appWallet)
        self.receiveSelectedObject = TLSelectedObject()
        self.historySelectedObject = TLSelectedObject()
        self.updateGodSend()
        let selectObjected: AnyObject? = self.godSend?.getSelectedSendObject()
        if (selectObjected is TLAccountObject) {
            self.receiveSelectedObject!.setSelectedAccount(selectObjected as! TLAccountObject)
            self.historySelectedObject!.setSelectedAccount(selectObjected as! TLAccountObject)
        } else if (selectObjected is TLImportedAddress) {
            self.receiveSelectedObject!.setSelectedAddress(selectObjected as! TLImportedAddress)
            self.historySelectedObject!.setSelectedAddress(selectObjected as! TLImportedAddress)
        }
        assert(self.accounts!.getNumberOfAccounts() > 0, "")
        
        TLBlockExplorerAPI.instance()
        TLExchangeRate.instance()
        TLAchievements.instance()
        
        let blockExplorerURL = TLPreferences.getBlockExplorerURL(TLPreferences.getBlockExplorerAPI())!
        let baseURL = URL(string:blockExplorerURL)
        TLNetworking.isReachable(baseURL!, reachable:{(reachable: TLDOMAINREACHABLE) in
            if (reachable == TLDOMAINREACHABLE.notreachable) {
                print("%@ servers not reachable.".localized, blockExplorerURL)
            }
        })
        
        TLBlockExplorerAPI.instance().getBlockHeight({(jsonData:AnyObject!) in
            let blockHeight = (jsonData.object(forKey: "height") as! NSNumber).uint64Value
            DLog("setBlockHeight: \((jsonData.object(forKey: "height") as! NSNumber))")
            TLBlockchainStatus.instance().blockHeight = blockHeight
        }, failure:{(code, status) in
            DLog("Error getting block height.")
            print("Error getting block height.")
        })
        self.navToWalletStory()
    }
    
    func refreshApp(_ passphrase: String, clearWalletInMemory: Bool = true) {
        if (TLPreferences.getCloudBackupWalletFileName() == nil) {
            TLPreferences.setCloudBackupWalletFileName()
        }
        
        TLPreferences.deleteWalletPassphrase()
        TLPreferences.deleteEncryptedWalletJSONPassphrase()
        
        TLPreferences.setWalletPassphrase(passphrase, useKeychain: true)
        TLPreferences.setEncryptedWalletJSONPassphrase(passphrase, useKeychain: true)
        TLPreferences.clearEncryptedWalletPassphraseKey()
        
        TLPreferences.setCanRestoreDeletedApp(true)
        TLPreferences.setInAppSettingsCanRestoreDeletedApp(true)
        
        TLPreferences.setEnableBackupWithiCloud(false)
        TLPreferences.setInAppSettingsKitEnableBackupWithiCloud(false)
        
        TLPreferences.setInAppSettingsKitEnabledDynamicFee(false)
        TLPreferences.setInAppSettingsKitDynamicFeeSettingIdx(TLDynamicFeeSetting.FastestFee);
        TLPreferences.setInAppSettingsKitTransactionFee(TLWalletUtils.DEFAULT_FEE_AMOUNT_IN_BITCOINS())
        TLPreferences.setEnablePINCode(false)
        TLSuggestions.instance().enabledAllSuggestions()
        TLPreferences.resetBlockExplorerAPIURL()
        
        TLPreferences.setBlockExplorerAPI(String(format:"%ld", DEFAULT_BLOCKEXPLORER_API.rawValue))
        TLPreferences.setInAppSettingsKitBlockExplorerAPI(String(format:"%ld", DEFAULT_BLOCKEXPLORER_API.rawValue))
        
        
        let DEFAULT_CURRENCY_IDX = "20"
        TLPreferences.setCurrency(DEFAULT_CURRENCY_IDX)
        TLPreferences.setInAppSettingsKitCurrency(DEFAULT_CURRENCY_IDX)
        TLPreferences.setEnableSoundNotification(true)
        
        TLPreferences.setSendFromType(.hdWallet)
        TLPreferences.setSendFromIndex(0)
        
        if clearWalletInMemory {
            let masterHex = TLHDWalletWrapper.getMasterHex(passphrase)
            self.appWallet.createInitialWalletPayload(passphrase, masterHex:masterHex)
            
            self.accounts = TLAccounts(appWallet: self.appWallet, accountsArray:self.appWallet.getAccountObjectArray(), accountType:.hdWallet)
            self.coldWalletAccounts = TLAccounts(appWallet: self.appWallet, accountsArray:self.appWallet.getColdWalletAccountArray(), accountType:.coldWallet)
            self.importedAccounts = TLAccounts(appWallet:self.appWallet, accountsArray:self.appWallet.getImportedAccountArray(), accountType:.imported)
            self.importedWatchAccounts = TLAccounts(appWallet: self.appWallet, accountsArray:self.appWallet.getWatchOnlyAccountArray(), accountType:.importedWatch)
            self.importedAddresses = TLImportedAddresses(appWallet: self.appWallet, importedAddresses:self.appWallet.getImportedPrivateKeyArray(), accountAddressType:.imported)
            self.importedWatchAddresses = TLImportedAddresses(appWallet: self.appWallet, importedAddresses:self.appWallet.getWatchOnlyAddressArray(), accountAddressType:.importedWatch)
        }
        
        self.receiveSelectedObject = TLSelectedObject()
        self.historySelectedObject = TLSelectedObject()
        
    }
    
    func application(_ application: (UIApplication), open url: URL, sourceApplication: (String)?, annotation:Any) -> Bool {
        self.bitcoinURIOptionsDict = TLWalletUtils.parseBitcoinURI(url.absoluteString)
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
        if (TLPreferences.getEnableBackupWithiCloud()) {
            // when terminating app must save immediately, don't wait to save to iCloud
            let encryptedWalletJson = TLWalletJson.getEncryptedWalletJsonContainer(self.appWallet.getWalletsJson()!,
                                                                                   password:TLWalletJson.getDecryptedEncryptedWalletJSONPassphrase()!)
            self.saveWalletJson(encryptedWalletJson as (NSString), date:Date())
        }
        self.saveWalletJsonCloud()
    }
    func saveWalletPayloadDelay(_ notification: Notification) {
        DispatchQueue.main.async {
            if self.saveWalletJSONEnabled == false {
                return
            }
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector:#selector(AppDelegate.saveWalletJsonCloudBackground), object:nil)
            Timer.scheduledTimer(timeInterval: self.SAVE_WALLET_PAYLOAD_DELAY, target: self,
                                 selector: #selector(AppDelegate.saveWalletJsonCloudBackground), userInfo: nil, repeats: false)
        }
    }
    
    func saveWalletJsonCloudBackground() {
        DLog("saveWalletJsonCloudBackground starting...")
        let queue = DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.background)
        queue.async {
            self.saveWalletJsonCloud()
        }
    }
    
    func printOutWalletJSON() {
        DLog("printOutWalletJSON:\n\(self.appWallet.getWalletsJson()!)")
    }
    
    func saveWalletJsonCloud() -> Bool {
        if saveWalletJSONEnabled == false {
            DLog("saveWalletJSONEnabled disabled")
            return false
        }
        DLog("saveFileToCloud starting...")
        
        let encryptedWalletJson = TLWalletJson.getEncryptedWalletJsonContainer(self.appWallet.getWalletsJson()!,
                                                                               password:TLWalletJson.getDecryptedEncryptedWalletJSONPassphrase()!)
        if (TLPreferences.getEnableBackupWithiCloud()) {
            if (TLCloudDocumentSyncWrapper.instance().checkCloudAvailability()) {
                TLCloudDocumentSyncWrapper.instance().saveFile(toCloud: TLPreferences.getCloudBackupWalletFileName()!, content:encryptedWalletJson,
                                                               completion:{(cloudDocument, documentData, error) in
                                                                if error == nil {
                                                                    self.saveWalletJson(encryptedWalletJson as (NSString), date:cloudDocument!.fileModificationDate!)
                                                                    DLog("saveFileToCloud done")
                                                                } else {
                                                                    DLog("saveFileToCloud error \(error!.localizedDescription)")
                                                                }
                })
            } else {
                self.saveWalletJson(encryptedWalletJson as (NSString), date:Date())
                DLog("saveFileToCloud ! checkCloudAvailability save local done")
            }
        } else {
            self.saveWalletJson(encryptedWalletJson as (NSString), date:Date())
            DLog("saveFileToCloud local done")
        }
        return true
    }
    
    fileprivate func saveWalletJson(_ encryptedWalletJson: (NSString), date: (Date)) -> Bool {
        let success = TLWalletJson.saveWalletJson(encryptedWalletJson as String, date:date)
        
        if (!success) {
            DispatchQueue.main.async {
                DLog("Local back up to wallet failed!")
            }
        }
        
        return success
    }
    
    func getLocalWalletJsonDict() -> NSDictionary? {
        return TLWalletJson.getWalletJsonDict(TLWalletJson.getLocalWalletJSONFile(),
                                              password:TLWalletJson.getDecryptedEncryptedWalletJSONPassphrase())
    }
    
    func setAccountsListeningToStealthPaymentsToFalse() {
        for i in stride(from: 0, to: self.accounts!.getNumberOfAccounts(), by: 1) {
            let accountObject = self.accounts!.getAccountObjectForIdx(i)
            if accountObject.stealthWallet != nil {
                accountObject.stealthWallet!.isListeningToStealthPayment = false
            }
        }
        
        for i in stride(from: 0, to: self.importedAccounts!.getNumberOfAccounts(), by: 1) {
            let accountObject = self.importedAccounts!.getAccountObjectForIdx(i)
            if accountObject.stealthWallet != nil {
                accountObject.stealthWallet!.isListeningToStealthPayment = false
            }
        }
    }
    
    
    
    
    
    func setWalletTransactionListenerClosed() {
        DLog("setWalletTransactionListenerClosed")
        for i in stride(from: 0, to: self.accounts!.getNumberOfAccounts(), by: 1) {
            let accountObject = self.accounts!.getAccountObjectForIdx(i)
            accountObject.listeningToIncomingTransactions = false
        }
        for i in stride(from: 0, to: self.coldWalletAccounts!.getNumberOfAccounts(), by: 1) {
            let accountObject = self.coldWalletAccounts!.getAccountObjectForIdx(i)
            accountObject.listeningToIncomingTransactions = false
        }
        for i in stride(from: 0, to: self.importedAccounts!.getNumberOfAccounts(), by: 1) {
            let accountObject = self.importedAccounts!.getAccountObjectForIdx(i)
            accountObject.listeningToIncomingTransactions = false
        }
        for i in stride(from: 0, to: self.importedWatchAccounts!.getNumberOfAccounts(), by: 1) {
            let accountObject = self.importedWatchAccounts!.getAccountObjectForIdx(i)
            accountObject.listeningToIncomingTransactions = false
        }
        for i in stride(from: 0, to: self.importedAddresses!.getCount(), by: 1) {
            let importedAddress = self.importedAddresses!.getAddressObjectAtIdx(i)
            importedAddress.listeningToIncomingTransactions = false
        }
        for i in stride(from: 0, to: self.importedWatchAddresses!.getCount(), by: 1) {
            let importedAddress = self.importedWatchAddresses!.getAddressObjectAtIdx(i)
            importedAddress.listeningToIncomingTransactions = false
        }
    }
    
    func listenToIncomingTransactionForGeneratedAddress(_ note: Notification) {
        let address: AnyObject? = note.object as AnyObject?
        
        TLTransactionListener.instance().listenToIncomingTransactionForAddress(address as! String)
    }
    
    func updateModelWithNewTransaction(_ note: Notification) {
        let txDict = note.object as! NSDictionary
        DLog("updateModelWithNewTransaction txDict: \(txDict.debugDescription)")
        
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.background).async {
            let txObject = TLTxObject(dict:txDict)
            if self.pendingSelfStealthPaymentTxid != nil {
                // Special case where receiving stealth payment from same sending account.
                // Let stealth websocket handle it
                // Need this cause, must generate private key and add address to account so that the bitcoins can be accounted for.
                if txObject.getHash() as? String == self.pendingSelfStealthPaymentTxid {
                    //self.pendingSelfStealthPaymentTxid = nil
                    return
                }
            }
            
            let addressesInTx = txObject.getAddresses()
            
            for i in stride(from: 0, to: self.accounts!.getNumberOfAccounts(), by: 1) {
                let accountObject = self.accounts!.getAccountObjectForIdx(i)
                if !accountObject.hasFetchedAccountData() {
                    continue
                }
                for address in addressesInTx {
                    if (accountObject.isAddressPartOfAccount(address )) {
                        DLog("updateModelWithNewTransaction accounts \(accountObject.getAccountID())")
                        self.handleNewTxForAccount(accountObject, txObject: txObject)
                    }
                }
            }
            
            for i in stride(from: 0, to: self.coldWalletAccounts!.getNumberOfAccounts(), by: 1) {
                let accountObject = self.coldWalletAccounts!.getAccountObjectForIdx(i)
                if !accountObject.hasFetchedAccountData() {
                    continue
                }
                for address in addressesInTx {
                    if (accountObject.isAddressPartOfAccount(address)) {
                        DLog("updateModelWithNewTransaction coldWalletAccounts \(accountObject.getAccountID())")
                        self.handleNewTxForAccount(accountObject, txObject: txObject)
                    }
                }
            }
            
            for i in stride(from: 0, to: self.importedAccounts!.getNumberOfAccounts(), by: 1) {
                let accountObject = self.importedAccounts!.getAccountObjectForIdx(i)
                if !accountObject.hasFetchedAccountData() {
                    continue
                }
                for address in addressesInTx {
                    if (accountObject.isAddressPartOfAccount(address)) {
                        DLog("updateModelWithNewTransaction importedAccounts \(accountObject.getAccountID())")
                        self.handleNewTxForAccount(accountObject, txObject: txObject)
                    }
                }
            }
            
            for i in stride(from: 0, to: self.importedWatchAccounts!.getNumberOfAccounts(), by: 1) {
                let accountObject = self.importedWatchAccounts!.getAccountObjectForIdx(i)
                if !accountObject.hasFetchedAccountData() {
                    continue
                }
                for address in addressesInTx {
                    if (accountObject.isAddressPartOfAccount(address)) {
                        DLog("updateModelWithNewTransaction importedWatchAccounts \(accountObject.getAccountID())")
                        self.handleNewTxForAccount(accountObject, txObject: txObject)
                    }
                }
            }
            
            for i in stride(from: 0, to: self.importedAddresses!.getCount(), by: 1) {
                let importedAddress = self.importedAddresses!.getAddressObjectAtIdx(i)
                if !importedAddress.hasFetchedAccountData() {
                    continue
                }
                let address = importedAddress.getAddress()
                for addr in addressesInTx {
                    if (addr == address) {
                        DLog("updateModelWithNewTransaction importedAddresses \(address)")
                        self.handleNewTxForImportedAddress(importedAddress, txObject: txObject)
                    }
                }
            }
            
            for i in stride(from: 0, to: self.importedWatchAddresses!.getCount(), by: 1) {
                let importedAddress = self.importedWatchAddresses!.getAddressObjectAtIdx(i)
                if !importedAddress.hasFetchedAccountData() {
                    continue
                }
                let address = importedAddress.getAddress()
                for addr in addressesInTx {
                    if (addr == address) {
                        DLog("updateModelWithNewTransaction importedWatchAddresses \(address)")
                        self.handleNewTxForImportedAddress(importedAddress, txObject: txObject)
                    }
                }
            }
        }
    }
    
    func handleNewTxForAccount(_ accountObject: TLAccountObject, txObject: TLTxObject) {
        let receivedAmount = accountObject.processNewTx(txObject)
        let receivedTo = accountObject.getAccountNameOrAccountPublicKey()
        //AppDelegate.instance().pendingOperations.addSetUpAccountOperation(accountObject, fetchDataAgain: true, success: {
//        self.updateUIForNewTx(txObject.getHash() as! String, receivedAmount: receivedAmount, receivedTo: receivedTo)
        //})
    }
    
    func handleNewTxForImportedAddress(_ importedAddress: TLImportedAddress, txObject: TLTxObject) {
        let receivedAmount = importedAddress.processNewTx(txObject)
        let receivedTo = importedAddress.getLabel()
        //AppDelegate.instance().pendingOperations.addSetUpImportedAddressOperation(importedAddress, fetchDataAgain: true, success: {
//        self.updateUIForNewTx(txObject.getHash() as! String, receivedAmount: receivedAmount, receivedTo: receivedTo)
        //})
    }
    
    func updateModelWithNewBlock(_ note: Notification) {
        let jsonData = note.object as! NSDictionary
        let blockHeight = jsonData.object(forKey: "height") as! NSNumber
        DLog("updateModelWithNewBlock: \(blockHeight)")
        TLBlockchainStatus.instance().blockHeight = blockHeight.uint64Value
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: TLNotificationEvents.EVENT_MODEL_UPDATED_NEW_BLOCK()), object:nil, userInfo:nil)
        
    }
    
    func listenToIncomingTransactionForWallet() {
        if (!self.isAccountsAndImportsLoaded || !TLTransactionListener.instance().isWebSocketOpen()) {
            return
        }
        
        for i in stride(from: 0, to: self.accounts!.getNumberOfAccounts(), by: 1) {
            let accountObject = self.accounts!.getAccountObjectForIdx(i)
            if accountObject.downloadState != .downloaded {
                continue
            }
            let activeMainAddresses = accountObject.getActiveMainAddresses()
            for address in activeMainAddresses! {
                TLTransactionListener.instance().listenToIncomingTransactionForAddress(address as! String)
            }
            let activeChangeAddresses = accountObject.getActiveChangeAddresses()
            for address in activeChangeAddresses! {
                TLTransactionListener.instance().listenToIncomingTransactionForAddress(address as! String)
            }
            
            if accountObject.stealthWallet != nil {
                let stealthPaymentAddresses = accountObject.stealthWallet!.getUnspentPaymentAddresses()
                for address in stealthPaymentAddresses {
                    TLTransactionListener.instance().listenToIncomingTransactionForAddress(address)
                }
            }
            accountObject.listeningToIncomingTransactions = true
        }
        
        for i in stride(from: 0, to: self.coldWalletAccounts!.getNumberOfAccounts(), by: 1) {
            let accountObject = self.coldWalletAccounts!.getAccountObjectForIdx(i)
            if accountObject.downloadState != .downloaded {
                continue
            }
            let activeMainAddresses = accountObject.getActiveMainAddresses()
            for address in activeMainAddresses! {
                TLTransactionListener.instance().listenToIncomingTransactionForAddress(address as! String)
            }
            let activeChangeAddresses = accountObject.getActiveChangeAddresses()
            for address in activeChangeAddresses! {
                TLTransactionListener.instance().listenToIncomingTransactionForAddress(address as! String)
            }
            accountObject.listeningToIncomingTransactions = true
        }
        
        for i in stride(from: 0, to: self.importedAccounts!.getNumberOfAccounts(), by: 1) {
            let accountObject = self.importedAccounts!.getAccountObjectForIdx(i)
            if accountObject.downloadState != .downloaded {
                continue
            }
            let activeMainAddresses = accountObject.getActiveMainAddresses()
            for address in activeMainAddresses! {
                TLTransactionListener.instance().listenToIncomingTransactionForAddress(address as! String)
            }
            let activeChangeAddresses = accountObject.getActiveChangeAddresses()
            for address in activeChangeAddresses! {
                TLTransactionListener.instance().listenToIncomingTransactionForAddress(address as! String)
            }
            
            if accountObject.stealthWallet != nil {
                let stealthPaymentAddresses = accountObject.stealthWallet!.getUnspentPaymentAddresses()
                for address in stealthPaymentAddresses {
                    TLTransactionListener.instance().listenToIncomingTransactionForAddress(address)
                }
            }
            accountObject.listeningToIncomingTransactions = true
        }
        
        for i in stride(from: 0, to: self.importedWatchAccounts!.getNumberOfAccounts(), by: 1) {
            let accountObject = self.importedWatchAccounts!.getAccountObjectForIdx(i)
            if accountObject.downloadState != .downloaded {
                continue
            }
            let activeMainAddresses = accountObject.getActiveMainAddresses()
            for address in activeMainAddresses! {
                TLTransactionListener.instance().listenToIncomingTransactionForAddress(address as! String)
            }
            let activeChangeAddresses = accountObject.getActiveChangeAddresses()
            for address in activeChangeAddresses! {
                TLTransactionListener.instance().listenToIncomingTransactionForAddress(address as! String)
            }
            accountObject.listeningToIncomingTransactions = true
        }
        
        for i in stride(from: 0, to: self.importedAddresses!.getCount(), by: 1) {
            let importedAddress = self.importedAddresses!.getAddressObjectAtIdx(i)
            if importedAddress.downloadState != .downloaded {
                continue
            }
            let address = importedAddress.getAddress()
            TLTransactionListener.instance().listenToIncomingTransactionForAddress(address)
            importedAddress.listeningToIncomingTransactions = true
        }
        
        for i in stride(from: 0, to: self.importedWatchAddresses!.getCount(), by: 1) {
            let importedAddress = self.importedWatchAddresses!.getAddressObjectAtIdx(i)
            if importedAddress.downloadState != .downloaded {
                continue
            }
            let address = importedAddress.getAddress()
            TLTransactionListener.instance().listenToIncomingTransactionForAddress(address)
            importedAddress.listeningToIncomingTransactions = true
        }
        
    }


}

