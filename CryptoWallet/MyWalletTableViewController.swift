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
    
    var transaction = [String: Any]()
    var transactions = [[String: Any]]()
    
    var addrOut: String?
    var addr: String?
    var value: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.updateBalance()
        self.updateAddressTransactions()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateBalance() {
        let amount = AppDelegate.instance().updateAddressBalance(address: AppDelegate.instance().address!)
        let currency = TLCurrencyFormat.getFiatCurrency()
        let fiatAmount = TLExchangeRate.instance().fiatAmountStringFromBitcoin(currency, bitcoinAmount: amount!)
        let amountString = TLCurrencyFormat.getProperAmount(amount!)
        
        self.balanceLabel.text = "\(amountString) / \(fiatAmount) USD"
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
                    self.transaction = ["who" : self.addrOut!, "toWho" : self.addr!, "value" : self.value!]
                    self.transactions.append(self.transaction)
                    print(self.transactions)
                }
                
                
            }
            
            //            print("Transaction history - \(transactionsArray)")
        }
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.transactions.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "transactionCell", for: indexPath as IndexPath)
        
        // Configure the cell...
        let transactionItem = self.transactions[indexPath.row]
        if let who = transactionItem["who"] as! String? {
            if who == AppDelegate.instance().address {
                if let toWho = transactionItem["toWho"] as! String? {
                    cell.textLabel?.text = toWho
                }
                if let value = transactionItem["value"] as! Int? {
                    cell.detailTextLabel?.text = "- \(value)"
                }
            } else {
                cell.textLabel?.text = who
                if let value = transactionItem["value"] as! Int? {
                    cell.detailTextLabel?.text = "+ \(value)"
                }
            }
        }
        
        
        return cell
    }
}
