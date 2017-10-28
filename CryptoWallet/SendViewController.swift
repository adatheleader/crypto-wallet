//
//  SendViewController.swift
//  CryptoWallet
//
//  Created by Лидия Хашина on 28.10.2017.
//  Copyright © 2017 Лидия Хашина. All rights reserved.
//

import UIKit

class SendViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func showAddressReaderControllerFromViewController(_ viewController: (UIViewController), success: @escaping (TLWalletUtils.SuccessWithString), error: @escaping (TLWalletUtils.ErrorWithString)) {
        if (!isCameraAllowed()) {
            promptAppNotAllowedCamera()
            return
        }
        
        let reader = TLQRCodeScannerViewController(success:{(data: String?) in
            success(data)
        }, error:{(e: String?) in
            error(e)
        })
        
        viewController.present(reader, animated:true, completion:nil)
    }
    
    fileprivate func isCameraAllowed() -> Bool {
        return AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) != AVAuthorizationStatus.denied
    }
    
    fileprivate func promptAppNotAllowedCamera() {
        let alert = UIAlertController(title: "CryptoWallet is not allowed to access the camera", message: "allow camera access in\n Settings->Privacy->Camera->CryptoWallet", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        self.present(alert, animated: true, completion: nil)
    }

}
