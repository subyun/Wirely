//
//  AccountViewController.swift
//  FastCash
//
//  Created by arfullight on 2/12/21.
//  Copyright © 2021 Trevor Carpenter. All rights reserved.
//

import UIKit

class AccountViewController: UIViewController, PopupEnded {
    
    var wallet = Wallet()
    var accountIndex: Int = -1
    var popup: CustomPopup? = Optional.none
    @IBOutlet weak var accountNameLabel: UILabel!
    @IBOutlet weak var accountAmountLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // set up popup
        let frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        let popup = CustomPopup(frame: frame)
        self.view.addSubview(popup)
        popup.isHidden = true
        popup.setKeyBoardType(type: UIKeyboardType.numberPad)
        popup.delegate = self
        self.popup = popup
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.accountNameLabel.text = self.wallet.accounts[self.accountIndex].name
        if self.accountIndex <= self.wallet.accounts.count - 1 {
            self.accountAmountLabel.text = self.formatMoney(amount: self.wallet.accounts[self.accountIndex].amount)
        }
    }
    
    func popupDidEnd(input: String, pickerData: Int?) {
        guard let selectedIndex = pickerData else { return }
        var amount = Double(input) ?? 0.0
        amount = self.checkBalance(withdrawAmount: amount)
        Api.transfer(wallet: self.wallet, fromAccountAt: self.accountIndex, toAccountAt: selectedIndex, amount: amount) { res, err in
            let homeVC = self.navigationController?.viewControllers.first as? HomeViewController
            homeVC?.updateWallet(response: res)
            self.accountAmountLabel.text = self.formatMoney(amount: self.wallet.accounts[self.accountIndex].amount)
        }
    }
    
    func popupValueIsValid(input: String, pickerData: Int?) -> Bool {
        let amount = Double(input) ?? 0.0
        let account = self.wallet.accounts[self.accountIndex]
        
        self.popup?.setError(error: "not enough money to transfer")
        return amount <= account.amount
    }
    
    func formatMoney(amount: Double) -> String {
        let charactersRev: [Character] = String(format: "$%.02f", amount).reversed()
        if charactersRev.count < 7 {
            return String(format: "$%.02f", amount)
        }
        var newChars: [Character] = []
        for (index, char) in zip(0...(charactersRev.count-1), charactersRev) {
            if (index-6)%3 == 0 && (index-6) > -1 && char != "$"{
                newChars.append(",")
                newChars.append(char)
            } else {
                newChars.append(char)
            }
        }
        
        return String(newChars.reversed())
    }
    
    @IBAction func doneButtonPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func depositButtonPressed(_ sender: Any) {

        let alertController = UIAlertController(title: "Deposit", message: "Enter the amount to deposit", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.keyboardType = .numberPad
        }
        let confirmAction = UIAlertAction(title: "Done", style: .default) { [weak alertController] _ in
            guard let alertController = alertController, let textField = alertController.textFields?.first else { return }
            guard let unwrapUserInput = textField.text else {return}
            let depositAmount = Double(unwrapUserInput) ?? 0.0
            Api.deposit(wallet: self.wallet, toAccountAt: self.accountIndex, amount: depositAmount) { res, err in
                let homeVC = self.navigationController?.viewControllers.first as? HomeViewController
                homeVC?.updateWallet(response: res)
                self.accountAmountLabel.text = self.formatMoney(amount: self.wallet.accounts[self.accountIndex].amount)
            }
        }
        alertController.addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func withdrawButtonPressed(_ sender: Any) {
        let alertController = UIAlertController(title: "Withdrawl", message: "Enter the amount to withdraw", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.keyboardType = .numberPad
        }
        let confirmAction = UIAlertAction(title: "Done", style: .default) { [weak alertController] _ in
            guard let alertController = alertController, let textField = alertController.textFields?.first else { return }
            guard let unwrapUserInput = textField.text else {return}
            var userInputAmount = Double(unwrapUserInput) ?? 0.0
            userInputAmount = self.checkBalance(withdrawAmount: userInputAmount)
            Api.withdraw(wallet: self.wallet, fromAccountAt: self.accountIndex, amount: userInputAmount) { res, err in
                let homeVC = self.navigationController?.viewControllers.first as? HomeViewController
                homeVC?.updateWallet(response: res)
                self.accountAmountLabel.text = self.formatMoney(amount: self.wallet.accounts[self.accountIndex].amount)
            }
        }
        alertController.addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func checkBalance(withdrawAmount: Double) -> Double {
        let currBalance = self.wallet.accounts[self.accountIndex].amount
        if (withdrawAmount <= currBalance) {
            return withdrawAmount
        } else {
            return currBalance
        }
    }
    
    @IBAction func transferButtonPressed(_ sender: Any) {
        self.popup?.setTitle(title: "test")
        let pickerData: [String] = self.wallet.accounts.map { "\($0.name) \(self.formatMoney(amount: $0.amount))" }
        self.popup?.setPickerData(pickerData)
        self.popup?.setPicker(enabled: true)
        self.popup?.setKeyBoardType(type: UIKeyboardType.numberPad)
        self.popup?.isHidden = false
    }
    
    @IBAction func deleteButtonPressed(_ sender: Any) {
        Api.removeAccount(wallet: self.wallet, removeAccountat: self.accountIndex) { res, err in
            let homeVC = self.navigationController?.viewControllers.first as? HomeViewController
            homeVC?.updateWallet(response: res)
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
