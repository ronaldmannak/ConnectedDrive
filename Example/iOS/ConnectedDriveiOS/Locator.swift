//
//  Locator.swift
//  ConnectedDriveiOS
//
//  Created by Ronald Mannak on 12/26/15.
//  Copyright © 2015 Ronald Mannak. All rights reserved.
//

import Foundation
import ConnectedDrive

class Locator {
    private (set) var connectedDrive: ConnectedDrive
    
    class var connectedDrive: ConnectedDrive {
        return Locator.sharedInstance.connectedDrive
    }
    
    class var sharedInstance :Locator {
        struct Singleton {
            static let instance = Locator()
        }
        return Singleton.instance
    }
    
    init() {        
         connectedDrive = ConnectedDrive()
    }
}