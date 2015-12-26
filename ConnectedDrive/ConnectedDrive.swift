//
//  ConnectedDrive.swift
//  i3Trip
//
//  Created by Ronald Mannak on 12/17/15.
//  Copyright © 2015 Ronald Mannak. All rights reserved.
//

import Foundation
import Alamofire

// Replace protocol with NSErrors?
public protocol ConnectedDriveDelegate: class {
    
    /**
     ConnectedDrive started fetching data from the server
     */
    func startedFetchingData()
    
    /**
     ConnectedDrive finshed fetching data from the server
     */
    func finshedFetchingData()
    
    /**
     ConnectedDrive is not logged in and no (valid) username and password. App needs to present the login window
     */
    func shouldPresentLoginWindow()
    
    /**
     Invoked when login was successful
     */
    func didLogin()
    
    /**
     Invoked when user logged out (could be in case server didn't accept access token)
     */
    func didLogout()
}

public class ConnectedDrive {
    
    public enum State {
        case LoggedOut
        case LoggingIn
        case LoggedIn
    }
    
    public weak var delegate: ConnectedDriveDelegate?
    
    private var credentials: Credentials?

    /// Stores and fetches username from the keychain
    private var username: String? {
        get {
            return Keychain.load("Username")?.stringValue
            // store in keychain
        }
        set {
            
            let key = "Username"
            guard let newValue = newValue else {
                Keychain.delete(key)
                return
            }
            
            Keychain.save(key, data: newValue.dataValue)
        }
    }
    
    /// Stores and fetches password from the keychain
    private var password: String? {
        get {
            return Keychain.load("Password")?.stringValue
            // store in keychain
        }
        set {
            
            let key = "Password"
            guard let newValue = newValue else {
                Keychain.delete(key)
                return
            }
            
            Keychain.save(key, data: newValue.dataValue)
        }
    }
    
