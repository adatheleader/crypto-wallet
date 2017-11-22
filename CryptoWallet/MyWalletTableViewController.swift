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
        if let transactionsArray = jsonData.object(forKey: "txs") as! NSArray? {
            for transaction in transactionsArray {
                do {
                    let transactionItem = try Transaction(JSONLoader(transaction))
                    print("block_height is: \(transactionItem.block_height)")
                } catch {
                    print("unable to parse the JSON")
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
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "transactionCell", for: indexPath as IndexPath)
        
        // Configure the cell...
        cell.textLabel?.text = "Transaction address"
        cell.detailTextLabel?.text = "-0 BTC"
        
        
        return cell
    }
}
