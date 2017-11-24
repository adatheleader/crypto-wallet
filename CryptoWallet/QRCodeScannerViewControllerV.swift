//
//  QRCodeScannerViewControllerV.swift
//  CryptoWallet
//
//  Created by Лидия Хашина on 28.10.2017.
//  Copyright © 2017 Лидия Хашина. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

@objc(QRCodeScannerViewController) class QRCodeScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    fileprivate let n = 66
    fileprivate let DEFAULT_HEADER_HEIGHT = 66
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    fileprivate var success: ((String?) -> ())?
    fileprivate var error: ((String?) -> ())?
    fileprivate var captureSession: AVCaptureSession?
    fileprivate var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    fileprivate var isReadingQRCode: Bool = false
    
    override var preferredStatusBarStyle : (UIStatusBarStyle) {
        return UIStatusBarStyle.lightContent
    }
    
    init(success __success: ((String?) -> ())?, error __error: ((String?) -> ())?) {
        super.init(nibName: nil, bundle: nil)
        self.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        self.success = __success
        self.error = __error
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let app = AppDelegate.instance()
        self.view.frame = CGRect(x: 0, y: 0, width: app.window!.frame.size.width, height: app.window!.frame.size.height - CGFloat(DEFAULT_HEADER_HEIGHT))
        
        let topBarView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: CGFloat(DEFAULT_HEADER_HEIGHT)))
//        topBarView.backgroundColor = TLColors.mainAppColor()
        self.view.addSubview(topBarView)
        
        let logo = UIImageView(image: UIImage(named: "top_menu_logo.png"))
        logo.frame = CGRect(x: 88, y: 22, width: 143, height: 40)
        topBarView.addSubview(logo)
        
        let closeButton = UIButton(frame: CGRect(x: self.view.frame.size.width - 70, y: 15, width: 80, height: 51))
        closeButton.setTitle("Close".localized, for: UIControlState())
        closeButton.setTitleColor(UIColor(white:0.56, alpha: 1.0), for: UIControlState.highlighted)
        closeButton.titleLabel!.font = UIFont.systemFont(ofSize: 15)
        closeButton.addTarget(self, action: #selector(QRCodeScannerViewController.closeButtonClicked(_:)), for: .touchUpInside)
        topBarView.addSubview(closeButton)
        
        self.startReadingQRCode()
    }
    
    @objc func closeButtonClicked(_ sender: UIButton) -> () {
        self.stopReadingQRCode()
    }
    
    func startReadingQRCode() -> () {
        var error: NSError?
        
        let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        
        var input: AnyObject!
        do {
            input = try AVCaptureDeviceInput(device: captureDevice!) as AVCaptureDeviceInput
        } catch let error1 as NSError {
            error = error1
            input = nil
        }
        if (input == nil) {
            // This should not happen - all devices we support have cameras
            DLog("QR code scanner problem: \(error!.localizedDescription)")
            return
        }
        
        captureSession = AVCaptureSession()
        captureSession!.addInput(input as! AVCaptureInput!)
        
        let captureMetadataOutput = AVCaptureMetadataOutput()
        captureSession!.addOutput(captureMetadataOutput)
        
        let dispatchQueue = DispatchQueue(label: "myQueue", attributes: [])
        captureMetadataOutput.setMetadataObjectsDelegate(self, queue: dispatchQueue)
        captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
        
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        videoPreviewLayer?.videoGravity = (AVLayerVideoGravity.resizeAspectFill)
        
        let app = AppDelegate.instance()
        let frame = CGRect(x: 0, y: CGFloat(DEFAULT_HEADER_HEIGHT), width: app.window!.frame.size.width, height: app.window!.frame.size.height - CGFloat(DEFAULT_HEADER_HEIGHT))
        
        videoPreviewLayer!.frame = frame
        
        self.view.layer.addSublayer(videoPreviewLayer!)
        
        captureSession!.startRunning()
    }
    
    func stopReadingQRCode() -> () {
        if(captureSession != nil)
        {
            captureSession!.stopRunning()
            captureSession = nil
        }
        
        if(videoPreviewLayer != nil)
        {
            videoPreviewLayer!.removeFromSuperlayer()
        }
        
        self.dismiss(animated: true, completion: nil)
        
        if (self.error != nil) {
            self.error!(nil)
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) -> () {
        if (metadataObjects != nil && metadataObjects.count > 0) {
            let metadataObj: AnyObject = metadataObjects[0] as AnyObject
            if (metadataObj.type == AVMetadataObject.ObjectType.qr) {
                // do something useful with results
                DispatchQueue.main.sync {
                    let data:String = metadataObj.stringValue
                    
                    if (self.success != nil) {
                        self.success!(data)
                        self.stopReadingQRCode()
                    }
                }
            }
        }
    }
}
