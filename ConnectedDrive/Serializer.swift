//
//  Serializer.swift
//  i3Trip
//
//  Created by Ronald Mannak on 12/14/15.
//  Copyright © 2015 Ronald Mannak. All rights reserved.
//
// https://littlebitesofcocoa.com/94-custom-alamofire-response-serializers

import Foundation
import Alamofire
import Decodable

extension Alamofire.Request {
    
    /**
    Serializes arrays stored in `key`
    
    - parameter key:               key under which the array is stored e.g. `"vehicles"`
    - parameter completionHandler: `Result.Success([T])` or `Result.Failure(NSError)`
    
    - returns: Self
    */
    public func responseCollection<T: Decodable>(_ key: String, completionHandler: (Response<[T], NSError>) -> Void) -> Self {
        let responseSerializer = ResponseSerializer<[T], NSError> { request, response, data, error in
            
            guard error == nil else { return .failure(error!) }
            
            let result = Alamofire
                .Request
                .JSONResponseSerializer(options: .allowFragments)
                .serializeResponse(request, response, data, error)
            
            switch result {
            case .success(let value):
                do {
                    guard let items = value.value(forKey: key) else {
                        let error = NSError(domain: "ConnectedDrive", code: Error.Code.jsonSerializationFailed.rawValue, userInfo: ["JSON": value])
                        return .failure(error)
                    }
                    return .success(try [T].decode(items))
                } catch {
                    let error = NSError(domain: "ConnectedDrive", code: Error.Code.jsonSerializationFailed.rawValue, userInfo: ["JSON": value])
                    return .failure(error)
                }
            case .failure(let error):
                return.failure(error)
            }
        }
        
        return response(responseSerializer: responseSerializer, completionHandler: completionHandler)
    }
    
    // Single object
    /**
    Serializes a single object
    
    - parameter completionHandler: `Result.Success(T)` or `Result.Failure(NSError)`
    
    - returns: Self
    */
    public func responseObject<T: Decodable>(_ completionHandler: (Response<T, NSError>) -> Void) -> Self {
        
        let responseSerializer = ResponseSerializer<T, NSError> { request, response, data, error in
            
            guard error == nil else { return .failure(error!) }
            
            let JSONResponseSerializer = Request.JSONResponseSerializer(options: .allowFragments)
            let result = JSONResponseSerializer.serializeResponse(request, response, data, error)
            
            switch result {
            case .success(let value):
                
                do {
                    return .success(try T.decode(value))
                } catch {
                    let error = NSError(domain: "ConnectedDrive", code: Error.Code.jsonSerializationFailed.rawValue, userInfo: ["JSON": value])
                    return .failure(error)
                }
            case .failure(let error):
                return .failure(error)
            }
        }
        
        return response(responseSerializer: responseSerializer, completionHandler: completionHandler)
    }
    
//    /**
//     Parses not authenticated errors.
//     
//     - parameter error: Error received from Alamofire
//     
//     - returns: original error or a not authorized error
//     */
//    private func parseNotAuthenticatedError(error: NSError) -> NSError {
//        return isNotAuthenticatedError(error) ? VehicleError.errorWithCode(.AuthenticationFailed, failureReason: "Token was rejected by server") : error
//    }
//    
//    /**
//     Returns true if error is a "Not Authenticated" 401 error
//     
//     - parameter error: Error received from Alamofire
//     
//     - returns: true if error is a "Not Authenticated" 401 error
//     */
//    private func isNotAuthenticatedError(error: NSError) -> Bool {
//        return error.domain == Error.Domain && error.code == Error.Code.StatusCodeValidationFailed.rawValue && error.localizedDescription.rangeOfString("401") != nil
//    }
}

