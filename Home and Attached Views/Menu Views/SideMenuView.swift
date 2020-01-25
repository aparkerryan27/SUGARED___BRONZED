//
//  SideMenuView.swift
//  SUGARED + BRONZED
//
//  Created by Parker Ryan on 7/20/18.
//  Copyright © 2018 SUGARED + BRONZED. All rights reserved.
//

import Foundation
import MessageUI
import SafariServices

class SideMenuView: UIViewController {
    

    var sideMenuItems = ["HEADER", "REFER A FRIEND", "LEAVE A REVIEW", "FAQ", "PURCHASE MEMBERSHIP"]
    var rowHeight: CGFloat = 70.0
    var headerHeight: CGFloat = 170.0

    @IBOutlet weak var sideMenuTableView: UITableView!
    
    @IBOutlet weak var sideMenuTableViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var logoutButton: UIButton!
    @IBAction func logout(_ sender: Any) {
        
        let alert = UIAlertController(title: "are you sure?", message: "you'll have to log back in again to book or view your appointments on the app", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "yes, log out", style: .default, handler: {
            UIAlertAction in self.logout()
        }))
        alert.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sideMenuTableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .white
        
        sideMenuTableView.separatorStyle = .singleLine
        sideMenuTableView.delegate = self
        sideMenuTableView.dataSource = self
        
        sideMenuTableViewHeight.constant = headerHeight +  (CGFloat(sideMenuItems.count - 1) * rowHeight) - 2 //adjusts for the row size minus the bottom edge
   
    }
    
    //MARK: - The Logout Flow
    @objc func logout() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        CustomerAPI().logout { (success, error) in
            DispatchQueue.main.async { UIApplication.shared.isNetworkActivityIndicatorVisible = false }
            guard success else {
                print("failed to log out")
                let alert = UIAlertController(title: "uh oh", message: "logout failed, please try again later", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                DispatchQueue.main.async {  self.present(alert, animated: true, completion: nil) }
                return
            }
        }
        
        UserDefaults.standard.set(nil, forKey: "email")
        if let view = self.presentingViewController?.presentingViewController {
            view.dismiss(animated: false)
        } else if let view = self.presentingViewController {
            view.dismiss(animated: true)
        } else {
            let alert = UIAlertController(title: "uh oh", message: "logout failed, please try again later", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            
            DispatchQueue.main.async {  self.present(alert, animated: true, completion: nil) }
        }
    }
}

//MARK: - Configuring Cell Data
extension SideMenuView: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sideMenuItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row == 0 { //HEADER
            let headerCell = tableView.dequeueReusableCell(withIdentifier: "menuHeaderCell") as! MenuHeaderCell
            headerCell.backgroundColor = Design.Colors.brown
            headerCell.nameLabel!.textColor = .white
            headerCell.nameLabel!.text = Customer.firstName.uppercased()
            headerCell.editLabel!.textColor = .white
            headerCell.editLabel!.text = "EDIT MY PROFILE"
            
            return headerCell
            
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "menuItemCell") as! MenuItemCell
            cell.itemLabel.text = sideMenuItems[indexPath.row]
            return cell
        }
    }
}

//MARK: - Configuring Cell Selection and Headers/Footers
extension SideMenuView: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return headerHeight
        } else {
            return rowHeight
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.row == 0 { //HEADER
            if let svc = storyboard?.instantiateViewController(withIdentifier: "profileController") {
                present(svc, animated: true)
            } else {
                print("storyboard error!")
            }
            
            /*
             -- WEB VERSION --
             let url = URL(string: "https://go.booker.com/location/SBBeverlyHills/account/profile")!
             let svc = SFSafariViewController(url: url)
             present(svc, animated: true, completion: nil)
             -- IN APP VERSION --
             if let svc = storyboard?.instantiateViewController(withIdentifier: "profileController") {
                present(svc, animated: true)
             } else {
                print("storyboard error!")
             }
             */
            
        } else if indexPath.row == 1  { //REFER A FRIEND
            if (MFMessageComposeViewController.canSendText()) {
                let controller = MFMessageComposeViewController()
                controller.body = "Book an appointment on the SUGARED + BRONZED app and we'll both get something sweet! You'll get a new client special and I'll get a $10 referral credit. Make sure you mention my name upon check-in! \nhttps://www.sugaredandbronzed.com"
                controller.messageComposeDelegate = self
                self.present(controller, animated: false, completion: nil)
            } else {
                let alert = UIAlertController(title: "bummer!", message: "it looks like your device is ineligble to send text messages, please try again later", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                present(alert, animated: true, completion: nil)
            }
            
        }  else if indexPath.row == 2 { //LEAVE A REVIEW
            let url = URL(string: "https://www.yelp.com/biz/sugared-bronzed-new-york-3")!
            let svc = SFSafariViewController(url: url)
            present(svc, animated: true, completion: nil)
            
        } else  if indexPath.row == 3 { // FAQ
            let url = URL(string: "https://sugaredandbronzed.com/faqs/")!
            let svc = SFSafariViewController(url: url)
            present(svc, animated: true, completion: nil)
            
        } else if indexPath.row == 4 { //MEMBERSHIPS
            
            let DISABLE_MEMBERSHIPS = true
            guard !DISABLE_MEMBERSHIPS else {
                let alert = UIAlertController(title: "sorry!", message: "membership purchasing isn't available yet through the app, stay tuned!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
             
            if let svc = storyboard?.instantiateViewController(withIdentifier: "membershipsController") {
                present(svc, animated: true)
            } else {
                print("storyboard error!")
            }
        }
        
        sideMenuTableView.deselectRow(at: indexPath, animated: true)
    }

}

//MARK: - Configuring the REFER A FRIEND Texting
extension SideMenuView: MFMessageComposeViewControllerDelegate {
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        self.dismiss(animated: true, completion: nil)
        if result == .sent {
            let alert = UIAlertController(title: "congrats!", message: "you've successfully sent a referral text! once they book an appointment and mention your name at the front desk, you'll recieve a $10 credit as thank you from S+B!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
        
    }
    
}
class MenuItemCell: UITableViewCell {
    @IBOutlet weak var itemLabel: UILabel!
}

class MenuHeaderCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var editLabel: UILabel!
}
