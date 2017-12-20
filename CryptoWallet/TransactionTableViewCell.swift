//
//  TransactionTableViewCell.swift
//  CryptoWallet
//
//  Created by Лидия Хашина on 20.12.2017.
//  Copyright © 2017 Лидия Хашина. All rights reserved.
//

import UIKit

class TransactionTableViewCell: UITableViewCell {
    
    @IBOutlet weak var inOrOutImage: UIImageView!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var fiatLabel: UILabel!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
