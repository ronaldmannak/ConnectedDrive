//
//  ConnectedDrive.swift
//  i3Trip
//
//  Created by Ronald Mannak on 12/17/15.
//  Copyright © 2015 Ronald Mannak. All rights reserved.
//

import Foundation
import Alamofire

/// Protocol to inform delegate about login/logout events and fetching data events
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

/// Main class to access ConnectedDrive servers through
public class ConnectedDrive {
    
    /**
     ConnectedDrive states
     
     - LoggedOut: User is logged out
     - LoggingIn: User is logging in
     - LoggedIn:  User is successfully logged in
     */
    public enum State {
        case loggedOut
        case loggingIn
        case loggedIn
    }
    
    public init() {}
    
    /// ConnectedDriveDelegate
    public weak var delegate: ConnectedDriveDelegate?
    
    /// credentials includes tokens and currently used BMWHub
    private var credentials: Credentials?

    /// Stores and fetches username in and from the keychain
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
    
    /// Stores and fetches password in and from the keychain
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

    /// last used BMWHub stored in and fetched from the standard user defaults
    private var lastUsedHub: BMWHub? {
        get {
            guard let hub = UserDefaults.standard.string(forKey: "LastUsedHub") else { return nil }
            return BMWHub(rawValue: hub)
        }
        set {
            UserDefaults.standard.set(newValue?.rawValue, forKey: "LastUsedHub")
            UserDefaults.standard.synchronize()
        }
    }
    
    private var isLoggedin: Bool {
        return credentials != nil && username != nil && password != nil
    }
    
    public var state: State = .loggedOut
        
    private func isNotAuthenticatedError(_ error: NSError) -> Bool {
        return error.domain == Error.Domain && error.code == Error.Code.statusCodeValidationFailed.rawValue && error.localizedDescription.range(of: "401") != nil
    }
}

/*
 *  Login
 */

extension ConnectedDrive {
    
    /**
     Logs into the last used hub as stored in user defaults or the default hub (Europe) if no last used hub is stored
     
     - parameter username:   ConnectedDrive username
     - parameter password:   ConnectedDrive password
     - parameter completion: Passes Result.Failure(NSError) or Result.Success(Credentials)
     */
    public func login(_ username: String, password: String, completion:(Result<Credentials, NSError>) -> Void) {
        
        if state == .loggingIn {
            // TODO: can we and return credentials when state changes to logged in?
        }
        
        // Log out so no server calls can be made while logging in is in progress
        logout()
        state = .loggingIn
        
        let hub = lastUsedHub ?? BMWHub.Europe // Europe is the default server
        
        Alamofire.request(Router.login(username: username, password: password, hub: hub)).validate().responseObject { (response: Response<Tokens, NSError>) in
            
            switch response.result {
            case .success(let tokens):
                
                let credentials     = Credentials(hub: hub, tokens: tokens)
                self.credentials    = credentials
                self.username       = username
                self.password       = password
                self.state          = .loggedIn

                self.delegate?.didLogin()
                completion(Result.success(credentials))
                
            case .failure(let error):
                print("login failed: \(error)")
                self.state = .loggedOut
                completion(Result.failure(error))
            }
        }
    }
    
    /**
     Tries to log in user based on username and password stored in the keychain.
     
     - parameter hub:        Optionally specify hub to log in
     - parameter completion: Passes `.NoUsernamePasswordStored` NSError in case no username and password were stored and will call `delegate?.shouldPresentLoginWindow()`. Will pass Credentials if auto login was successful.
     */
    public func autoLogin(_ hub: BMWHub? = nil, completion:(Result<Credentials, NSError>) -> Void) {
        
        guard let password = password, username = username, hub = hub ?? lastUsedHub else {
            delegate?.shouldPresentLoginWindow()
            let error = VehicleError.noUsernamePasswordStored.error()
            completion(Result.failure(error))
            return
        }
        lastUsedHub = hub
        login(username, password: password, completion: completion)
    }
    
