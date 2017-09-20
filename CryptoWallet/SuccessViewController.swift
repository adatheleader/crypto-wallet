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
        
        self.wallet = self.getItemFromKeychain(service: "com.example.sandcoin-wallet", key: "wallet")
        
        if self.wallet == nil {
            self.wallet = Bitcoin.newPrivateKey()
            self.saveToKeychain(service: "com.example.sandcoin-wallet", value: self.wallet, key: "wallet")
            self.displayQRCodeImage()
            self.walletLabel.text = self.wallet
        } else {
            print(self.wallet)
            self.displayQRCodeImage()
            self.walletLabel.text = self.wallet
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
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
