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

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
}
