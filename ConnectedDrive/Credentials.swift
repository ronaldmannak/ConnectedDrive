//
//  Credentials.swift
//  i3Trip
//
//  Created by Ronald Mannak on 12/22/15.
//  Copyright © 2015 Ronald Mannak. All rights reserved.
//

import Foundation
import Decodable

/**
 *  Wrapper for tokens and hub
 */
public struct Credentials {
    let hub: BMWHub
    let tokens: Tokens
}

/**
 *  accessToken and refreshToken
 */
struct Tokens {
    let accessToken: String
    let refreshToken: String
}

extension Tokens: Decodable {
 
    static func decode(json: AnyObject) throws -> Tokens {
        
        return Tokens(accessToken: try json => "access_token", refreshToken: try json => "refresh_token")
    }
}