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
        
        //try? self.createKeyPair()
        /*self.wallet = self.getItemFromKeychain(service: "com.example.sandcoin-wallet", key: "wallet")
        
        if self.wallet == nil {
            self.wallet = Bitcoin.newPrivateKey()
            self.saveToKeychain(service: "com.example.sandcoin-wallet", value: self.wallet, key: "wallet")
            self.displayQRCodeImage()
            self.walletLabel.text = self.wallet
        } else {
            print(self.wallet)
            self.displayQRCodeImage()
            self.walletLabel.text = self.wallet
        }*/
        
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
        self.imgQRCode.image = self.generateQRCode(from: self.wallet)
    }
    
    func saveToKeychain(service: String, value: String, key: String){
        let keychain = Keychain(service: service).synchronizable(true)
        keychain[string: key] = value
    }
    
    
    func getItemFromKeychain(service: String, key: String) -> String {
        let keychain = Keychain(service: service).synchronizable(true)
        
        let providedKey:String = keychain[string: key]!
        
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
    
    func createKeyPair() throws {
        print("createKeyPair started")
        let tag = "com.example.keys.mykey".data(using: .utf8)!
        let attributes: [String: Any] =
            [kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
             kSecAttrKeySizeInBits as String: 256,
             kSecPrivateKeyAttrs as String:
                [kSecAttrIsPermanent as String: true,
                 kSecAttrApplicationTag as String: tag]
        ]
        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            print("createKeyPair throws an error")
            throw error!.takeRetainedValue() as Error
        }
        let publicKey = SecKeyCopyPublicKey(privateKey)
    
        var error2: Unmanaged<CFError>?
        guard let data = SecKeyCopyExternalRepresentation(publicKey!, &error2) as Data? else {
            throw error!.takeRetainedValue() as Error
        }
        
        let nsdataStr = NSData.init(data: data)
//        let pbKeyStr = nsdataStr.description.trimmingCharacters(in: characterSet).replacingOccurrences(of: " ", width: "")
        let pbKeyStr = nsdataStr.base64EncodedString(options: .lineLength64Characters)
        let base58Str = pbKeyStr.base58String
        print(base58Str as Any)
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
