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
    
    // Arrays
    public func responseCollection<T: Decodable>(key: String, completionHandler: Response<[T], NSError> -> Void) -> Self {
        let responseSerializer = ResponseSerializer<[T], NSError> { request, response, data, error in
            
            guard error == nil else { return .Failure(error!) }
            
            let result = Alamofire
                .Request
                .JSONResponseSerializer(options: .AllowFragments)
                .serializeResponse(request, response, data, error)
            
            switch result {
            case .Success(let value):
                do {
                    guard let items = value.valueForKeyPath(key) else {
                        return .Failure(Error.errorWithCode(.JSONSerializationFailed,
                            failureReason: "JSON parsing error, JSON: \(value)"))
                    }
                    return .Success(try [T].decode(items))
                } catch {
                    return .Failure(Error.errorWithCode(.JSONSerializationFailed,
                        failureReason: "JSON parsing error, JSON: \(value)"))
                }
            case .Failure(let error): return.Failure(error)
            }
        }
        
        return response(responseSerializer: responseSerializer, completionHandler: completionHandler)
    }
    
    // Single object
    public func responseObject<T: Decodable>(completionHandler: Response<T, NSError> -> Void) -> Self {

        let responseSerializer = ResponseSerializer<T, NSError> { request, response, data, error in
            
            guard error == nil else { return .Failure(error!) }
            
            let JSONResponseSerializer = Request.JSONResponseSerializer(options: .AllowFragments)
            let result = JSONResponseSerializer.serializeResponse(request, response, data, error)
            
            switch result {
            case .Success(let value):
                
                do {
                    return .Success(try T.decode(value))
                } catch {
                    return .Failure(Error.errorWithCode(.JSONSerializationFailed,
                        failureReason: "JSON parsing error, JSON: \(value)"))
                }
            case .Failure(let error):
                return .Failure(error)
            }
        }
        
        return response(responseSerializer: responseSerializer, completionHandler: completionHandler)
    }
}

