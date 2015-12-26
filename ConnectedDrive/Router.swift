//
//  Router.swift
//  i3Trip
//
//  Created by Ronald Mannak on 12/10/15.
//  Copyright © 2015 Ronald Mannak. All rights reserved.
//

import Foundation
import Alamofire

/// Alamofire router enum. Because requests can be made to any of the three hubs (servers), Router does not store server addresses or tokens. Those need to be passed to Router with each call.
public enum Router: URLRequestConvertible {
    
    static var APIKey: String {
        guard let info = NSBundle.mainBundle().infoDictionary, APIKey = info["APIKey"] as? String else {
            fatalError("No API key in info.plist found. Store Base64 encoded API key (looks similar to: a2V5OnNlY3JldA==). See also https://github.com/quentinsf/BMW-i-Remote")
        }
        return APIKey
    }
    
    case Login(username: String, password: String, hub: BMWHub)
    case Vehicles(login: Credentials)
    case VehicleStatus(VIN: String, login: Credentials)
    case LastTrip(VIN: String, login: Credentials)
    case AllTrips(VIN: String, login: Credentials)
    case ChargingTimes(VIN: String, login: Credentials)
    case VehicleDestinations(VIN: String, login: Credentials)
    case RangeMap(VIN: String, login: Credentials)
    case RequestStatus(VIN: String, service: VehicleService, login: Credentials)
    case ExecuteService(VIN: String, service: VehicleService, login: Credentials)
    case ChargingStations(login: Credentials)

    private var method: Alamofire.Method {
        switch self {
        case .Login(_,_,_), .ExecuteService(_,_,_):
            return .POST
        default:
            return .GET
        }
    }
    
    private var accessToken: String {
        switch self {
        case Login(_, _, _):
            return ""
        case .Vehicles(let credentials):
            return credentials.tokens.accessToken
        case .VehicleStatus(_, let credentials):
            return credentials.tokens.accessToken
        case .LastTrip(_, let credentials):
            return credentials.tokens.accessToken
        case .AllTrips(_ , let credentials):
            return credentials.tokens.accessToken
        case .ChargingTimes(_, let credentials):
            return credentials.tokens.accessToken
        case .VehicleDestinations(_, let credentials):
            return credentials.tokens.accessToken
        case .RangeMap(_, let credentials):
            return credentials.tokens.accessToken
        case .RequestStatus(_, _, let credentials):
            return credentials.tokens.accessToken
        case .ExecuteService(_, _, let credentials):
            return credentials.tokens.accessToken
        case .ChargingStations(let credentials):
            return credentials.tokens.accessToken
        }
    }
    
    private var baseURLString: String {
        switch self {
        case .Login(_, _, let hub):
            return hub.baseURLString
        case .Vehicles(let credentials):
            return credentials.hub.baseURLString
        case .VehicleStatus(_, let credentials):
            return credentials.hub.baseURLString
        case .LastTrip(_, let credentials):
            return credentials.hub.baseURLString
        case .AllTrips(_ , let credentials):
            return credentials.hub.baseURLString
        case .ChargingTimes(_, let credentials):
            return credentials.hub.baseURLString
        case .VehicleDestinations(_, let credentials):
            return credentials.hub.baseURLString
        case .RangeMap(_, let credentials):
            return credentials.hub.baseURLString
        case .RequestStatus(_, _, let credentials):
            return credentials.hub.baseURLString
        case .ExecuteService(_, _, let credentials):
            return credentials.hub.baseURLString
        case .ChargingStations(let credentials):
            return credentials.hub.baseURLString
        }
    }
    
    private var path: String {
        switch self {
        case .Login(_,_,_):
            return "webapi/oauth/token/"
        case .Vehicles(_):
            return "/webapi/v1/user/vehicles/"
        case .VehicleStatus(let VIN, _):
            return "/webapi/v1/user/vehicles/\(VIN)/status"
        case .LastTrip(let VIN, _):
            return "/webapi/v1/user/vehicles/\(VIN)/statistics/lastTrip"
        case .AllTrips(let VIN, _):
            return "/webapi/v1/user/vehicles/\(VIN)/statistics/allTrips"
        case .ChargingTimes(let VIN, _):
            return "/webapi/v1/user/vehicles/\(VIN)/chargingprofile"
        case .VehicleDestinations(let VIN, _):
            return "/webapi/v1/user/vehicles/\(VIN)/destinations"
        case .RangeMap(let VIN, _):
            return "/webapi/v1/user/vehicles/\(VIN)/rangemap"
        case .RequestStatus(let VIN, let service, _):
            return "/webapi/v1/user/vehicles/\(VIN)/serviceExecutionStatus?serviceType=\(service.rawValue)" // TODO: parameter in dict?
        case .ExecuteService(let VIN, _, _):
            return "/webapi/v1/user/vehicles/\(VIN)/executeService"
        case .ChargingStations(_):
            return "webapi/v1/chargingstations/dynamicdata"
        }
    }
    
    private var parameters: [String : AnyObject]? {
        switch self {
//        case .VehicleStatus:
//            return ["deviceTime" : "2015-12-10T16:47:03-500"] // deviceTime seems to be optional
        case .Login(let username, let password, _):
            return [
                "grant_type"        : "password",
                "username"          : username,
                "password"          : password,
                "scope"             : "remote_services vehicle_data",
            ]
        default:
            return nil
        }
    }
    
    private var authorizationHeader: String {
        switch self {
        case .Login(_,_,_):
            return "Basic " + Router.APIKey
        default:
            return "Bearer " + (accessToken)
        }
    }
    
    public var URLRequest: NSMutableURLRequest {
        
        let URL = NSURL(string: baseURLString)!
        let mutableURLRequest = NSMutableURLRequest(URL: URL.URLByAppendingPathComponent(path))
        mutableURLRequest.HTTPMethod = method.rawValue
        mutableURLRequest.setValue(authorizationHeader, forHTTPHeaderField: "Authorization")
        
        if parameters == nil {
            return mutableURLRequest
        } else {
            switch method {
            case .POST:
                return Alamofire.ParameterEncoding.URL.encode(mutableURLRequest, parameters: parameters).0
            default:
                return Alamofire.ParameterEncoding.URLEncodedInURL.encode(mutableURLRequest, parameters: parameters).0
            }
        }
    }
}

