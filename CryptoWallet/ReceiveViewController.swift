//
//  ReceiveViewController.swift
//  CryptoWallet
//
//  Created by Лидия Хашина on 21.07.17.
//  Copyright © 2017 Лидия Хашина. All rights reserved.
//

import UIKit
import KeychainAccess
import LocalAuthentication

class ReceiveViewController: UIViewController {
    
    @IBOutlet weak var imgQRCode: UIImageView!
    
    var receiveSelectedObject:TLSelectedObject?
    var address: String!
    var addresses: NSMutableArray?
    var qrcodeImage: CIImage!
    var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.address = AppDelegate.instance().address
        
        self.displayQRCodeImage()
        
        // Do any additional setup after loading the view.
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    @IBAction func close(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.isNavigationBarHidden = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    
    
    func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)
        
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 3, y: 3)
            
            if let output = filter.outputImage?.transformed(by: transform) {
                let scaleX = imgQRCode.frame.size.width / output.extent.size.width
                let scaleY = imgQRCode.frame.size.height / output.extent.size.height
                
                let transformedImage = output.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
                return UIImage(ciImage: transformedImage)
            }
        }
        
        return nil
    }
    
    func displayQRCodeImage() {
        
        self.imgQRCode.image = self.generateQRCode(from: self.address!)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
