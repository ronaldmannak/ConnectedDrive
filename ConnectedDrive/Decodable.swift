//
//  Decodable.swift
//  i3Trip
//
//  Created by Ronald Mannak on 12/17/15.
//  Copyright © 2015 Ronald Mannak. All rights reserved.
//

import Foundation
import Decodable
import CoreLocation

extension NSDate: Decodable {
    
    enum NSDateDecodingError: ErrorType {
        case InvalidStringFormat
    }
    
    public class func decode(json: AnyObject) throws -> Self {
        
        let string = try String.decode(json)
        let dateFormat = NSDateFormatter()
        dateFormat.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZ" // e.g. "2015-12-10T22:48:49-0500"
        guard let date = dateFormat.dateFromString(string) else {
            throw NSDateDecodingError.InvalidStringFormat
        }
        
        return self.init(timeIntervalSince1970: date.timeIntervalSince1970)
    }
}

extension CLLocation: Decodable {
    
    public static func decode(json: AnyObject) throws -> Self {
        
        let latitude: CLLocationDegrees     = try json => "lat"
        let longitude: CLLocationDegrees    = try json => "lon"
        let direction: CLLocationDirection  = try json => "heading"
        let coordinate                      = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        return self.init(coordinate: coordinate, altitude: 0, horizontalAccuracy: 0, verticalAccuracy: 0, course: direction, speed: 0, timestamp: NSDate())
    }
}

extension CLLocationCoordinate2D: Decodable {
    
    public static func decode(json: AnyObject) throws -> CLLocationCoordinate2D {
        let latitude: CLLocationDegrees     = try json => "lat"
        let longitude: CLLocationDegrees    = try json => "lon"
        
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}