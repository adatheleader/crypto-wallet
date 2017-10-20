//
//  BackupPhraseViewController.swift
//  CryptoWallet
//
//  Created by Лидия Хашина on 20.10.2017.
//  Copyright © 2017 Лидия Хашина. All rights reserved.
//

import UIKit

class BackupPhraseViewController: UIViewController {
    
    @IBOutlet weak var passphraseTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.passphraseTextView.isSelectable = false
        
        let passPhraseTextViewGestureRecognizer = UITapGestureRecognizer(target: self, action:#selector(BackupPhraseViewController.passPhraseTextViewTapped(_:)))
        self.passphraseTextView.addGestureRecognizer(passPhraseTextViewGestureRecognizer)
        
        let passphrase = AppDelegate.instance().passphrase
        self.passphraseTextView.text = passphrase
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func passPhraseTextViewTapped(_ sender:AnyObject) {
        let alert = UIAlertController(title: "", message: "The backup passphrase is not selectable on purpose, It is not recommended that you copy it to your clipboard or paste it anywhere on a device that connects to the internet. Instead the backup passphrase should be memorized or written down on a piece of paper.", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        self.present(alert, animated: true, completion: nil)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
