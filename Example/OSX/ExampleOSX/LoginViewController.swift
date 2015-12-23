//
//  LoginViewController.swift
//  i3Trip
//
//  Created by Ronald Mannak on 12/13/15.
//  Copyright © 2015 Ronald Mannak. All rights reserved.
//

import Cocoa

protocol LoginDelegate: class {
    
    func userProvidedUsername(username: String, password: String)
}

class LoginViewController: NSViewController {

    @IBOutlet weak var usernameField: NSTextField!
    @IBOutlet weak var passwordField: NSSecureTextField!
    
    unowned let delegate: LoginDelegate
    
    init?(delegate: LoginDelegate) {
        self.delegate = delegate
        super.init(nibName: "LoginViewController", bundle:  nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBAction func login(sender: AnyObject) {
        
        guard usernameField.stringValue.characters.count > 0 && passwordField.stringValue.characters.count > 0 else { return }
        
        delegate.userProvidedUsername(usernameField.stringValue, password: passwordField.stringValue)
    }
    
    
}
