//
//  MyWalletTableViewController.swift
//  CryptoWallet
//
//  Created by Лидия Хашина on 21.11.2017.
//  Copyright © 2017 Лидия Хашина. All rights reserved.
//

import UIKit

class MyWalletTableViewController: UITableViewController {
    
    @IBOutlet weak var balanceLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.updateBalance()
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
