//
//  SuccessViewController.swift
//  CryptoWallet
//
//  Created by Лидия Хашина on 21.07.17.
//  Copyright © 2017 Лидия Хашина. All rights reserved.
//

import UIKit

class SuccessViewController: UIViewController {
    
    
    @IBOutlet weak var walletLabel: UILabel!
    @IBOutlet weak var imgQRCode: UIImageView!
    
    var qrcodeImage: CIImage!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.walletLabel.text = "0xe57f8723ecce747177ebf8037c3658c2beab57a5"
        self.displayQRCodeImage()

        // Do any additional setup after loading the view.
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)
        
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 3, y: 3)
            
            if let output = filter.outputImage?.applying(transform) {
                return UIImage(ciImage: output)
            }
        }
        
        return nil
    }
    
    func displayQRCodeImage() {
        self.imgQRCode.image = self.generateQRCode(from: self.walletLabel.text!)
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