    // Do we need this? Would be cleaner if we got rid of this
    /// Fetches and saves last used hub for use in autologin
    private var lastUsedHub: BMWHub? {
        get {
            guard let hub = NSUserDefaults.standardUserDefaults().stringForKey("LastUsedHub") else { return nil }
            return BMWHub(rawValue: hub)
        }
        set {
            NSUserDefaults.standardUserDefaults().setObject(newValue?.rawValue, forKey: "LastUsedHub")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    private var isLoggedin: Bool {
        return credentials != nil && username != nil && password != nil
    }
    
    public var state: State = .LoggedOut
    
    private static let notLoggedInError = VehicleError.errorWithCode(.NotLoggedIn, failureReason: "Not logged in")
    
}

/*
 *  Login
 */

extension ConnectedDrive {
    
    public func login(username: String, password: String, completion:(Result<Credentials, NSError>) -> Void) {
        
        // Log out so no server calls can be made while logging in is in progress
        logout()
        state = .LoggingIn
        
        let hub = lastUsedHub ?? BMWHub.Europe // Europe is the default server
        
        Alamofire.request(Router.Login(username: username, password: password, hub: hub)).responseObject { (response: Response<Tokens, NSError>) in
            
            switch response.result {
            case .Success(let tokens):
                
                let credentials = Credentials(hub: hub, tokens: tokens)
                self.credentials    = credentials
                self.username       = username
                self.password       = password
                self.delegate?.didLogin()
                
                self.state = .LoggedIn
                completion(Result.Success(credentials))
                
            case .Failure(let error):
                print("login failed: \(error)")
                self.state = .LoggedOut
                completion(Result.Failure(error))
            }
        }
    }
    
    public func autoLogin(hub: BMWHub? = nil, completion:(Result<Credentials, NSError>) -> Void) {
        
        guard let password = password, username = username, hub = hub ?? lastUsedHub else {
            delegate?.shouldPresentLoginWindow()
            let error = VehicleError.errorWithCode(.NoUsernamePasswordStored, failureReason: "Autologin failed")
            completion(Result.Failure(error))
            return
        }
        lastUsedHub = hub
        login(username, password: password, completion: completion)
    }
    
    public func logout(deleteStoredPassword: Bool = false) {
        
        if deleteStoredPassword {
            username = nil
            password = nil
        }
        credentials = nil
        state = .LoggedOut
        
        delegate?.didLogout()
    }
}

/*
 *  Vehicles
 */

extension ConnectedDrive {
    
    public typealias ConfineServer = (credentials: Credentials?) -> Void
    
    /**
     Fetches list of vehicles from server. All geographically different BMW servers return the same vehicle list.
     
     - parameter completion: Invoked when server returns data. Result is either Result.Success([Vehicle]) or Result.Failure(NSError)
     */
    
    public func vehicles(completion: (Result<[Vehicle], NSError>) -> Void) {
        
        guard let credentials = credentials else {
            completion(Result.Failure(ConnectedDrive.notLoggedInError))
            return
        }
        
        Alamofire.request(Router.Vehicles(login: credentials)).validate().responseCollection("vehicles"){ (response: Response<[Vehicle], NSError>) -> Void in
            
            switch response.result {
            case .Success(let vehicles):
                
                guard vehicles.count > 0 else {
                    completion(Result.Failure(VehicleError.errorWithCode(.VehicleNotFound, failureReason: "No vehicles found")))
                    return
                }
                completion(Result.Success(vehicles))
                
            case .Failure(let error):
                
                completion(Result.Failure(error))
            }
        }
    }
    
    /**
     Fetches vehicle status from server. If the vehicle is stored on a different server than currently logged in to, this method will automatically login to the correct server. In that case, the router will stay logged in to the old server until login is completed.
     
     - parameter vehicle:    Vehicle
     - parameter completion: Invoked when server returns data. Result is either Result.Success(VehicleStatus) or Result.Failure(NSError)
     */
    public func vehicleStatus(vehicle: Vehicle, completion: (Result<VehicleStatus, NSError>) -> Void) {
        
        let vehicleStatus: ConfineServer = { credentials in
            
            guard let credentials = credentials else {
                completion(Result.Failure(ConnectedDrive.notLoggedInError))
                return
            }
            
            Alamofire.request(Router.VehicleStatus(VIN: vehicle.VIN, login: credentials)).responseObject { (response: Response<VehicleStatus, NSError>) in
                
                completion(response.result)
            }
        }
        
        confineServer(vehicle.hub, completion: vehicleStatus)
    }
    
    
    public func rangeMap(vehicle: Vehicle, completion: (Result<RangeMap, NSError>) -> Void) {
        
        let rangeMap: ConfineServer = { credentials in
            
            guard let credentials = credentials else {
                completion(Result.Failure(ConnectedDrive.notLoggedInError))
                return
            }
            
            Alamofire.request(Router.RangeMap(VIN: vehicle.VIN, login: credentials)).responseObject { (response: Response<RangeMap, NSError>) in
                
                completion(response.result)
            }
        }
        
        confineServer(vehicle.hub, completion: rangeMap)
    }
    
    /**
     This method makes sure the app is logged in to the right geographic server. Logs into a different server if necessary
     Invoke this method for server calls that are server specific (e.g. vehicle status)
     
     - parameter completion: invoked when switch was completed or no switch was necessary
     */
    private func confineServer(hub: BMWHub, completion: (credentials: Credentials?) -> Void) {
        
        guard let credentials = credentials where hub.rawValue == credentials.hub.rawValue else {
            
            autoLogin(hub) { credentials in
                switch credentials {
                case .Failure(_):
                    completion(credentials: nil)
                    self.delegate?.shouldPresentLoginWindow()
                case .Success(let credentials):
                    completion(credentials: credentials)
                }
            }
            return
        }
        completion(credentials: self.credentials)
    }
    
    
    /**
     For debug purposes
     */
    public func deleteStoredItems() {
        Keychain.delete("username")
        Keychain.delete("password")
        NSUserDefaults.standardUserDefaults().setObject(nil, forKey: "LastUsedHub")
    }
}