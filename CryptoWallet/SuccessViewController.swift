//
//  SuccessViewController.swift
//  CryptoWallet
//
//  Created by Лидия Хашина on 21.07.17.
//  Copyright © 2017 Лидия Хашина. All rights reserved.
//

import UIKit
import KeychainAccess
import LocalAuthentication

class SuccessViewController: UIViewController {
    
    @IBOutlet weak var walletLabel: CopyableLabel!
    @IBOutlet weak var imgQRCode: UIImageView!
    @IBOutlet weak var balanceLabel: UILabel!
    
    var receiveSelectedObject:TLSelectedObject?
    var address: String!
    var accountBalance = TLCoin.zero()
    var addresses: NSMutableArray?
    var qrcodeImage: CIImage!
    var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.isNavigationBarHidden = false
        
        self.address = AppDelegate.instance().address
        self.walletLabel.text = self.address
        self.displayQRCodeImage()
        self.updateAddressBalance(address: self.address)
        
        // Do any additional setup after loading the view.
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.isNavigationBarHidden = false
        self.timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(self.refreshBalance), userInfo: nil, repeats: true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.timer!.invalidate()
    }
    
    @objc func refreshBalance() {
        self.updateAddressBalance(address: self.address)
    }
    
    func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)
        
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 3, y: 3)
            
            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }
        
        return nil
    }
    
    func displayQRCodeImage() {
        self.imgQRCode.image = self.generateQRCode(from: self.address!)
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func savePrivateKeyToKeychain(privateKey: NSMutableData){
        let keychain = Keychain(service: "com.cryptowallet.myBTC").synchronizable(true)
        keychain[data: "privateKey"] = privateKey as Data
    }

    func getPrivateKeyFromKeychain() -> NSMutableData {
        let keychain = Keychain(service: "com.cryptowallet.myBTC").synchronizable(true)
        let providedKey:NSMutableData = keychain[data: "privateKey"] as! NSMutableData

        return providedKey
    }

    func removeItemFromKeychain(service: String, key: String){
        let keychain = Keychain(service: service).synchronizable(true)

        do {
            try keychain.remove(key)
        } catch _ {
            // Error handling if needed...
        }
    }
    
    func updateAddressBalance(address: String) {
        var addresses = [String]()
        addresses.append(address)
        let jsonData = TLBlockExplorerAPI.instance().getAddressesInfoSynchronous(addresses)
        if (jsonData.object(forKey: TLNetworking.STATIC_MEMBERS.HTTP_ERROR_CODE) != nil) {
            DLog("getAccountDataSynchronous error \(jsonData.description)")
            NSException(name: NSExceptionName(rawValue: "Network Error"), reason: "HTTP Error", userInfo: nil).raise()
        }
        let addressesArray = jsonData.object(forKey: "addresses") as! NSArray
        var balance:UInt64 = 0
        for _addressDict in addressesArray {
            let addressDict = _addressDict as! NSDictionary
            let addressBalance = (addressDict.object(forKey: "final_balance") as! NSNumber).uint64Value
            balance += addressBalance
        }
        self.accountBalance = TLCoin(uint64: self.accountBalance.toUInt64() + UInt64(balance))
        let balanceString = TLCurrencyFormat.getProperAmount(self.accountBalance)
        self.balanceLabel.text = "Balance: \(balanceString)"
        print("balance is updated")
    }
    
    @IBAction func showBackupPhrase(_ sender: Any) {
        self.useTouchID()
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
                        self.performSegue(withIdentifier: "showPhrase", sender: nil)
                    } else {
                        let ac = UIAlertController(title: "Authentication failed", message: "Your fingerprint could not be verified; please try again.", preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(ac, animated: true, completion: nil)
                    }
                }
            }
        } else {
            let ac = UIAlertController(title: "Touch ID not available", message: "Your device is not configured for Touch ID.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(ac, animated: true, completion: nil)
        }
    }
    
}
