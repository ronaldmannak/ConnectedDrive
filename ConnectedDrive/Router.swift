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
        guard let info = Bundle.main.infoDictionary, let APIKey = info["APIKey"] as? String else {
            fatalError("No API key in info.plist found. Store Base64 encoded API key (looks similar to: a2V5OnNlY3JldA==). See also https://github.com/quentinsf/BMW-i-Remote")
        }
        return APIKey
    }
    
    case login(username: String, password: String, hub: BMWHub)
    case refreshToken(login: Credentials)
    case vehicles(login: Credentials)
    case vehicleStatus(VIN: String, login: Credentials)
    case lastTrip(VIN: String, login: Credentials)
    case allTrips(VIN: String, login: Credentials)
    case chargingTimes(VIN: String, login: Credentials)
    case vehicleDestinations(VIN: String, login: Credentials)
    case rangeMap(VIN: String, login: Credentials)
    case serviceStatus(VIN: String, service: VehicleService, login: Credentials)
    case executeService(VIN: String, service: VehicleService, login: Credentials)
    case chargingStations(login: Credentials)

    private var method: Alamofire.Method {
        switch self {
        case .login(_,_,_), .executeService(_,_,_), .refreshToken(_):
            return .POST
        default:
            return .GET
        }
    }
    
    private var accessToken: String {
        switch self {
        case .login(_, _, _), .refreshToken(_):
            return ""
        case .vehicles(let credentials):
            return credentials.tokens.accessToken
        case .vehicleStatus(_, let credentials):
            return credentials.tokens.accessToken
        case .lastTrip(_, let credentials):
            return credentials.tokens.accessToken
        case .allTrips(_ , let credentials):
            return credentials.tokens.accessToken
        case .chargingTimes(_, let credentials):
            return credentials.tokens.accessToken
        case .vehicleDestinations(_, let credentials):
            return credentials.tokens.accessToken
        case .rangeMap(_, let credentials):
            return credentials.tokens.accessToken
        case .serviceStatus(_, _, let credentials):
            return credentials.tokens.accessToken
        case .executeService(_, _, let credentials):
            return credentials.tokens.accessToken
        case .chargingStations(let credentials):
            return credentials.tokens.accessToken
        }
    }
    
    private var baseURLString: String {
        switch self {
        case .login(_, _, let hub):
            return hub.baseURLString
        case .refreshToken(let credentials):
            return credentials.hub.baseURLString
        case .vehicles(let credentials):
            return credentials.hub.baseURLString
        case .vehicleStatus(_, let credentials):
            return credentials.hub.baseURLString
        case .lastTrip(_, let credentials):
            return credentials.hub.baseURLString
        case .allTrips(_ , let credentials):
            return credentials.hub.baseURLString
        case .chargingTimes(_, let credentials):
            return credentials.hub.baseURLString
        case .vehicleDestinations(_, let credentials):
            return credentials.hub.baseURLString
        case .rangeMap(_, let credentials):
            return credentials.hub.baseURLString
        case .serviceStatus(_, _, let credentials):
            return credentials.hub.baseURLString
        case .executeService(_, _, let credentials):
            return credentials.hub.baseURLString
        case .chargingStations(let credentials):
            return credentials.hub.baseURLString
        }
    }
    
    private var path: String {
        switch self {
        case .login(_,_,_), .refreshToken(_):
            return "webapi/oauth/token/"
        case .vehicles(_):
            return "/webapi/v1/user/vehicles/"
        case .vehicleStatus(let VIN, _):
            return "/webapi/v1/user/vehicles/\(VIN)/status"
        case .lastTrip(let VIN, _):
            return "/webapi/v1/user/vehicles/\(VIN)/statistics/lastTrip"
        case .allTrips(let VIN, _):
            return "/webapi/v1/user/vehicles/\(VIN)/statistics/allTrips"
        case .chargingTimes(let VIN, _):
            return "/webapi/v1/user/vehicles/\(VIN)/chargingprofile"
        case .vehicleDestinations(let VIN, _):
            return "/webapi/v1/user/vehicles/\(VIN)/destinations"
        case .rangeMap(let VIN, _):
            return "/webapi/v1/user/vehicles/\(VIN)/rangemap"
        case .serviceStatus(let VIN, let service, _):
            return "/webapi/v1/user/vehicles/\(VIN)/serviceExecutionStatus?serviceType=\(service.rawValue)" // TODO: parameter in dict?
        case .executeService(let VIN, _, _):
            return "/webapi/v1/user/vehicles/\(VIN)/executeService"
        case .chargingStations(_):
            return "webapi/v1/chargingstations/dynamicdata"
        }
    }
    
    private var parameters: [String : AnyObject]? {
        switch self {
//        case .VehicleStatus:
//            return ["deviceTime" : "2015-12-10T16:47:03-500"] // deviceTime seems to be optional
        case .login(let username, let password, _):
            return [
                "grant_type"        : "password",
                "username"          : username,
                "password"          : password,
                "scope"             : "remote_services vehicle_data",
            ]
        case .refreshToken(let credentials):
            return [
                "grant_type"        : "refresh_token",
                "refresh_token"     : credentials.tokens.refreshToken
            ]
        case .executeService(_, let service, _):
            return ["serviceType"   : service.rawValue]
        case .serviceStatus(_, let service, _):
            return ["serviceType"   : service.rawValue]
        default:
            return nil
        }
    }
    
    private var authorizationHeader: String {
        
        switch self {
        case .login(_,_,_), .refreshToken(_):
            return "Basic " + Router.APIKey
        default:
            return "Bearer " + (accessToken)
        }
    }
    
    public var urlRequest: URLRequest {
        
        let URL = Foundation.URL(string: baseURLString)!
        var request = URLRequest(url: try! URL.appendingPathComponent(path))
        request.httpMethod = method.rawValue
        request.setValue(authorizationHeader, forHTTPHeaderField: "Authorization")
        
        if parameters == nil {
            return request
        } else {
            switch method {
            case .POST:
                return Alamofire.ParameterEncoding.url.encode(request, parameters: parameters).0
            default:
                return Alamofire.ParameterEncoding.urlEncodedInURL.encode(request, parameters: parameters).0
            }
        }
    }
}

