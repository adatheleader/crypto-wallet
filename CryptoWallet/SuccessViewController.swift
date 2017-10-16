//
//  SuccessViewController.swift
//  CryptoWallet
//
//  Created by Лидия Хашина on 21.07.17.
//  Copyright © 2017 Лидия Хашина. All rights reserved.
//

import UIKit
import KeychainAccess

class SuccessViewController: UIViewController {
    
    @IBOutlet weak var walletLabel: CopyableLabel!
    @IBOutlet weak var imgQRCode: UIImageView!
    
    var wallet: String!
//    var providedKey: String!
    
    var qrcodeImage: CIImage!


    override func viewDidLoad() {
        super.viewDidLoad()
        
        let defaults = UserDefaults.standard
        if let btcAddress = defaults.string(forKey: "btcAddress") {
            self.wallet = btcAddress
            self.walletLabel.text = self.wallet
            self.displayQRCodeImage()
        } else {
            self.createKeyPairAndAddress()
            self.wallet = defaults.string(forKey: "btcAddress")
            self.walletLabel.text = self.wallet
            self.displayQRCodeImage()
        }
        
        // Do any additional setup after loading the view.
        self.navigationController?.setNavigationBarHidden(true, animated: true)
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
        self.imgQRCode.image = self.generateQRCode(from: self.wallet!)
    }
    
    func createKeyPairAndAddress() {
        let defaults = UserDefaults.standard
        let newKey = BTCKey()
        let address = newKey?.address.string
        let privateKey = newKey?.privateKey
        let publicKey = newKey?.publicKey
        //let hashtype:BTCSignatureHashType = BTCSignatureHashType(rawValue: 1)!
        //let hashForSign = newKey?.address.data
        //let signature = newKey?.signature(forHash: hashForSign, hashType: hashtype)
        
        defaults.set(address, forKey: "btcAddress")
        defaults.set(privateKey, forKey: "privateKey")
        defaults.set(publicKey, forKey: "publicKey")
        self.savePrivateKeyToKeychain(privateKey: privateKey!)
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

}
