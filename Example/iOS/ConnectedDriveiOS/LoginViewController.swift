//
//  LoginViewController.swift
//  ConnectedDriveiOS
//
//  Created by Ronald Mannak on 12/26/15.
//  Copyright © 2015 Ronald Mannak. All rights reserved.
//

import UIKit
import ConnectedDrive

class LoginViewController: UIViewController {

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func login(sender: AnyObject) {
        
        guard let username = usernameTextField.text, password = passwordTextField.text where username.characters.count > 0 && password.characters.count > 0 else {
            return
        }
        
        Locator.connectedDrive.login(username, password: password) { result in
            // AppDelegate will handle segue to main viewController
        }
    }
}
