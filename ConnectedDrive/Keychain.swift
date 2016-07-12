//
//  Keychain.swift
//  i3Trip
//
//  Created by Ronald Mannak on 12/15/15.
//  Copyright © 2015 Ronald Mannak. All rights reserved.
//
// Source: https://gist.github.com/jackreichert/414623731241c95f0e20

import Foundation
import Security

class Keychain {
    
    class func save(_ key: String, data: Data) -> Bool {
        let query = [
            kSecClass as String       : kSecClassGenericPassword as String,
            kSecAttrAccount as String : key,
            kSecValueData as String   : data ]
        
        SecItemDelete(query as CFDictionary)
        
        let status: OSStatus = SecItemAdd(query as CFDictionary, nil)
        
        return status == noErr
    }
    
    class func load(_ key: String) -> Data? {
        let query = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : key,
            kSecReturnData as String  : kCFBooleanTrue,
            kSecMatchLimit as String  : kSecMatchLimitOne ]
        
        var dataTypeRef: AnyObject?
        let status = withUnsafeMutablePointer(&dataTypeRef) { SecItemCopyMatching(query, UnsafeMutablePointer($0)) }
        
        if status == errSecSuccess {
            if let data = dataTypeRef as! Data? {
                return data
            }
        }
        return nil
    }
    
    class func delete(_ key: String) -> Bool {
        let query = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : key ]
        
        let status: OSStatus = SecItemDelete(query as CFDictionary)
        
        return status == noErr
    }
    
    
    class func clear() -> Bool {
        let query = [ kSecClass as String : kSecClassGenericPassword ]
        
        let status: OSStatus = SecItemDelete(query as CFDictionary)
        
        return status == noErr
    }
}

extension String {
    public var dataValue: Data {
        return data(using: String.Encoding.utf8, allowLossyConversion: false)!
    }
}

extension Data {
    public var stringValue: String {
        return NSString(data: self, encoding: String.Encoding.utf8.rawValue) as! String
    }
}
