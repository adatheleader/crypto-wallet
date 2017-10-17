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
    @IBOutlet weak var balanceLabel: UILabel!
    
    var receiveSelectedObject:TLSelectedObject?
    var address: String!
    var accountBalance = TLCoin.zero()
    var addresses: NSMutableArray?
//    var providedKey: String!
    
    var qrcodeImage: CIImage!
    
    let DEFAULT_BLOCKEXPLORER_API = TLBlockExplorer.blockchain

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let defaults = UserDefaults.standard
//        if let btcAddress = defaults.string(forKey: "btcAddress") {
//            self.address = btcAddress
//            self.updateAddressBalance(address: address)
//            self.walletLabel.text = self.address
//            self.displayQRCodeImage()
//        } else {
//            self.createKeyPairAndAddress()
//            self.address = defaults.string(forKey: "btcAddress")
//            self.updateAddressBalance(address: address)
//            self.walletLabel.text = self.address
//            self.displayQRCodeImage()
//        }
        
//            self.updateAddressBalance()
        
        self.updateReceiveAddressArray()
//        self.walletLabel.text = self.address
        
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
        self.imgQRCode.image = self.generateQRCode(from: self.address!)
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
    
    func updateAddressBalance(address: String) {
        var addresses = [String]()
        var address2NumberOfTransactions = [String:Int]()
        var address2BalanceDict = [String:TLCoin]()
        let addressToIdxDict = NSMutableDictionary()
        var accountAddressIdx = -1
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
            let n_tx = addressDict.object(forKey: "n_tx") as! Int
            let address = addressDict.object(forKey: "address") as! String
            address2NumberOfTransactions[address] = n_tx
            let addressBalance = (addressDict.object(forKey: "final_balance") as! NSNumber).uint64Value
            balance += addressBalance
            //address2BalanceDict[address] = TLCoin(uint64: addressBalance)
            
            
            //let HDIdx = addressToIdxDict.object(forKey: address) as! Int
           // DLog(String(format: "recoverAccountMainAddresses HDIdx: %d address: %@ n_tx: %d", HDIdx, address, n_tx))
            /*if (n_tx > 0 && HDIdx > accountAddressIdx) {
                accountAddressIdx = HDIdx
            }*/
        }
        self.accountBalance = TLCoin(uint64: self.accountBalance.toUInt64() + UInt64(balance))
        let balanceString = TLCurrencyFormat.getProperAmount(self.accountBalance)
        self.balanceLabel.text = "Balance: \(balanceString)"
    }
    
    
    
    func updateReceiveAddressArray() {
        let receivingAddressesCount = AppDelegate.instance().receiveSelectedObject!.getReceivingAddressesCount()
        self.addresses = NSMutableArray(capacity: Int(receivingAddressesCount))
        for i in stride(from: 0, to: Int(receivingAddressesCount), by: 1) {
            let address = AppDelegate.instance().receiveSelectedObject!.getReceivingAddressForSelectedObject(i)
            self.addresses!.add(address!)
        }
        
        if (AppDelegate.instance().receiveSelectedObject!.getSelectedObjectType() == .account) {
            self.addresses!.add("End")
        }
        self.address = self.addresses![0] as! String
        print(self.address)
        DispatchQueue.main.async {
            self.walletLabel.text = self.address
        }
    }

}
