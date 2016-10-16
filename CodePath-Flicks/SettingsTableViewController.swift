//
//  SettingsTableViewController.swift
//  CodePath-Flicks
//
//  Created by Ernest on 10/15/16.
//  Copyright © 2016 Purpleblue Pty Ltd. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {
    
    @IBOutlet weak var viewTypeSegmentControl: UISegmentedControl!
    
    let defaults = UserDefaults.standard

    override func viewDidLoad() {
        super.viewDidLoad()

        let titleLabel = UILabel()
        let titleText = NSAttributedString(string: "Settings", attributes: [
            NSFontAttributeName : UIFont(name: "OpenSans", size: 18)!,
            NSForegroundColorAttributeName : UIColor.darkText
            ])
        
        titleLabel.attributedText = titleText
        titleLabel.sizeToFit()
        navigationItem.titleView = titleLabel
        
        loadSettings()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        // Remove the separator inset
        // Ref: https://guides.codepath.com/ios/Table-View-Guide#how-do-you-remove-the-separator-inset
        tableView.separatorInset = UIEdgeInsets.zero
        
        // A little trick for removing the cell separators
        tableView.tableFooterView = UIView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Settings changes

    func loadSettings() {
        if (defaults.object(forKey: "flicks_view_type") != nil) {
            viewTypeSegmentControl.selectedSegmentIndex = (defaults.object(forKey: "flicks_view_type") as? Int!)!
        }
    }
    
    @IBAction func viewTypeSegmentedControlAction(sender: AnyObject) {
        defaults.set(viewTypeSegmentControl.selectedSegmentIndex, forKey: "flicks_view_type")
        defaults.synchronize()
        
        // Let's update the views with a new view type
        NotificationCenter.default.post(name: Notification.Name(rawValue: "com.purpleblue.CodePath-Flicks.loadViewType"), object: self)
    }
}
