//
//  RangeMap.swift
//  i3Trip
//
//  Created by Ronald Mannak on 12/16/15.
//  Copyright © 2015 Ronald Mannak. All rights reserved.
//

import Foundation
import CoreLocation
import Decodable

/**
 *  Range map polygons for Comfort and Eco Pro Plus modes that can be projected on a map
 */
public struct RangeMap {
    
    public let center: CLLocationCoordinate2D
    public let polyLines: [RangeMapPolyLine]
    public let quality: String
}

extension RangeMap: Decodable {

    public static func decode(_ json: AnyObject) throws -> RangeMap {
        let rangeMapJSON = try json => "rangemap"
        return RangeMap(center: try rangeMapJSON => "center", polyLines: try rangeMapJSON => "rangemaps", quality: try rangeMapJSON => "quality")
    }
}

/**
 *  Stores polygon and car mode
 */
public struct RangeMapPolyLine {
    
    /**
     Types of car modes
     
     - Comfort:    Range polygon for comfort
     - EcoPro:     Range polygon for Eco Pro
     - EcoProPlus: Range polygon for Eco Pro Plus
     */
    public enum RangeMapPolyLineType: String {
        case Comfort =      "COMFORT"
        case EcoPro =       "ECO_PRO"
        case EcoProPlus =   "ECO_PRO_PLUS"
    }
    
    public let type: RangeMapPolyLineType
    public let polyLine: [CLLocationCoordinate2D]
}

extension RangeMapPolyLine: Decodable {
    
    public static func decode(_ json: AnyObject) throws -> RangeMapPolyLine {
        
        let type = try RangeMapPolyLineType(rawValue: json => "type")!
        let polyLine = try [CLLocationCoordinate2D].decode(json => "polyline")
        
        return RangeMapPolyLine(type: type, polyLine: polyLine)
    }
}
