//
//  VerificationViewController.swift
//  FastCash
//
//  Created by Trevor Carpenter on 1/18/21.
//  Copyright © 2021 Trevor Carpenter. All rights reserved.
//

import UIKit

class VerificationViewController: UIViewController, PinTextFieldDelegate {

    @IBOutlet weak var OTP1: PinTextField!
    @IBOutlet weak var OTP2: PinTextField!
    @IBOutlet weak var OTP3: PinTextField!
    @IBOutlet weak var OTP4: PinTextField!
    @IBOutlet weak var OTP5: PinTextField!
    @IBOutlet weak var OTP6: PinTextField!
    @IBOutlet weak var ErrorLabel: UILabel!
    
    @IBOutlet weak var sentToNumber: UILabel!
    
    var fields: [PinTextField] = []
    var phoneNum: String = ""
    var currentField = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.fields.append(OTP1)
        self.fields.append(OTP2)
        self.fields.append(OTP3)
        self.fields.append(OTP4)
        self.fields.append(OTP5)
        self.fields.append(OTP6)
        
        self.fields = self.fields.map({$0.delegate = self; return $0})
        self.moveCursor(OTP1)
        sentToNumber.text = "Code was sent to \(self.phoneNum)"
        
        self.navigationController?.navigationBar.isHidden = false
    }
    
    func didPressBackspace(textField: PinTextField) {
        
        // moving back is a little confusing since it competes with the code for moving forward, which occurs whenever a textbox value is changed. I have outlined how we function in 4 cases based on the question: are we in the first box, and are we empty or full?
        if self.currentField > 5 {
            self.currentField = 5
        }
        let boxEmpty = (self.fields[self.currentField].text ?? "").count == 0
        let firstBox = self.currentField == 0
        
        // case 1: We aren't in the first box but we are empty, in which case we clear the previous box and move into its space
        if !firstBox && boxEmpty {
            self.currentField -= 1
            self.fields[currentField].text = ""
            self.moveCursor(self.fields[currentField])
        }
        // case 2: We aren't in the first box and we aren't empty. In this case we let the backspace clear our box, and move backwards 2 because we know that the edited function will move us forward 1 and so the summed end result will only be back 1 (a little hacky, but works)
        else if !firstBox && !boxEmpty{
            self.currentField -= 2
        }
        // case 3: We are in the first box and we aren't empty. This is essentially the previous case, but since we can't go back any further because we are in the first box already, we let the backspace delete our box contents and only decrement currentField by one to cancel out the editingChanged
        else if firstBox && !boxEmpty {
            self.currentField -= 1
        }
        // case 4: The last scenario is that we are in an empty first box, in which case there is nothing to do; editingChanged won't push us forward and we can't go backward. So there's no code for this case
        
    }
    
    func verify() {
        
        Api.verifyCode(phoneNumber: self.phoneNum,
                       code: self.fields.compactMap({$0.text}).reduce("", {$0 + $1}),
                       completion: { response, error in
            if let resp = response {
                
                // succesful verification, so set storage info
                Storage.phoneNumberInE164 = self.phoneNum
                Storage.authToken = resp["auth_token"] as? String
                
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewController(identifier: "home")
                guard let navC = self.navigationController else {
                    assertionFailure("couldn't find navigation controller")
                    return
                }
                
                navC.setViewControllers([vc], animated: true)
            }
            else {
                self.ErrorLabel.text = error?.message
                self.ErrorLabel.textColor = .systemRed
            }
        })
    }
    
    // code to set the cursor location when a box is touched
    @IBAction func moveCursor(_ sender: PinTextField) {
        
        guard var indexOfSender = Int(sender.accessibilityLabel ?? "") else {
            assertionFailure("Unable to parse sender label")
            return
        }
        let textCount = self.fields.compactMap({$0.text}).reduce("", {$0 + $1}).count
        
        // I don't want the user to be able to set the cursor past the leftmost empty textbox to avoid holes in the code
        if indexOfSender > textCount{
            indexOfSender = textCount
        }
        self.fields[indexOfSender].becomeFirstResponder()
        self.fields = self.fields.map {$0.layer.borderColor = UIColor.lightGray.cgColor; $0.layer.borderWidth = 2.0; return $0}
        self.fields[indexOfSender].layer.borderColor = UIColor.systemGreen.cgColor
        self.currentField = indexOfSender
    }
    
    // code for what to do when the field is being edited
    @IBAction func editedField(_ sender: Any) {
        // empty error label
        self.ErrorLabel.text = ""
        
        // get what the text looks like as a whole
        let text = self.fields.compactMap({$0.text}).reduce("", {$0 + $1})
        // if we go over the text length, we want to fill with "blanks" or empty strings
        var fireBlanks = false
        for (field, index) in zip(self.fields, 1...6) {
            if fireBlanks {
                field.text = ""
            }
            else if index > text.count {
                field.text = ""
                fireBlanks = true
            }
            else {
                field.text = String(text[text.index(text.startIndex, offsetBy: index-1)])
            }
        }
        // increment current active field
        self.currentField += 1
        
        // if we are in an early field and the next field is empty, lets show the user that they are going to type into that one
        if self.currentField < 5 && (self.fields[currentField+1].text ?? "").count == 0 {
            self.currentField += 1
        }
        
        // verify if we have a code of length 6!
        if text.count == 6 {
            self.verify()
        } else {
            self.moveCursor(self.fields[currentField])
        }
    }
    
    @IBAction func resendCode(_ sender: Any) {
        Api.sendVerificationCode(phoneNumber: self.phoneNum, completion: { response, error in
            if let _ = response {
                self.ErrorLabel.text = ""
                self.ErrorLabel.textColor = .black
            }
            if let err = error {
                self.ErrorLabel.text = err.message
                self.ErrorLabel.textColor = .systemRed
            }
        })
    }

}
