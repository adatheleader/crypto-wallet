//
//  ReviewPaymentViewController.swift
//  CryptoWallet
//
//  Created by Лидия Хашина on 28.10.2017.
//  Copyright © 2017 Лидия Хашина. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}


@objc(ReviewPaymentViewController) class ReviewPaymentViewController: UIViewController {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @IBOutlet weak var navigationBar:UINavigationBar?
    @IBOutlet weak var fromLabel: UILabel!
    @IBOutlet weak var toLabel: UILabel!
    @IBOutlet weak var unitLabel: UILabel!
    @IBOutlet weak var fiatUnitLabel: UILabel!
    @IBOutlet weak var toAmountLabel: UILabel!
    @IBOutlet weak var feeAmountLabel: UILabel!
    @IBOutlet weak var toAmountFiatLabel: UILabel!
    @IBOutlet weak var feeAmountFiatLabel: UILabel!
    @IBOutlet weak var totalAmountLabel: UILabel!
    @IBOutlet weak var totalFiatAmountLabel: UILabel!
    @IBOutlet weak var sendButton: UIButton!
    weak var reviewPaymentViewController: ReviewPaymentViewController?
    fileprivate lazy var showedPromptedForSentPaymentTxHashSet:NSMutableSet = NSMutableSet()
    fileprivate var QRImageModal: TLQRImageModal?
    fileprivate var airGapDataBase64PartsArray: Array<String>?
    var sendTimer:Timer?
    var sendTxHash:String?
    var toAddress:String?
    var toAmount:TLCoin?
    var amountMovedFromAccount: TLCoin? = nil
    var realToAddresses: Array<String>? = nil
    
    lazy var unspentOutputsCount: Int = 0
    fileprivate var unspentOutputs:NSArray?
    fileprivate var unspentOutputsSum:TLCoin?
    
    typealias Failure = (Bool) -> ()
    
    private var scannedSignedTxAirGapDataPartsDict = [Int:String]()
    private var totalExpectedParts:Int = 0
    private var scannedSignedTxAirGapData:String? = nil
    
    private var shouldPromptToScanSignedTxAirGapData = false
    private var shouldPromptToBroadcastSignedTx = false
    private var signedAirGapTxHex:String? = nil
    private var signedAirGapTxHash:String? = nil
    
    
    