    /**
     Logs user out.
     
     - parameter deleteStoredPassword: if true, username and password are permanently deleted from the keychain. 
     Usually this should be set to true only if a user explicitly selects 'logout' from the app.
     */
    public func logout(_ deleteStoredPassword: Bool = false) {
        
        if deleteStoredPassword {
            username = nil
            password = nil
        }
        credentials = nil
        state = .loggedOut
        
        delegate?.didLogout()
    }
    
    /**
     Refreshes access token
     
     - parameter completion: Passes credentials if successful, an error generated by autoLogin if not
     */
    func refreshAccessToken(_ completion:(Result<Credentials, NSError>) -> Void) {
        
        state = .loggingIn
        guard let credentials = credentials else {
            autoLogin(completion: completion)
            return
        }
        
        Alamofire.request(Router.refreshToken(login: credentials)).validate().responseObject { (response: Response<Tokens, NSError>) in
            
            switch response.result {
            case .success(let tokens):
                
                let updatedCredentials  = Credentials(hub: credentials.hub, tokens: tokens)
                self.credentials        = updatedCredentials
                self.state              = .loggedIn
                
                completion(Result.success(credentials))
                
            case .failure(let error):
                print("refresh token failed: \(error)")
                self.state = .loggedOut
                completion(Result.failure(error))
            }
        }
    }
    
    /**
     For debug purposes only. Deletes username and password from keychain and last used hub from user defaults.
     */
    public func deleteStoredItems() {
        Keychain.delete("username")
        Keychain.delete("password")
        UserDefaults.standard.set(nil, forKey: "LastUsedHub")
    }
}

/*
 *  Vehicles
 */

extension ConnectedDrive {
    
    /// Typealias for (Credentials?) -> Void closure for use with confineServer(hub:completion:)
    private typealias ConfineServer = (credentials: Credentials?) -> Void
    
    /**
     Fetches list of vehicles from server. All geographically different BMW servers return the same vehicle list.
     
     - parameter completion: Invoked when server returns data. Result is either `Result.Success([Vehicle])` or `Result.Failure(NSError)`
     - parameter retryCount: For internal use only
     */
    public func vehicles(_ retryCount: Int = 0, completion: (Result<[Vehicle], NSError>) -> Void) {
        
        guard let credentials = credentials else {
            completion(Result.failure(VehicleError.notLoggedIn.error()))
            return
        }
        
        Alamofire.request(Router.vehicles(login: credentials)).validate().responseCollection("vehicles"){ (response: Response<[Vehicle], NSError>) -> Void in
            
            switch response.result {
            case .success(let vehicles):
                
                guard vehicles.count > 0 else {
                    completion(Result.failure(VehicleError.vehicleNotFound.error()))
                    return
                }
                completion(Result.success(vehicles))
                
            case .failure(let error):
            
                let tokenDidExpire = self.isNotAuthenticatedError(error)
                if tokenDidExpire && retryCount < 3 {
                    DispatchQueue.main.after(when: .now() + (self.state == .loggingIn ? 3 : 0)) {
                        self.refreshAccessToken { result in

                            self.vehicles(retryCount + 1, completion: completion)
                        }
                    }
                } else {
                    completion(Result.failure(error))
                }
            }
        }
    }
    
