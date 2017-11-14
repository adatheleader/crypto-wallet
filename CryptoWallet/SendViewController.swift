//
//  SendViewController.swift
//  CryptoWallet
//
//  Created by Лидия Хашина on 28.10.2017.
//  Copyright © 2017 Лидия Хашина. All rights reserved.
//

import UIKit
import AVFoundation

class SendViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var toAddressTextField: UITextField!
    @IBOutlet weak var mainBTCAddress: UILabel!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var fiatAmountTextField: UITextField!
    
    fileprivate var tapGesture: UITapGestureRecognizer?
    
    class func instance() -> SendViewController {
        return UIApplication.shared.delegate as! (SendViewController)
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.mainBTCAddress.text = AppDelegate.instance().address
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func scanQRCode(_ sender: Any) {
        self.showAddressReaderControllerFromViewController(self, success: {
            (data: String!) in
            self.handleScannedAddress(data)
        }, error: {
            (data: String?) in
        })
    }
    
    func showAddressReaderControllerFromViewController(_ viewController: (UIViewController), success: @escaping (TLWalletUtils.SuccessWithString), error: @escaping (TLWalletUtils.ErrorWithString)) {
        if (!isCameraAllowed()) {
            self.prompt(title: "CryptoWallet is not allowed to access the camera", message: "Allow camera access in\n Settings->Privacy->Camera->CryptoWallet")
            return
        }
        
        let reader = QRCodeScannerViewController(success:{(data: String?) in
            success(data)
        }, error:{(e: String?) in
            error(e)
        })
        
        viewController.present(reader, animated:true, completion:nil)
    }
    
    fileprivate func isCameraAllowed() -> Bool {
        return AVCaptureDevice.authorizationStatus(for: AVMediaType.video) != AVAuthorizationStatus.denied
    }
    
    fileprivate func prompt(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        self.present(alert, animated: true, completion: nil)
    }
    
    fileprivate func handleScannedAddress(_ data: String) {
        if (data.hasPrefix("bitcoin:")) {
            let parsedBitcoinURI = TLWalletUtils.parseBitcoinURI(data)
            if parsedBitcoinURI == nil {
                self.prompt(title: "Error", message: "URL does not contain an address.")
                return
            }
            let address = parsedBitcoinURI!.object(forKey: "address") as! String?
            if (address == nil) {
                self.prompt(title: "Error", message: "URL does not contain an address.")
                return
            }
            
            let success = self.fillToAddressTextField(address!)
            if (success) {
                let parsedBitcoinURIAmount = parsedBitcoinURI!.object(forKey: "amount") as! String?
                if (parsedBitcoinURIAmount != nil) {
                    let coinAmount = TLCoin(bitcoinAmount: parsedBitcoinURIAmount!, bitcoinDenomination: TLBitcoinDenomination.bitcoin)
                    let amountString = TLCurrencyFormat.coinToProperBitcoinAmountString(coinAmount)
                    self.amountTextField!.text = amountString
                    self.updateFiatAmountTextFieldExchangeRate([])
                    TLSendFormData.instance().setAmount(amountString)
                    TLSendFormData.instance().setFiatAmount(nil)
                }
            }
        } else {
            self.fillToAddressTextField(data)
        }
    }
    
    fileprivate func fillToAddressTextField(_ address: String) -> Bool {
        if (TLCoreBitcoinWrapper.isValidAddress(address, isTestnet: false)) {
            self.toAddressTextField!.text = address
            TLSendFormData.instance().setAddress(address)
            return true
        } else {
            self.prompt(title: "Invalid Bitcoin Address", message: "")
            return false
        }
    }
    
    @IBAction func updateFiatAmountTextFieldExchangeRate(_ sender: Any) {
        print("updateFiatAmountTextFieldExchangeRate")
        let currency = TLCurrencyFormat.getFiatCurrency()
        let amount = TLCurrencyFormat.properBitcoinAmountStringToCoin(self.amountTextField!.text!)
        
        if (amount.greater(TLCoin.zero())) {
            self.fiatAmountTextField!.text = TLExchangeRate.instance().fiatAmountStringFromBitcoin(currency,
                                                                                                   bitcoinAmount: amount)
            TLSendFormData.instance().toAmount = amount
        } else {
            self.fiatAmountTextField!.text = nil
            TLSendFormData.instance().toAmount = nil
        }
    }
    
    @IBAction func updateAmountTextFieldExchangeRate(_ sender: Any) {
        print("updateAmountTextFieldExchangeRate")
        let currency = TLCurrencyFormat.getFiatCurrency()
        let fiatFormatter = NumberFormatter()
        fiatFormatter.numberStyle = .decimal
        fiatFormatter.maximumFractionDigits = 2
        let fiatAmount = fiatFormatter.number(from: self.fiatAmountTextField!.text!)
        if fiatAmount != nil && fiatAmount! != 0 {
            let bitcoinAmount = TLExchangeRate.instance().bitcoinAmountFromFiat(currency, fiatAmount: fiatAmount!.doubleValue)
            self.amountTextField!.text = TLCurrencyFormat.coinToProperBitcoinAmountString(bitcoinAmount)
            TLSendFormData.instance().toAmount = bitcoinAmount
        } else {
            self.amountTextField!.text = nil
            TLSendFormData.instance().toAmount = nil
        }
    }
    
    @IBAction func reviewPayment(_ sender: Any) {
        self.dismissKeyboard()
        
        let toAddress = self.toAddressTextField!.text
        TLSendFormData.instance().setAddress(toAddress)
        if toAddress != nil && TLStealthAddress.isStealthAddress(toAddress!, isTestnet: false) {
            func checkToShowStealthPaymentDelayInfo() {
                if TLSuggestions.instance().enabledShowStealthPaymentDelayInfo() && TLBlockExplorerAPI.STATIC_MEMBERS.blockExplorerAPI == .blockchain {
                    let msg = "Sending payment to a reusable address might take longer to show up then a normal transaction with the blockchain.info API. You might have to wait until at least 1 confirmation for the transaction to show up. This is due to the limitations of the blockchain.info API. For reusable address payments to show up faster, configure your app to use the Insight API in advance settings.".localized
                    self.promptForOK(self, title:"Warning", message:msg, success: {
                        () in
                        TLSuggestions.instance().setEnableShowStealthPaymentDelayInfo(false)
                    })
                } else {
                    self._reviewPaymentClicked()
                }
            }
            
            if TLSuggestions.instance().enabledShowStealthPaymentNote() {
                let msg = "You are making a payment to a reusable address. Make sure that the receiver can see the payment made to them. (All ArcBit reusable addresses are compatible with other ArcBit wallets)".localized
                self.promptForOK(self, title:"Note", message:msg, success: {
                    () in
                    self._reviewPaymentClicked()
                    TLSuggestions.instance().setEnableShowStealthPaymentNote(false)
                    checkToShowStealthPaymentDelayInfo()
                })
            } else {
                checkToShowStealthPaymentDelayInfo();
            }
            
        } else {
            self._reviewPaymentClicked()
        }
    }
    
    func _reviewPaymentClicked() {
        self.checkTofetchFeeThenFinalPromptReviewTx()
    }
    
    func promptForOK(_ vc:UIViewController, title: String, message: String,
                    success: @escaping TLWalletUtils.Success) -> () {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        self.present(alert, animated: true, completion: success)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: (NSRange), replacementString string: String) -> Bool {
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        if (textField == self.toAddressTextField) {
            TLSendFormData.instance().setAddress(newString)
        } else if (textField == self.amountTextField) {
            TLSendFormData.instance().setAmount(newString)
            TLSendFormData.instance().setFiatAmount(nil)
            TLSendFormData.instance().useAllFunds = false
        } else if (textField == self.fiatAmountTextField) {
            TLSendFormData.instance().setFiatAmount(newString)
            TLSendFormData.instance().setAmount(nil)
            TLSendFormData.instance().useAllFunds = false
        }
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        if (self.tapGesture == nil) {
            self.tapGesture = UITapGestureRecognizer(target: self,
                                                     action: #selector(SendViewController.dismissKeyboard))
            
            self.view.addGestureRecognizer(self.tapGesture!)
        }
        
//        self.setAllCoinsBarButton()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        NotificationCenter.default.addObserver(self, selector: #selector(SendViewController.dismissTextFieldsAndScrollDown(_:)), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        
        if textField == self.amountTextField || textField == self.fiatAmountTextField {
            self.checkTofetchFeeThenFinalPromptReviewTx()
        }
        return true
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        if (textField == self.toAddressTextField) {
            TLSendFormData.instance().setAddress(nil)
        }
        
        return true
    }
    
    @objc func dismissKeyboard() {
        self.amountTextField!.resignFirstResponder()
        self.fiatAmountTextField!.resignFirstResponder()
        self.toAddressTextField!.resignFirstResponder()
        if self.tapGesture != nil {
            self.view.removeGestureRecognizer(self.tapGesture!)
            self.tapGesture = nil
        }
    }
    
    fileprivate func checkTofetchFeeThenFinalPromptReviewTx() {
        if TLPreferences.enabledInAppSettingsKitDynamicFee() && !AppDelegate.instance().txFeeAPI.haveUpdatedCachedDynamicFees() {
            AppDelegate.instance().txFeeAPI.getDynamicTxFee({
                (_jsonData) in
                self.showFinalPromptReviewTx()
            }, failure: {
                (code, status) in
                self.showFinalPromptReviewTx()
            })
        } else {
            self.showFinalPromptReviewTx()
        }
    }
    
    @objc func dismissTextFieldsAndScrollDown(_ notification: Notification) {
        self.fiatAmountTextField!.resignFirstResponder()
        self.amountTextField!.resignFirstResponder()
        self.toAddressTextField!.resignFirstResponder()
    }
    
    fileprivate func showFinalPromptReviewTx() {
        let bitcoinAmount = self.amountTextField!.text
        let toAddress = self.toAddressTextField!.text
        
        if (!TLCoreBitcoinWrapper.isValidAddress(toAddress!, isTestnet: false)) {
            self.prompt(title: "Error", message: "You must provide a valid bitcoin address.")
            return
        }
        
        DLog("showFinalPromptReviewTx bitcoinAmount \(bitcoinAmount!)")
        let inputtedAmount = TLCurrencyFormat.properBitcoinAmountStringToCoin(bitcoinAmount!)
        
        if (inputtedAmount.equalTo(TLCoin.zero())) {
            self.prompt(title: "Error", message: "Amount entered must be greater then zero.")
            return
        }
        
        
        func showReviewPaymentViewController(_ useDynamicFees: Bool) {
            let fee:TLCoin
            let txSizeBytes:UInt64
            if useDynamicFees {
                if TLSendFormData.instance().useAllFunds {
                    fee = TLSendFormData.instance().feeAmount!
                } else {
                    if (AppDelegate.instance().godSend!.getSelectedObjectType() == .account) {
                        let accountObject = AppDelegate.instance().godSend!.getSelectedSendObject() as! TLAccountObject
                        let inputCount = accountObject.getInputsNeededToConsume(inputtedAmount)
                        //TODO account for change output, output count likely 2 (3 if have stealth payment) cause if user dont do click use all funds because will likely have change
                        // but for now dont need to be fully accurate with tx fee, for now we will underestimate tx fee, wont underestimate much because outputs contributes little to tx size
                        txSizeBytes = AppDelegate.instance().godSend!.getEstimatedTxSize(inputCount, outputCount: 1)
                        DLog("showPromptReviewTx TLAccountObject useDynamicFees inputCount txSizeBytes: \(inputCount) \(txSizeBytes)")
                    } else {
                        let importedAddress = AppDelegate.instance().godSend!.getSelectedSendObject() as! TLImportedAddress
                        // TODO same as above
                        let inputCount = importedAddress.getInputsNeededToConsume(inputtedAmount)
                        txSizeBytes = AppDelegate.instance().godSend!.getEstimatedTxSize(inputCount, outputCount: 1)
                        DLog("showPromptReviewTx importedAddress useDynamicFees inputCount txSizeBytes: \(importedAddress.unspentOutputsCount) \(txSizeBytes)")
                    }
                    
                    if let dynamicFeeSatoshis:NSNumber = AppDelegate.instance().txFeeAPI.getCachedDynamicFee() {
                        fee = TLCoin(uint64: txSizeBytes*dynamicFeeSatoshis.uint64Value)
                        DLog("showPromptReviewTx coinFeeAmount dynamicFeeSatoshis: \(txSizeBytes*dynamicFeeSatoshis.uint64Value)")
                        
                    } else {
                        fee = TLCurrencyFormat.bitcoinAmountStringToCoin(TLPreferences.getInAppSettingsKitTransactionFee()!)
                    }
                    TLSendFormData.instance().feeAmount = fee
                }
            } else {
                let feeAmount = TLPreferences.getInAppSettingsKitTransactionFee()
                fee = TLCurrencyFormat.bitcoinAmountStringToCoin(feeAmount!)
                TLSendFormData.instance().feeAmount = fee
            }
            
            let amountNeeded = inputtedAmount.add(fee)
            let accountBalance = AppDelegate.instance().updateAddressBalance(address: AppDelegate.instance().address!)
            if (amountNeeded.greater(accountBalance!)) {
                let msg = String(format: "You have %@ %@, but %@ is needed. (This includes the transactions fee)".localized, TLCurrencyFormat.coinToProperBitcoinAmountString(accountBalance!), TLCurrencyFormat.getBitcoinDisplay(), TLCurrencyFormat.coinToProperBitcoinAmountString(amountNeeded))
                self.prompt(title: "Insufficient Balance", message: msg)
                return
            }
            
            DLog("showPromptReviewTx accountBalance: \(String(describing: accountBalance?.toUInt64()))")
            DLog("showPromptReviewTx inputtedAmount: \(inputtedAmount.toUInt64())")
            DLog("showPromptReviewTx fee: \(fee.toUInt64())")
            TLSendFormData.instance().fromLabel = AppDelegate.instance().address
//            let vc = self.storyboard!.instantiateViewController(withIdentifier: "ReviewPayment") as! ReviewPaymentViewController
//            self.present(vc, animated: true, completion: nil)
            self.performSegue(withIdentifier: "reviewPayment", sender: nil)
        }
        
        func checkToFetchDynamicFees() {
            if !AppDelegate.instance().txFeeAPI.haveUpdatedCachedDynamicFees() {
                AppDelegate.instance().txFeeAPI.getDynamicTxFee({
                    (_jsonData) in
                    showReviewPaymentViewController(true)
                }, failure: {
                    (code, status) in
                    self.prompt(title: "Error", message: "Unable to query dynamic fees. Falling back on fixed transaction fee. (fee can be configured on review payment)")
                    showReviewPaymentViewController(false)
                })
            } else {
                showReviewPaymentViewController(true)
            }
        }
        
        if TLPreferences.enabledInAppSettingsKitDynamicFee() {
            if !AppDelegate.instance().godSend!.haveUpDatedUTXOs() {
                AppDelegate.instance().godSend!.getAndSetUnspentOutputs(address: AppDelegate.instance().address!, {
                    checkToFetchDynamicFees()
                }, failure: {
                    self.prompt(title: "Error", message: "Error fetching unspent outputs. Try again later.")
                })
            } else {
                checkToFetchDynamicFees()
            }
        } else {
            showReviewPaymentViewController(false)
        }
    }
}
