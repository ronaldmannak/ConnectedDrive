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

struct RangeMap {
    
    let center: CLLocationCoordinate2D
    let polyLines: [RangeMapPolyLine]
    let quality: String
}

extension RangeMap: Decodable {

    static func decode(json: AnyObject) throws -> RangeMap {
        let rangeMapJSON = try json => "rangemap"
        return RangeMap(center: try rangeMapJSON => "center", polyLines: try rangeMapJSON => "rangemaps", quality: try rangeMapJSON => "quality")
    }
}


struct RangeMapPolyLine {
    
    enum RangeMapPolyLineType: String {
        case Comfort =      "COMFORT"
        case EcoPro =       "ECO_PRO"
        case EcoProPlus =   "ECO_PRO_PLUS"
    }
    
    let type: RangeMapPolyLineType
    let polyLine: [CLLocationCoordinate2D]
}

extension RangeMapPolyLine: Decodable {
    
    static func decode(json: AnyObject) throws -> RangeMapPolyLine {
        
        let type = try RangeMapPolyLineType(rawValue: json => "type")!
        let polyLine = try [CLLocationCoordinate2D].decode(json => "polyline")
        
        return RangeMapPolyLine(type: type, polyLine: polyLine)
    }
}