    /**
     Fetches vehicle status from server. If the vehicle is stored on a different server than currently logged in to, this method will automatically login to the correct server. In that case, the router will stay logged in to the old server until login is completed.
     
     - parameter vehicle:    Vehicle
     - parameter completion: Invoked when server returns data. Result is either `Result.Success(VehicleStatus)` or `Result.Failure(NSError)`
     */
    public func vehicleStatus(_ vehicle: Vehicle, retryCount: Int = 0, completion: (Result<VehicleStatus, NSError>) -> Void) {
        
        let vehicleStatus: ConfineServer = { credentials in
            
            guard let credentials = credentials else {
                completion(Result.failure(VehicleError.notLoggedIn.error()))
                return
            }
            
            Alamofire.request(Router.vehicleStatus(VIN: vehicle.VIN, login: credentials)).validate().responseObject { (response: Response<VehicleStatus, NSError>) in
                
                switch response.result {
                case .success(_):
                    completion(response.result)
                    
                case .failure(let error):
                    let tokenDidExpire = self.isNotAuthenticatedError(error)
                    if tokenDidExpire && retryCount < 3 {
                        DispatchQueue.main.after(when: .now() + (self.state == .loggingIn ? 4 : 0)) {
                            self.refreshAccessToken { result in
                                self.vehicleStatus(vehicle, retryCount: retryCount + 1, completion: completion)
                            }
                        }
                    } else {
                        completion(Result.failure(error))
                    }
                }
            }
        }
        
        confineServer(vehicle.hub, completion: vehicleStatus)
    }
    
    
    /**
     Fetches polygons that visualise the current range in Comfort and Eco Pro Plus mode.
     
     - parameter vehicle:    Vehicle
     - parameter completion: Invoked when server returns data. Result is `Result.Success(RangeMap)` in case of success
        or `Result.Failure(NSError)` in case of failure.
     */
    public func rangeMap(_ vehicle: Vehicle, completion: (Result<RangeMap, NSError>) -> Void) {
        
        let rangeMap: ConfineServer = { credentials in
            
            guard let credentials = credentials else {
                completion(Result.failure(VehicleError.notLoggedIn.error()))
                return
            }
            
            Alamofire.request(Router.rangeMap(VIN: vehicle.VIN, login: credentials)).responseObject { (response: Response<RangeMap, NSError>) in
                
                completion(response.result)
            }
        }
        
        confineServer(vehicle.hub, completion: rangeMap)
    }
    
    /**
     This method makes sure the app is logged in to the right geographic server. Logs into a different server if necessary.
     Invoke this method for server calls that are server specific (e.g. vehicle status)
     
     - parameter completion: invoked when switch was completed or no switch was necessary
     */
    private func confineServer(_ hub: BMWHub, completion: (credentials: Credentials?) -> Void) {
        
        guard let credentials = credentials where hub.rawValue == credentials.hub.rawValue else {
            
            autoLogin(hub) { credentials in
                switch credentials {
                case .failure(_):
                    completion(credentials: nil)
                    self.delegate?.shouldPresentLoginWindow()
                case .success(let credentials):
                    completion(credentials: credentials)
                }
            }
            return
        }
        completion(credentials: self.credentials)
    }
}

/*
 *  Execute commands
 */
extension ConnectedDrive {
    
    public func executeCommand(_ vehicle: Vehicle, service: VehicleService, completion: (Result<ExecutionStatus, NSError>) -> Void) {
        let command: ConfineServer = { credentials in
            
            guard let credentials = credentials else {
                completion(Result.failure(VehicleError.notLoggedIn.error()))
                return
            }
            
            Alamofire.request(Router.executeService(VIN: vehicle.VIN, service: service, login: credentials)).validate().responseObject { (response: Response<ExecutionStatus, NSError>) in
                completion(response.result)
            }
        }
        confineServer(vehicle.hub, completion: command)
    }
    
    public func CommandStatus(_ vehicle: Vehicle, service: VehicleService, completion: (Result<ExecutionStatus, NSError>) -> Void) {
        let status: ConfineServer = { credentials in
            
            guard let credentials = credentials else {
                completion(Result.failure(VehicleError.notLoggedIn.error()))
                return
            }
            
            Alamofire.request(Router.serviceStatus(VIN: vehicle.VIN, service: service, login: credentials)).validate().responseObject { (response: Response<ExecutionStatus, NSError>) in
                completion(response.result)
            }
        }
        confineServer(vehicle.hub, completion: status)
    }
}
