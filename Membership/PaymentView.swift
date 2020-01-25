//
//  PaymentView.swift
//  SUGARED + BRONZED
//
//  Created by Parker Ryan on 7/18/18.
//  Copyright © 2018 SUGARED + BRONZED. All rights reserved.
//

import Foundation
import Firebase
import NVActivityIndicatorView

class PaymentView: UIViewController {
    
    
    var datePicker = MonthYearPickerView()
    var dateFormatter = DateFormatter()
    
    var previousTextFieldContent: String?
    var previousSelection: UITextRange?
    
    var selectedCellIndex: IndexPath? = nil
    var newCardToSelect: Card? = nil
    
    var cardExpFieldFormatted = ""
    
    var alert: UIAlertController?
    
    var activityIndicator: NVActivityIndicatorView! {
        didSet {
            activityIndicator.startAnimating()
            activityIndicator.isHidden = true
        }
    }
    var activityIndicatorContainerView: UIView! {
        didSet {
            activityIndicatorContainerView.isHidden = true
            activityIndicatorContainerView.backgroundColor = Design.Colors.blue.withAlphaComponent(0.7)
            activityIndicatorContainerView.layer.cornerRadius = 4
            activityIndicatorContainerView.layer.masksToBounds = true
        }
    }
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var dismissButton: UIButton!
    @IBAction func dismissButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet weak var paymentsTableView: UITableView!
    
    @IBOutlet weak var editCardView: UIView!
    @IBOutlet weak var cardModifyLabel: UILabel!
    
