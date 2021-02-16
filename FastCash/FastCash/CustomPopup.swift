//
//  CustomPopup.swift
//  FastCash
//
//  Created by arfullight on 2/12/21.
//  Copyright © 2021 Trevor Carpenter. All rights reserved.
//

import Foundation
import UIKit

protocol PopupEnded {
    func popupDidEnd(input: String, pickerData: Int?)
    func popupValueIsValid(input: String, pickerData: Int?) -> Bool
}

class CustomPopup: UIView, UIPickerViewDelegate, UIPickerViewDataSource {
    var delegate: PopupEnded? = Optional.none
    var titleLabel: UILabel? = Optional.none
    var textField: UITextField? = Optional.none
    var errorLabel: UILabel? = Optional.none
    var picker: UIPickerView? = Optional.none
    var textFieldDefault: String = ""
    var usePicker: Bool = false
    var pickerData: [String] = []
    
    //initWithFrame to init view from code
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }

    //initWithCode to init view from xib or storyboard
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupView()
    }
    
    @objc private func onTap() {
        self.endEditing(true)
    }
    
    func setTextFieldDefault(defaultValue: String) {
        self.textField?.placeholder = defaultValue
    }
    
    func setTitle(title: String) {
        self.titleLabel?.text = title
    }
    
    // display this error if an account name already exist
    func setError(error: String) {
        self.errorLabel?.text = error
    }
    
    func setKeyBoardType(type: UIKeyboardType) {
        self.textField?.keyboardType = type
    }
    
    func setPicker(enabled: Bool) {
        self.usePicker = enabled
        self.setupView()
    }
    
    func setPickerData(_ data: [String]) {
        self.pickerData = data
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.pickerData[row]
    }

    //common func to init our view
    private func setupView() {
        // remove previous subview if any
        if self.subviews.count == 1 {
            let view = self.subviews[0]
            view.removeFromSuperview()
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTap))
        self.addGestureRecognizer(tapGesture)
        
        self.backgroundColor = UIColor(white: 1, alpha: 0.7)
        
        // create main window
        let windowWidth = Int(self.bounds.width) - 32 * 2
        let windowHeight = 250
        let frame = CGRect(x: Int(self.bounds.width) / 2 - windowWidth / 2, y: Int(self.bounds.height) / 2 - windowHeight / 2, width: windowWidth, height: windowHeight)
        let window = UIView(frame: frame)
        window.backgroundColor = .white
        window.layer.cornerRadius = 10
        window.layer.shadowColor = UIColor.black.cgColor
        window.layer.shadowOpacity = 0.6
        window.layer.shadowOffset = .zero
        window.layer.shadowRadius = 10
        
        // add title label
        let firstItemHeight = 50
        if self.usePicker {
            let picker = UIPickerView(frame: CGRect(x: 0, y: 16, width: windowWidth, height: firstItemHeight))
            picker.dataSource = self
            picker.delegate = self
            self.picker = picker
            window.addSubview(picker)
        } else {
            let headerLabel = UILabel(frame: CGRect(x: 0, y: 16, width: windowWidth, height: firstItemHeight))
            headerLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
            headerLabel.text = ""
            headerLabel.textAlignment = .center
            headerLabel.textColor = .black
            window.addSubview(headerLabel)
            self.titleLabel = headerLabel
        }
        
        // add textfield
        let textField = UITextField(frame: CGRect(x: 16, y: firstItemHeight + 32, width: windowWidth - 32, height: 40))
        let textFieldMaxY = 40 + 32 + 40
        textField.borderStyle = UITextField.BorderStyle.roundedRect
        window.addSubview(textField)
        self.textField = textField
        
        // add "Done" button
        let button = UIButton(frame: CGRect(x: windowWidth / 2 - 150 / 2, y: textFieldMaxY + 16, width: 125, height: 50))
        button.setTitle("Done", for: .normal)
        button.backgroundColor = .black
        button.layer.cornerRadius = button.bounds.height / 2
        button.addTarget(self, action: #selector(self.onClick), for: .touchUpInside)
        window.addSubview(button)
        
        // add Error Message
        let errorLabel = UILabel(frame: CGRect(x: 16, y: firstItemHeight + 150, width: windowWidth - 32, height: 20))
        errorLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        errorLabel.text = ""
        errorLabel.textColor = .red
        errorLabel.textAlignment = .center
        errorLabel.isHidden = true
        window.addSubview(errorLabel)
        self.errorLabel = errorLabel
        
        
        self.addSubview(window)
    }
    
    @objc func onClick(sender: UIButton) {
        if let delegate = self.delegate {
            guard var input = self.textField?.text else { return }
            let selected = self.picker?.selectedRow(inComponent: 0) ?? 0
            
            // check if the account name already exist
            if delegate.popupValueIsValid(input: input, pickerData: selected) {
                // create the account if name is valid
                self.endEditing(true)
                self.isHidden = true
                
                if input == "" {
                    input = self.textField?.placeholder ?? ""
                }
                
                if self.usePicker {
                    delegate.popupDidEnd(input: input, pickerData: selected)
                } else {
                    delegate.popupDidEnd(input: input, pickerData: nil)
                }
                
                self.textField?.text = ""
                self.errorLabel?.text = ""
            } else {
                self.errorLabel?.isHidden = false
            }
        }
    }
}
