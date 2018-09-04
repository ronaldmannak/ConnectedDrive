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

// Make NSDate conform to Decodable protocol
extension Date: Decodable {
    
    enum NSDateDecodingError: ErrorProtocol {
        case invalidStringFormat
    }
    
    public static func decode(_ json: AnyObject) throws -> Date {
        
        let string = try String.decode(json)
        let dateFormat = DateFormatter()
        dateFormat.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZ" // e.g. "2015-12-10T22:48:49-0500"
        guard let date = dateFormat.date(from: string) else {
            throw NSDateDecodingError.invalidStringFormat
        }
        
        return self.init(timeIntervalSince1970: date.timeIntervalSince1970)
    }
}

// Make CLLocation conform to Decodable protocol
extension CLLocation: Decodable {
    
    public static func decode(_ json: AnyObject) throws -> Self {
        
        let latitude: CLLocationDegrees     = try json => "lat"
        let longitude: CLLocationDegrees    = try json => "lon"
        let direction: CLLocationDirection  = try json => "heading"
        let coordinate                      = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        return self.init(coordinate: coordinate, altitude: 0, horizontalAccuracy: 0, verticalAccuracy: 0, course: direction, speed: 0, timestamp: Date())
    }
}

// Make CLLocationCoordinate2D conform to Decodable protocol
extension CLLocationCoordinate2D: Decodable {
    
    public static func decode(_ json: AnyObject) throws -> CLLocationCoordinate2D {
        let latitude: CLLocationDegrees     = try json => "lat"
        let longitude: CLLocationDegrees    = try json => "lon"
        
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