    @IBOutlet weak var cardNumberField: UITextField!
    @IBAction func cardNumberField(_ sender: Any) {
        
    }
    @IBOutlet weak var nameField: UITextField!
    @IBAction func nameField(_ sender: Any) {
        
    }
    @IBOutlet weak var cardCodeField: UITextField!
    @IBAction func cardCodeField(_ sender: Any) {
        
        if cardCodeField.text != nil && cardCodeField.text!.count > 4 {
            let alert = UIAlertController(title: "uh oh!", message: "it looks like there are too many characters in this security code, please double check your card and try again!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            cardCodeField.text = ""
            return
        }
        
    }

    @IBOutlet weak var cardExpField: UITextField!
    @IBAction func cardExpField(_ sender: Any) {
        
    }
    
    @IBOutlet weak var zipField: UITextField!
    @IBAction func zipField(_ sender: Any) {
    }
    
    
    @IBOutlet weak var saveCardButton: UIButton! {
        didSet {
            saveCardButton.layer.cornerRadius = 4
            saveCardButton.layer.masksToBounds = true
            saveCardButton.layer.borderColor = Design.Colors.blue.cgColor
            saveCardButton.layer.borderWidth = 1.0
        }
    }
    @IBAction func saveCardButton(_ sender: Any) {
    
        self.view.endEditing(true)
        
        guard zipField.text != nil && zipField.text!.count > 0 && Int(zipField.text!) != nil else {
            let alert = UIAlertController(title: "uh oh!", message: "it looks like there's something wrong with your zip code or it hasn't been entered, please double check and try again!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        
        guard cardNumberField.text != nil && cardNumberField.text!.count > 0 && !includesNumbersAndLetters(text: cardNumberField.text!) else {
            let alert = UIAlertController(title: "uh oh!", message: "it looks like there's something wrong with your card number or it hasn't been entered, please double check your card and try again!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        
        let cardNumber = cardNumberField.text!.replacingOccurrences(of: " ", with: "", options:[], range: nil)
        var cardType = 0
        switch CardState(fromNumber: cardNumber) {
        case .identified(let cardTypeValue):
            cardType = cardTypeValue.bookerID

        case .invalid:
            let alert = UIAlertController(title: "uh oh!", message: "it looks like there's something wrong with your card number, please double check your card and try again!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        case .indeterminate:
            let alert = UIAlertController(title: "uh oh!", message: "it looks like we don't support your card type or we couldn't determine it, please double check your card info and try again!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        
        guard nameField.text != nil && nameField.text!.count > 0 && !includesNumbersAndLetters(text: nameField.text!) else {
            let alert = UIAlertController(title: "uh oh!", message: "it looks like your card holder name hasn't been entered or has invalid characters, please double check your card and try again!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        
        guard cardCodeField.text != nil && cardCodeField.text!.count > 0  && cardCodeField.text!.count <= 4 && !includesNumbersAndLetters(text: cardCodeField.text!) else {
            let alert = UIAlertController(title: "uh oh!", message: "it looks like there's something wrong with your card security code, please double check your card and try again!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        
        guard cardExpFieldFormatted.count > 0 else {
            let alert = UIAlertController(title: "uh oh!", message: "it looks like there's something wrong with your card expiration or one hasn't been selected, please double check your card and try again!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
    
        let card = Card(name: nameField.text!, number: cardNumber, exp: cardExpFieldFormatted, code: cardCodeField.text!, type: cardType, zip: Int(zipField.text!)!)
        
        let match = Customer.cards.first { (cardItem) -> Bool in
            return cardItem.number.suffix(4) == card.number.suffix(4) && cardItem.expiryDate == card.expiryDate
        }
        
        paymentsTableView.deselectRow(at: selectedCellIndex!, animated: true)
        selectedCellIndex = nil
        editCardView.isHidden = true
       
        MembershipPurchase.cardSelected = card
        newCardToSelect = card
        continueButton.isHidden = false
        continueButtonSpacer.isHidden = false
        
        guard match == nil else {
            let alert = UIAlertController(title: "oh!", message: "it looks like that card already exists as a payment option on your account!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
    
        Customer.cards.append(card)
        paymentsTableView.reloadData()
    
    }

    @IBOutlet weak var continueButtonSpacer: UIButton! {
        didSet {
            continueButtonSpacer.isHidden = true
        }
    }
    @IBOutlet weak var continueButton: UIButton! {
        didSet {
            continueButton.isHidden = true
        }
    }
 
    @IBAction func continueButton(_ sender: Any) {
        
        self.view.endEditing(true)
        
        guard MembershipPurchase.cardSelected != nil else {
            let alert = UIAlertController(title: "uh oh!", message: "you must select a payment type before proceeding", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        
        guard self.activityIndicator.isHidden else {
            print("already attempting purchase")
            return
        }
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        self.activityIndicator.isHidden = false
        self.activityIndicatorContainerView.isHidden = false
        
        CustomerAPI().purchaseMembership(methodCompletion: { (success, error) -> Void in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self.activityIndicator.isHidden = true
                self.activityIndicatorContainerView.isHidden = true
                
                guard success else {
                    print("Failed to purchase membership: \(error)")
                    var alertMessage = ""
                    if error == "Customer already signed up for this membership" {
                        alertMessage = "looks like you're trying to purchase a membership you already have! please check your profile for memberships on file"
                    } else {
                        alertMessage = "it looks like there was a problem purchasing your membership, please try again later!"
                    }
                    self.alert = UIAlertController(title: "uh oh!", message: alertMessage, preferredStyle: .alert)
                    self.alert!.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(self.alert!, animated: true, completion: nil)
                    return
                }
                
                self.performSegue(withIdentifier: "toThankViewSegue", sender: nil)
            
            }
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        Analytics.setScreenName("PaymentView", screenClass: "app")
        
        //MARK: - Set Observers
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        selectedCellIndex = nil

        cardExpField.delegate = self
        cardNumberField.delegate = self
        cardCodeField.delegate = self
        nameField.delegate = self
        zipField.delegate = self
        
        paymentsTableView.delegate = self
        paymentsTableView.dataSource = self
        
        cardNumberField.tag = 0
        cardCodeField.tag = 1
        nameField.tag = 2
        cardExpField.tag = 3
        zipField.tag = 4
        
        cardCodeField.addToolbarButtonToKeyboard(myAction: #selector(self.cardCodeField.resignFirstResponder), title: "Done")
        zipField.addToolbarButtonToKeyboard(myAction: #selector(self.zipField.resignFirstResponder), title: "Done")
        nameField.addToolbarButtonToKeyboard(myAction: #selector(self.nameField.resignFirstResponder), title: "Done")
        cardNumberField.addToolbarButtonToKeyboard(myAction: #selector(self.cardNumberField.resignFirstResponder), title: "Done")
        cardNumberField.addTarget(self, action: #selector(reformatAsCardNumber), for: .editingChanged)
        
        
        
        editCardView.isHidden = true
        
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        
        //Format Date Picker Toolbar
        let toolbar = UIToolbar();
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneDatePicker))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        toolbar.setItems([spaceButton,doneButton], animated: false)
        cardExpField.inputAccessoryView = toolbar
        cardExpField.inputView = datePicker
        
        //MARK: - Create Activity Indicator
        activityIndicatorContainerView = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        self.view.addSubview(activityIndicatorContainerView)
        activityIndicator = NVActivityIndicatorView(frame: CGRect(x: view.center.x - 30, y: view.center.y, width: 60, height: 45), type: .ballPulseSync , color: .white, padding: 5)
        self.view.addSubview(activityIndicator)
    
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        activityIndicatorContainerView.center = view.center
        activityIndicator.center = view.center
    }
    
    @objc func doneDatePicker(){
        
        let datePickerText = "\(datePicker.month)/\(datePicker.year)"
        dateFormatter.dateFormat = "M/yyyy" //Date Picker Format
        let date = dateFormatter.date(from: datePickerText)
        guard date != nil else {
            print("error parsing date object from \(datePickerText)")
            return
        }
        
        dateFormatter.dateFormat =  "MM/yy" //Card Expiration Format
        cardExpField.text = dateFormatter.string(from: date!)
        
        dateFormatter.dateFormat =  "yyyy-MM-dd'T'HH:mm:ssxxxxx" //Booker v5 Date Format
        cardExpFieldFormatted = dateFormatter.string(from: date!)
        self.view.endEditing(true)
    }
    
    @objc func dismissKeyboard(){
        self.view.endEditing(true)
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        
        let contentInsets = UIEdgeInsets.zero
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        
        guard let userInfo = notification.userInfo else { return }
        guard var keyboardFrame: CGRect = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue else { return }
        keyboardFrame = self.view.convert(keyboardFrame, from: nil)
        
        var contentInset:UIEdgeInsets = scrollView.contentInset
        contentInset.bottom = keyboardFrame.size.height + 50
        scrollView.contentInset = contentInset
        
    }
    
}


extension PaymentView:  UITableViewDataSource {
    
    //MARK: - Configuring Cells
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Customer.cards.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard (indexPath.row + 1) != tableView.numberOfRows(inSection: 0) else { //check if not last row, else
            let cell = tableView.dequeueReusableCell(withIdentifier: "addPaymentCell") as! AddPaymentCell
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cardCell") as! CardCell
        
        let card = Customer.cards[indexPath.row]; cell.card = card
        
        cell.cardNumberLabel.text = String(repeating: "*", count: card.number.count - 4) + card.number.suffix(4)
        
        dateFormatter.timeZone =  TimeZone(abbreviation: "UTC")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssxxxxx"
        let date = dateFormatter.date(from: card.expiryDate)
        if date != nil  {
            dateFormatter.dateFormat = "MM/yy"
            cell.cardExpLabel.text = dateFormatter.string(from: date!)
            if date! < Date() { cell.cardUnusableIcon.isHidden = false }
        } else {
            print("error parsing date object from \(card.expiryDate)")
            cell.cardExpLabel.text = "EXP"
        }
        
        switch card.type {
        case 1:
            cell.cardTypeLabel.text = "AMEX"
            cell.cardTypeImage.image = UIImage(named: "card_amex")!
        case 2:
            cell.cardTypeLabel.text = "VISA"
            cell.cardTypeImage.image = UIImage(named: "card_visa")!
        case 3:
            cell.cardTypeLabel.text = "MasterCard"
            cell.cardTypeImage.image = UIImage(named: "card_mastercard")!
        case 4:
            cell.cardTypeLabel.text = "Discover"
            cell.cardTypeImage.image = UIImage(named: "card_discover")!
        case 5:
            cell.cardTypeLabel.text = "JCB"
        case 6:
            cell.cardTypeLabel.text = "DinersClub"
        case 7:
            cell.cardTypeLabel.text = "Maestro"
        case 8:
            cell.cardTypeLabel.text = "Solo"
        case 9:
            cell.cardTypeLabel.text = "Samsung"
        case 10:
            cell.cardTypeLabel.text = "ShinHan"
        case 11:
            cell.cardTypeLabel.text = "KookMin"
        case 12:
            cell.cardTypeLabel.text = "Lotte"
        case 13:
            cell.cardTypeLabel.text = "KEB"
        case 14:
            cell.cardTypeLabel.text = "BC"
        case 15:
            cell.cardTypeLabel.text = "HyunDai"
        case 16:
            cell.cardTypeLabel.text = "Naps"
        case 18:
            cell.cardTypeLabel.text = "ElectronVisa"
        case 19:
            cell.cardTypeLabel.text = "DeltaVisa"
        case 20:
            cell.cardTypeLabel.text = "NH"
        case 21:
            cell.cardTypeLabel.text = "JEJU"
        default:
            cell.cardTypeLabel.text = "Card"
            print("error determining card type!")
        }
        cell.cardTypeLabel.text = cell.cardTypeLabel.text!.uppercased()
        
        if newCardToSelect != nil && newCardToSelect!.equals(c2: card)  {
            cell.isSelected = true
            selectedCellIndex = indexPath
            MembershipPurchase.cardSelected = card
        }
        
        return cell
    }
}


extension PaymentView:  UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if selectedCellIndex != nil {
            tableView.deselectRow(at: selectedCellIndex!, animated: true)
        }
        
        guard selectedCellIndex != indexPath else { //if the selected row is already tapped on
            if (indexPath.row + 1) == tableView.numberOfRows(inSection: 0) { //check if last row
                editCardView.isHidden = true
                
            } else {
                MembershipPurchase.cardSelected = nil
                newCardToSelect = nil
                continueButton.isHidden = true
                continueButtonSpacer.isHidden = true
                editCardView.isHidden = true
            }
            selectedCellIndex = nil
            return
        }
        
        
        if (indexPath.row + 1) == tableView.numberOfRows(inSection: 0) { //if last row
            editCardView.isHidden = false
            MembershipPurchase.cardSelected = nil
            continueButton.isHidden = true
            continueButtonSpacer.isHidden = true
            
        } else {
            guard let cardInfo = (tableView.cellForRow(at: indexPath) as? CardCell), let cardValue = cardInfo.card else {
                print("error: cannot obtain card info")
                return
            }
            MembershipPurchase.cardSelected = cardValue
            
            continueButton.isHidden = false
            continueButtonSpacer.isHidden = false
            editCardView.isHidden = true
        }
        
        selectedCellIndex = indexPath
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}



extension PaymentView:  UITextFieldDelegate {
    
    //MARK: - Handling TextField
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        if let next = textField.viewWithTag(textField.tag + 1) {
            next.becomeFirstResponder()
        }
        return false
        
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        scrollView.scrollRectToVisible(textField.frame, animated: true)
    }
    
    
    //MARK: - Handling Card Replacements
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        previousTextFieldContent = textField.text;
        previousSelection = textField.selectedTextRange;
        return true
    }
    
    @objc func reformatAsCardNumber(textField: UITextField) {
        var targetCursorPosition = 0
        if let startPosition = textField.selectedTextRange?.start {
            targetCursorPosition = textField.offset(from: textField.beginningOfDocument, to: startPosition)
        }
        
        var cardNumberWithoutSpaces = ""
        if let text = textField.text {
            cardNumberWithoutSpaces = self.removeNonDigits(string: text, andPreserveCursorPosition: &targetCursorPosition)
        }
        
        if cardNumberWithoutSpaces.count > 19 {
            textField.text = previousTextFieldContent
            textField.selectedTextRange = previousSelection
            return
        }
        
        let cardNumberWithSpaces = self.insertCreditCardSpaces(cardNumberWithoutSpaces, preserveCursorPosition: &targetCursorPosition)
        textField.text = cardNumberWithSpaces
        
        if let targetPosition = textField.position(from: textField.beginningOfDocument, offset: targetCursorPosition) {
            textField.selectedTextRange = textField.textRange(from: targetPosition, to: targetPosition)
        }
        textField.undoManager?.removeAllActions()
    }
    
    func removeNonDigits(string: String, andPreserveCursorPosition cursorPosition: inout Int) -> String {
        var digitsOnlyString = ""
        let originalCursorPosition = cursorPosition
        
        for i in Swift.stride(from: 0, to: string.count, by: 1) {
            let characterToAdd = string[string.index(string.startIndex, offsetBy: i)]
            if characterToAdd >= "0" && characterToAdd <= "9" {
                digitsOnlyString.append(characterToAdd)
            }
            else if i < originalCursorPosition {
                cursorPosition -= 1
            }
        }
        
        return digitsOnlyString
    }
    
    func insertCreditCardSpaces(_ string: String, preserveCursorPosition cursorPosition: inout Int) -> String {
        
        var spacingFormat = ""
        
        switch CardState(fromPrefix: cardNumberField.text!.replacingOccurrences(of: " ", with: "", options:[], range: nil)) {
        case .identified(let cardType):
            spacingFormat = cardType.spacingFormat
        case .indeterminate, .invalid:
            spacingFormat = "4444"
        }
        
        var stringWithAddedSpaces = ""
        let cursorPositionInSpacelessString = cursorPosition
        
        for i in 0..<string.count {
            let needs465Spacing = (spacingFormat == "465" && (i == 4 || i == 10 || i == 15))
            let needs456Spacing = (spacingFormat == "456" && (i == 4 || i == 9 || i == 15))
            let needs4444Spacing = (spacingFormat == "4444" && i > 0 && (i % 4) == 0)
            
            if needs465Spacing || needs456Spacing || needs4444Spacing {
                stringWithAddedSpaces.append(" ")
                
                if i < cursorPositionInSpacelessString {
                    cursorPosition += 1
                }
            }
            
            let characterToAdd = string[string.index(string.startIndex, offsetBy:i)]
            stringWithAddedSpaces.append(characterToAdd)
        }
        
        return stringWithAddedSpaces
    }
}


//MARK: - The Custom Cell classes for the PaymentTableView
class CardCell: UITableViewCell {
    
    var card: Card? = nil
    
    @IBOutlet weak var cardNumberLabel: UILabel!
    @IBOutlet weak var cardTypeLabel: UILabel!
    @IBOutlet weak var cardTypeImage: UIImageView!
    
    @IBOutlet weak var cardExpLabel: UILabel!
    @IBOutlet weak var cardUnusableIcon: UIImageView!
    
}

class AddPaymentCell: UITableViewCell {
    @IBOutlet weak var label: UILabel!
    
}




//MARK: - Customer Picker View for Month/Year Selection
class MonthYearPickerView: UIPickerView, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var months: [String]!
    var years: [Int]!
    let maxRows = 500
    let actualRows = 12
    var visible = false
    
    var month = Calendar.current.component(.month, from: Date()) {
        didSet {
            selectRow(month-1, inComponent: 0, animated: false)
        }
    }
    
    var year = Calendar.current.component(.year, from: Date()) {
        didSet {
            selectRow(years.index(of: year)!, inComponent: 1, animated: true)
        }
    }
    
    var onDateSelected: ((_ month: Int, _ year: Int) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonSetup()
    }
    
    func commonSetup() {
        // population years
        var years: [Int] = []
        if years.count == 0 {
            var year = NSCalendar(identifier: NSCalendar.Identifier.gregorian)!.component(.year, from: NSDate() as Date)
            for _ in 1...15 {
                years.append(year)
                year += 1
            }
        }
        self.years = years
        
        // populate months with localized names
        var months: [String] = []
        var month = 0
        for _ in 1...12 {
            months.append(DateFormatter().monthSymbols[month].capitalized)
            month += 1
        }
        self.months = months
        
        self.delegate = self
        self.dataSource = self
        
        let currentMonth = NSCalendar(identifier: NSCalendar.Identifier.gregorian)!.component(.month, from: NSDate() as Date)
        self.selectRow(currentMonth - 1, inComponent: 0, animated: false)
        
    }
    
    // Mark: UIPicker Delegate / Data Source
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        switch component {
        case 0:
            let relativeRow = row % 12
            if visible { //currently never set to true, can't find a good way to do this to only run when the keyboard is showing
                // moves the wheel back again to the middle rows so the user can virtually loop in any direction
                let absoluteRow = relativeRow + ( (maxRows / (2 * actualRows) ) * actualRows )
                self.selectRow(absoluteRow, inComponent: component, animated: false)
            }
            return months[relativeRow]
        case 1:
            return "\(years[row])"
        default:
            return nil
        }
    
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    
        switch component {
        case 0:
            return maxRows
        case 1:
            return years.count
        default:
            return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let month = self.selectedRow(inComponent: 0)+1
        let year = years[self.selectedRow(inComponent: 1)]
        
        self.month = month
        self.year = year
    }
    
}
