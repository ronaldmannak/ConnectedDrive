//
//  VehicleErrors.swift
//  i3Trip
//
//  Created by Ronald Mannak on 12/15/15.
//  Copyright © 2015 Ronald Mannak. All rights reserved.
//
//  Based on Alamofire Error struct

import Foundation

public struct VehicleError {

    /// The domain used for creating all iRemote errors.
    public static let Domain = "com.connecteddrive.error"
    
    /// The custom error codes generated by iRemote.
    public enum Code: Int {
        case authenticationFailed               = -8000
        case notLoggedIn                        = -8001
        case noUsernamePasswordStored           = -8002
        case vehicleNotFound                    = -8003
    }
    
    /**
     Creates an `NSError` with the given error code and failure reason.
     
     - parameter code:          The error code.
     - parameter failureReason: The failure reason.
     
     - returns: An `NSError` with the given error code and failure reason.
     */
    public static func error(code: Code, failureReason: String) -> NSError {
        return error(code: code.rawValue, failureReason: failureReason)
    }
    
    /**
     Creates an `NSError` with the given error code and failure reason.
     
     - parameter code:          The error code.
     - parameter failureReason: The failure reason.
     
     - returns: An `NSError` with the given error code and failure reason.
     */
    public static func error(code: Int, failureReason: String) -> NSError {
        let userInfo = [NSLocalizedFailureReasonErrorKey: failureReason]
        return NSError(domain: Domain, code: code, userInfo: userInfo)
    }
}