    override var preferredStatusBarStyle : (UIStatusBarStyle) {
        return UIStatusBarStyle.lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self
            ,selector:#selector(ReviewPaymentViewController.finishSend(_:)),
             name:NSNotification.Name(rawValue: TLNotificationEvents.EVENT_MODEL_UPDATED_NEW_UNCONFIRMED_TRANSACTION()), object:nil)
        updateView()
        self.reviewPaymentViewController = self
    }
    override func viewWillAppear(_ animated: Bool) {
        if self.shouldPromptToScanSignedTxAirGapData {
            self.promptToScanSignedTxAirGapData()
        } else if self.shouldPromptToBroadcastSignedTx {
            self.shouldPromptToBroadcastSignedTx = false
            self.promptToBroadcastColdWalletAccountSignedTx(txHex: self.signedAirGapTxHex!, txHash: self.signedAirGapTxHash!)
        }
    }
    
    func updateView() {
        self.title = "Review Payment"
        self.fromLabel.text = TLSendFormData.instance().fromLabel
        self.toLabel.text = TLSendFormData.instance().getAddress()
        self.unitLabel.text = TLCurrencyFormat.getBitcoinDisplay()
        self.fiatUnitLabel.text = TLCurrencyFormat.getFiatCurrency()
        self.toAmountLabel.text = TLCurrencyFormat.coinToProperBitcoinAmountString(TLSendFormData.instance().toAmount!, withCode: false)
        self.toAmountFiatLabel.text = TLCurrencyFormat.coinToProperFiatAmountString(TLSendFormData.instance().toAmount!, withCode: false)
        self.feeAmountLabel.text = TLCurrencyFormat.coinToProperBitcoinAmountString(TLSendFormData.instance().feeAmount!, withCode: false)
        self.feeAmountFiatLabel.text = TLCurrencyFormat.coinToProperFiatAmountString(TLSendFormData.instance().feeAmount!, withCode: false)
        let total = TLSendFormData.instance().toAmount!.add(TLSendFormData.instance().feeAmount!)
        self.totalAmountLabel.text = TLCurrencyFormat.coinToProperBitcoinAmountString(total, withCode: false)
        self.totalFiatAmountLabel.text = TLCurrencyFormat.coinToProperFiatAmountString(total, withCode: false)
    }
    
    fileprivate func showPromptForSetTransactionFee() {
        let msg = String(format: "Input your custom fee in %@", TLCurrencyFormat.getBitcoinDisplay())
        
        let alert = UIAlertController(title: "Transaction Fee".localized, message: msg, preferredStyle: UIAlertControllerStyle.alert)
        alert.addTextField { (textField : UITextField) -> Void in
            textField.placeholder = "fee amount".localized
            textField.keyboardType = .decimalPad
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default) { (action) in
            let feeAmountString = (alert.textFields![0]).text
            
            let feeAmount = TLCurrencyFormat.properBitcoinAmountStringToCoin(feeAmountString!)
            
            let amountNeeded = TLSendFormData.instance().toAmount!.add(feeAmount)
            let sendFromBalance = AppDelegate.instance().addressBalanceCoin
            AppDelegate.instance().godSend!.setCurrentFromBalance(sendFromBalance)
            if (amountNeeded.greater(sendFromBalance)) {
                self.prompt(title: "Insufficient Balance".localized, message: "Your new transaction fee is too high")
                return
            }
            
            if (TLWalletUtils.isTransactionFeeTooLow(feeAmount)) {
                let msg = String(format: "Too low a transaction fee can cause transactions to take a long time to confirm. Continue anyways?".localized)
                
                self.promtForOKCancel(self, title: "Non-recommended Amount Transaction Fee".localized, message: msg, success: {
                    () in
                    TLSendFormData.instance().feeAmount = feeAmount
                    self.updateView()
                }, failure: {
                    (isCancelled: Bool) in
                    self.showPromptForSetTransactionFee()
                })
            } else if (TLWalletUtils.isTransactionFeeTooHigh(feeAmount)) {
                let msg = String(format: "Your transaction fee is very high. Continue anyways?".localized)
                
                self.promtForOKCancel(self, title: "Non-recommended Amount Transaction Fee".localized, message: msg, success: {
                    () in
                    TLSendFormData.instance().feeAmount = feeAmount
                    self.updateView()
                }, failure: {
                    (isCancelled: Bool) in
                    self.showPromptForSetTransactionFee()
                })
            } else {
                TLSendFormData.instance().feeAmount = feeAmount
                self.updateView()
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel".localized, style: .destructive) { (action) in
        })
        self.present(alert, animated: true, completion: nil)
    }
    
    func promtForOKCancel(_ vc: UIViewController, title: String, message: String,
                          success: @escaping TLWalletUtils.Success
        , failure: @escaping Failure) -> () {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK".localized, style: .default) { (action) in
            success()
        })
        alert.addAction(UIAlertAction(title: "Cancel".localized, style: .destructive) { (action) in
            failure(true)
        })
        self.present(alert, animated: true, completion: nil)
    }
    
    func showPromptPaymentSent(_ txHash: String, address: String, amount: TLCoin) {
        DLog("showPromptPaymentSent \(txHash)")
        let msg = String(format:"Sent %@ to %@".localized, TLCurrencyFormat.getProperAmount(amount), address)
//        TLHUDWrapper.hideHUDForView(self.view, animated: true)
        self.promptForOK(self, title: "", message: msg, success: {
            self.dismiss(animated: true, completion: nil)
        })
    }
    
    func cancelSend() {
        sendTimer?.invalidate()
//        TLHUDWrapper.hideHUDForView(self.view, animated: true)
    }
    
    @objc func retryFinishSend() {
        DLog("retryFinishSend \(String(describing: self.sendTxHash))")
        if !AppDelegate.instance().webSocketNotifiedTxHashSet.contains(self.sendTxHash!) {
            let nonUpdatedBalance = AppDelegate.instance().godSend!.getCurrentFromBalance()
            let accountNewBalance = nonUpdatedBalance.subtract(self.amountMovedFromAccount!)
            DLog("retryFinishSend 2 \(String(describing: self.sendTxHash))")
            AppDelegate.instance().godSend!.setCurrentFromBalance(accountNewBalance)
        }
        
        if !self.showedPromptedForSentPaymentTxHashSet.contains(self.sendTxHash!) {
            self.showedPromptedForSentPaymentTxHashSet.add(self.sendTxHash!)
            self.showPromptPaymentSent(self.sendTxHash!, address: self.toAddress!, amount: self.toAmount!)
        }
    }
    
    @objc func finishSend(_ note: Notification) {
        let webSocketNotifiedTxHash = note.object as? String
        DLog("finishSend \(String(describing: webSocketNotifiedTxHash))")
        if webSocketNotifiedTxHash! == self.sendTxHash! && !self.showedPromptedForSentPaymentTxHashSet.contains(webSocketNotifiedTxHash!) {
            DLog("finishSend 2 \(String(describing: webSocketNotifiedTxHash))")
            self.showedPromptedForSentPaymentTxHashSet.add(webSocketNotifiedTxHash!)
            sendTimer?.invalidate()
            self.showPromptPaymentSent(webSocketNotifiedTxHash!, address: self.toAddress!, amount: self.toAmount!)
        }
    }
    
    func initiateSend() {
        let unspentOutputsSum = self.getUnspentSum()
        if (unspentOutputsSum?.less(TLSendFormData.instance().toAmount!))! {
            // can only happen if unspentOutputsSum is for some reason less then the balance computed from the transactions, which it shouldn't
            cancelSend()
            let unspentOutputsSumString = TLCurrencyFormat.coinToProperBitcoinAmountString(unspentOutputsSum!)
            self.prompt(title: "Error: Insufficient Funds".localized, message: String(format: "Some funds may be pending confirmation and cannot be spent yet. (Check your account history) Account only has a spendable balance of %@ %@".localized, unspentOutputsSumString, TLCurrencyFormat.getBitcoinDisplay()))
            return
        }
        
        let toAddressesAndAmount = NSMutableDictionary()
        toAddressesAndAmount.setObject(TLSendFormData.instance().getAddress()!, forKey: "address" as NSCopying)
        toAddressesAndAmount.setObject(TLSendFormData.instance().toAmount!, forKey: "amount" as NSCopying)
        let toAddressesAndAmounts = NSArray(objects: toAddressesAndAmount)
        
        let signTx = !AppDelegate.instance().godSend!.isColdWalletAccount()
        let ret = AppDelegate.instance().godSend!.createSignedSerializedTransactionHex(toAddressesAndAmounts,
                                                                                       feeAmount: TLSendFormData.instance().feeAmount!,
                                                                                       signTx: signTx,
                                                                                       error: {
                                                                                        (data: String?) in
                                                                                        self.cancelSend()
                                                                                        self.prompt(title: "Error".localized, message: data ?? "")
        })
        
        let txHexAndTxHash = ret.0
        self.realToAddresses = ret.1
        
        if txHexAndTxHash == nil {
            cancelSend()
            return
        }
        
        let txHex = txHexAndTxHash!.object(forKey: "txHex") as? String
        
        if (txHex == nil) {
            //should not reach here, because I check sum of unspent outputs already,
            // unless unspent outputs contains dust and are require to filled the amount I want to send
            cancelSend()
            return
        }
        
        if AppDelegate.instance().godSend!.isColdWalletAccount() {
            cancelSend()
            let txInputsAccountHDIdxes = ret.2
            let inputScripts = txHexAndTxHash!.object(forKey: "inputScripts") as! NSArray
            self.promptToSignTransaction(txHex!, inputScripts:inputScripts, txInputsAccountHDIdxes:txInputsAccountHDIdxes!)
            return;
        }
        let txHash = txHexAndTxHash!.object(forKey: "txHash") as? String
        prepAndBroadcastTx(txHex!, txHash: txHash!)
    }
    
    func getUnspentSum() -> (TLCoin?) {
        self.unspentOutputs = AppDelegate.instance().godSend?.unspentOutputsArray
        if (unspentOutputsSum != nil) {
            return unspentOutputsSum
        }
        
        if (unspentOutputs == nil) {
            return TLCoin.zero()
        }
        
        var unspentOutputsSumTemp:UInt64 = 0
        for unspentOutput in unspentOutputs as! [NSDictionary] {
            let amount = unspentOutput.object(forKey: "value") as! NSNumber
            unspentOutputsSumTemp += UInt64(amount)
        }
        
        
        unspentOutputsSum = TLCoin(uint64: unspentOutputsSumTemp)
        return unspentOutputsSum
    }
    
    func prepAndBroadcastTx(_ txHex: String, txHash: String) {
        if (TLSendFormData.instance().getAddress() == AppDelegate.instance().godSend!.getStealthAddress()) {
            AppDelegate.instance().pendingSelfStealthPaymentTxid = txHash
        }
        
        if AppDelegate.instance().godSend!.isPaymentToOwnAccount(TLSendFormData.instance().getAddress()!) {
            self.amountMovedFromAccount = TLSendFormData.instance().feeAmount!
        } else {
            self.amountMovedFromAccount = TLSendFormData.instance().toAmount!.add(TLSendFormData.instance().feeAmount!)
        }
        
        for address in self.realToAddresses! {
            TLTransactionListener.instance().listenToIncomingTransactionForAddress(address)
        }
        
        TLSendFormData.instance().beforeSendBalance = AppDelegate.instance().godSend!.getCurrentFromBalance()
        self.sendTxHash = txHash
        self.toAddress = TLSendFormData.instance().getAddress()
        self.toAmount = TLSendFormData.instance().toAmount
        DLog("showPromptReviewTx txHex: \(txHex)")
        DLog("showPromptReviewTx txHash: \(txHash)")
        broadcastTx(txHex, txHash: txHash, toAddress: TLSendFormData.instance().getAddress()!)
    }
    
    func broadcastTx(_ txHex: String, txHash: String, toAddress: String) {
        let handlePushTxSuccess = { () -> () in
            NotificationCenter.default.post(name: Notification.Name(rawValue: TLNotificationEvents.EVENT_SEND_PAYMENT()),
                                            object: nil, userInfo: nil)
        }
        
        TLPushTxAPI.instance().sendTx(txHex, txHash: txHash, toAddress: toAddress, success: {
            (jsonData) in
            DLog("showPromptReviewTx pushTx: success \(jsonData)")
            
            if TLStealthAddress.isStealthAddress(toAddress, isTestnet:false) == true {
                // doing stealth payment with push tx insight get wrong hash back??
                let txid = (jsonData as! NSDictionary).object(forKey: "txid") as! String
                DLog("showPromptReviewTx pushTx: success txid \(txid)")
                DLog("showPromptReviewTx pushTx: success txHash \(txHash)")
                if txid != txHash {
                    NSException(name: NSExceptionName(rawValue: "API Error"), reason:"txid return does not match txid in app", userInfo:nil).raise()
                }
            }
            
//            if let label = AppDelegate.instance().appWallet.getLabelForAddress(toAddress) {
//                AppDelegate.instance().appWallet.setTransactionTag(txHash, tag: label)
//            }
            handlePushTxSuccess()
            
        }, failure: {
            (code, status) in
            DLog("showPromptReviewTx pushTx: failure \(code) \(String(describing: status))")
            if (code == 200) {
                handlePushTxSuccess()
            } else {
                self.prompt(title: "Error".localized, message: status!)
                self.cancelSend()
            }
        })
    }
    
    func showNextUnsignedTxPartQRCode() {
        if self.airGapDataBase64PartsArray == nil {
            return
        }
        let nextAipGapDataPart = self.airGapDataBase64PartsArray![0]
        self.airGapDataBase64PartsArray!.remove(at: 0)
        self.QRImageModal = TLQRImageModal(data: nextAipGapDataPart as NSString, buttonCopyText: "Next".localized, vc: self)
        self.QRImageModal!.show()
    }
    
    func promptToSignTransaction(_ unSignedTx: String, inputScripts:NSArray, txInputsAccountHDIdxes:NSArray) {
        let extendedPublicKey = AppDelegate.instance().godSend!.getExtendedPubKey()
        if let airGapDataBase64 = TLColdWallet.createSerializedUnsignedTxAipGapData(unSignedTx, extendedPublicKey: extendedPublicKey!, inputScripts: inputScripts, txInputsAccountHDIdxes: txInputsAccountHDIdxes) {
            self.airGapDataBase64PartsArray = TLColdWallet.splitStringToArray(airGapDataBase64)
            DLog("airGapDataBase64PartsArray \(String(describing: airGapDataBase64PartsArray))")
            self.promtForOKCancel(self, title: "Spending from a cold wallet account".localized, message: "Transaction needs to be authorize by an offline and airgap device. Send transaction to an offline device for authorization?", success: {
                () in
                self.showNextUnsignedTxPartQRCode()
            }, failure: {
                (isCancelled: Bool) in
            })
        }
    }
    
    @IBAction func customizeFeeButtonClicked(_ sender: AnyObject) {
        showPromptForSetTransactionFee()
    }
    
    @IBAction func feeInfoButtonClicked(_ sender: AnyObject) {
        self.prompt(title: "Transaction Fees", message: "Transaction fees impact how quickly the Bitcoin mining network will confirm your transactions, and depend on the current network conditions.")
    }
    
    @IBAction func sendButtonClicked(_ sender: AnyObject) {
//        self.startSendTimer()
        AppDelegate.instance().godSend!.getAndSetUnspentOutputs(address: AppDelegate.instance().address!, {
            self.initiateSend()
        }, failure: {
            self.cancelSend()
            self.prompt(title: "Error".localized, message: "Error fetching unspent outputs. Try again.".localized)
        })
    }
    
    @IBAction fileprivate func cancel(_ sender:AnyObject) {
        self.dismiss(animated: true, completion:nil)
    }
    
    func startSendTimer() {
//        TLHUDWrapper.showHUDAddedTo(self.view, labelText: "Sending".localized, animated: true)
        // relying on websocket to know when a payment has been sent can be unreliable, so cancel after a certain time
        let TIME_TO_WAIT_TO_HIDE_HUD_AND_REFRESH_ACCOUNT = 13.0
        sendTimer = Timer.scheduledTimer(timeInterval: TIME_TO_WAIT_TO_HIDE_HUD_AND_REFRESH_ACCOUNT, target: self,
                                         selector: #selector(retryFinishSend), userInfo: nil, repeats: false)
    }
    
    func didClickScanSignedTxButton() {
        scanSignedTx(success: { () in
            DLog("didClickScanSignedTxButton success");
            
            if self.totalExpectedParts != 0 && self.scannedSignedTxAirGapDataPartsDict.count == self.totalExpectedParts {
                self.shouldPromptToScanSignedTxAirGapData = false
                
                self.scannedSignedTxAirGapData = ""
                for i in stride(from: 1, through: self.totalExpectedParts, by: 1) {
                    let dataPart = self.scannedSignedTxAirGapDataPartsDict[i]
                    self.scannedSignedTxAirGapData = self.scannedSignedTxAirGapData! + dataPart!
                }
                self.scannedSignedTxAirGapDataPartsDict = [Int:String]()
                DLog("didClickScanSignedTxButton self.scannedSignedTxAirGapData \(String(describing: self.scannedSignedTxAirGapData))");
                
                if let signedTxData = TLColdWallet.getSignedTxData(self.scannedSignedTxAirGapData!) {
                    DLog("didClickScanSignedTxButton signedTxData \(signedTxData)");
                    let txHex = signedTxData["txHex"] as! String
                    let txHash = signedTxData["txHash"] as! String
                    let txSize = signedTxData["txSize"] as! NSNumber
                    DLog("didClickScanSignedTxButton txHex \(txHex)");
                    DLog("didClickScanSignedTxButton txHash \(txHash)");
                    DLog("didClickScanSignedTxButton txSize \(txSize)");
                    
                    self.signedAirGapTxHex = txHex
                    self.signedAirGapTxHash = txHash
                    self.shouldPromptToBroadcastSignedTx = true
                }
            } else {
                self.shouldPromptToScanSignedTxAirGapData = true
            }
            
        }, error: {
            () in
            DLog("didClickScanSignedTxButton error");
        })
    }
    
    func scanSignedTx(success: @escaping (TLWalletUtils.Success), error: @escaping (TLWalletUtils.Error)) {
        SendViewController.instance().showAddressReaderControllerFromViewController(self, success: {
            (data: String!) in
            let ret = TLColdWallet.parseScannedPart(data)
            let dataPart = ret.0
            let partNumber = ret.1
            let totalParts = ret.2
            
            self.totalExpectedParts = totalParts
            self.scannedSignedTxAirGapDataPartsDict[partNumber] = dataPart
            
            DLog("scanSignedTx \(dataPart) \(partNumber) \(totalParts)");
            success()
        }, error: {
            (data: String?) in
            error()
        })
    }
    
    func promptToScanSignedTxAirGapData() {
        let msg = "\(self.scannedSignedTxAirGapDataPartsDict.count)/\(self.totalExpectedParts)" + " parts scanned.".localized
        self.promptAlertController(title: "Scan next part".localized, message: msg)
    }
    
    func customIOS7dialogButtonTouchUp(inside alertView: CustomIOS7AlertView, clickedButtonAt buttonIndex: Int) {
        if (buttonIndex == 0) {
            if self.airGapDataBase64PartsArray?.count > 0 {
                self.showNextUnsignedTxPartQRCode()
            } else {
                self.promptAlertController(title: "Finished Passing Transaction Data".localized,
                                           message: "Now authorize the transaction on your air gap device. When you have done so click continue on this device to scan the authorized transaction data and make your payment.".localized)
            }
        }
        
        alertView.close()
    }
    
    func promptToBroadcastColdWalletAccountSignedTx(txHex: String, txHash: String) {
        let alert = UIAlertController(title: "Send authorized payment?".localized, message: "", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Send".localized, style: .default) { (action) in
//            self.startSendTimer()
            self.prepAndBroadcastTx(txHex, txHash: txHash)
        })
        alert.addAction(UIAlertAction(title: "Cancel".localized, style: .destructive) { (action) in
        })
        self.present(alert, animated: true, completion: nil)
    }
    
    func promptAlertController(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Continue".localized, style: .default) { (action) in
            self.didClickScanSignedTxButton()
        })
        alert.addAction(UIAlertAction(title: "Cancel".localized, style: .destructive) { (action) in
        })
        self.present(alert, animated: true, completion: nil)
    }
    
    func prompt(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        self.present(alert, animated: true, completion: nil)
    }
    
    func promptForOK(_ vc:UIViewController, title: String, message: String,
                     success: @escaping TLWalletUtils.Success) -> () {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        self.present(alert, animated: true, completion: success)
    }
}
