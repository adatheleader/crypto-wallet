//
//  MyWalletTableViewController.swift
//  CryptoWallet
//
//  Created by Лидия Хашина on 21.11.2017.
//  Copyright © 2017 Лидия Хашина. All rights reserved.
//

import UIKit
import JSONJoy

class MyWalletTableViewController: UITableViewController {
    
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var fiatBalanceLabel: UILabel!
    @IBOutlet weak var shareAddressButton: UIButton!
    
    @IBOutlet weak var qrCodeButton: UIButton!
    @IBOutlet weak var addressLabel: UILabel!
    
    var qrCodeImage: UIImageView?
    
    var transaction = [String: Any]()
    var transactions = [[String: Any]]()
    var sortedTransactions = [String:[[String:Any]]]()
    
    var addrOut: String?
    var addr: String?
    var value: Int?
    var transactionTime: String?
    
    struct Objects {
        
        var sectionName : String!
        var sectionObjects : [[String : Any]]!
    }
    
    var objectArray = [Objects]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.updateBalance()
        self.updateAddressTransactions()
        
        self.shareAddressButton.layer.cornerRadius = 4.0
        self.qrCodeButton.layer.cornerRadius = 4.0
        
        self.navigationController?.navigationBar.barTintColor = #colorLiteral(red: 0.9814189076, green: 0.6426411271, blue: 0.1245707795, alpha: 1)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.utf8)
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 3, y: 3)
            
            if let output = filter.outputImage?.transformed(by: transform) {
//                let scaleX = (qrCodeImage?.frame.size.width)! / output.extent.size.width
//                let scaleY = (qrCodeImage?.frame.size.height)! / output.extent.size.height
//
//                let transformedImage = output.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
                return UIImage(ciImage: output)
            }
        }
        return nil
    }
    
    
    func showQRCodeAlert() {
        let alert = UIAlertController(title:"QR Code", message: "Show this QR Code to your friend ", preferredStyle: UIAlertControllerStyle.alert)
        
        let saveAction = UIAlertAction(title: "", style: .default, handler: nil)
        
        // image set in alret view inside
        // size to fit in view
        var image = self.generateQRCode(from: AppDelegate.instance().address!)
        
        image = image?.withAlignmentRectInsets(UIEdgeInsets(top: 0, left:  -40, bottom: 0, right: 50))
        
        
        saveAction.setValue(image?.withRenderingMode(UIImageRenderingMode.alwaysOriginal), forKey: "image")
        alert.addAction(saveAction)
        
        
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { alertAction in
            alert.dismiss(animated: true, completion: nil)
        }))
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    
    func updateBalance() {
        let amount = AppDelegate.instance().updateAddressBalance(address: AppDelegate.instance().address!)
        let currency = TLCurrencyFormat.getFiatCurrency()
        let fiatAmount = TLExchangeRate.instance().fiatAmountStringFromBitcoin(currency, bitcoinAmount: amount!)
        let amountString = TLCurrencyFormat.getProperAmount(amount!)
        
        self.balanceLabel.text = amountString as String
        self.fiatBalanceLabel.text = "\(fiatAmount) USD"
        self.addressLabel.text = AppDelegate.instance().address!
        print("\(amountString) / \(fiatAmount) USD")
    }
    
    func updateAddressTransactions() {
        var addresses = [String]()
        addresses.append(AppDelegate.instance().address!)
        let jsonData = TLBlockExplorerAPI.instance().getAddressesInfoSynchronous(addresses)
        if (jsonData.object(forKey: TLNetworking.STATIC_MEMBERS.HTTP_ERROR_CODE) != nil) {
            DLog("getAccountDataSynchronous error \(jsonData.description)")
            NSException(name: NSExceptionName(rawValue: "Network Error"), reason: "HTTP Error", userInfo: nil).raise()
        }
       
        if let transactionsArray = jsonData.object(forKey: "txs") as! [NSDictionary]? {
            for transaction in transactionsArray {
                if let inputs = transaction["inputs"] as! [NSDictionary]? {
                    if let input = inputs[0] as NSDictionary? {
                        if let prevOut = input["prev_out"] as! NSDictionary?{
                            self.addrOut = prevOut["addr"] as! String?
                        }
                    }
                    if let out = transaction["out"] as! [NSDictionary]? {
                        if let outItem = out[0] as NSDictionary? {
                            self.addr = outItem["addr"] as! String?
                            self.value = outItem["value"] as! Int?
                        }
                    }
                    if let time = transaction["time"] as! Int? {
                        let date = NSDate(timeIntervalSince1970: TimeInterval(time))
                        let dateFormatter = DateFormatter()
                        dateFormatter.timeStyle = DateFormatter.Style.none //Set time style
                        dateFormatter.dateStyle = DateFormatter.Style.long //Set date style
                        dateFormatter.timeZone = TimeZone.current
                        let localDate = dateFormatter.string(from: date as Date)
                        self.transactionTime = localDate
                    }
                    self.transaction = ["who" : self.addrOut!, "toWho" : self.addr!, "value" : self.value!, "when" : self.transactionTime!]
                    self.transactions.append(self.transaction)
                    print(self.transactions)
                }
                
                
            }
            
            let datesArray = self.transactions.flatMap { $0["when"] as? String } // return array of date
            // Your required result
            datesArray.forEach {
                let dateKey = $0
                let filterArray = self.transactions.filter { $0["when"] as? String == dateKey }
                self.sortedTransactions[$0] = filterArray
            }
            
            print(self.sortedTransactions)
            
            for (key, value) in self.sortedTransactions {
                print("\(key) -> \(value)")
                self.objectArray.append(Objects(sectionName: key, sectionObjects: value))
            }
            self.objectArray = self.objectArray.sorted{ ($0.sectionName)! > ($1.sectionName)! }
            
            //            print("Transaction history - \(transactionsArray)")
        }
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return self.objectArray.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return objectArray[section].sectionName
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        
        return objectArray[section].sectionObjects.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "transactionCell", for: indexPath as IndexPath)
        
        // Configure the cell...
        
        if let secObj = objectArray[indexPath.section].sectionObjects {
            if let secObjItem = secObj[indexPath.row] as [String: Any]?{
                if let who = secObjItem["who"] as! String? {
                    if who == AppDelegate.instance().address {
                        if let toWho = secObjItem["toWho"] as! String? {
                            cell.textLabel?.text = toWho
                        }
                        if let value = secObjItem["value"] as! Int? {
                            let valueBTCString = self.convertSatoshiToBTCString(value: value)
                            cell.detailTextLabel?.text = "- \(valueBTCString)"
                        }
                    } else {
                        cell.textLabel?.text = who
                        if let value = secObjItem["value"] as! Int? {
                            let valueBTCString = self.convertSatoshiToBTCString(value: value)
                            cell.detailTextLabel?.text = "+ \(valueBTCString)"
                        }
                    }
                }
            }
        }
        
        
        return cell
    }
    
    func convertSatoshiToBTCString(value: Int) -> String {
//        let valueString = String(value)
        let valueBTC = TLCoin(uint64: UInt64(value))
        let valueBTCString = TLCurrencyFormat.getProperAmount(valueBTC)
        
        return valueBTCString as String
    }
}
