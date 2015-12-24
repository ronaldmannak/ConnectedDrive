//
//  Vehicle.swift
//  i3Trip
//
//  Created by Ronald Mannak on 12/10/15.
//  Copyright © 2015 Ronald Mannak. All rights reserved.
//

import Foundation
import Decodable

enum DriveTrain: String {
    case BEV = "BEV"
    case REX = "REX"
}

enum BMWiModel: String {
    case I3 = "I3"
    case I8 = "I8"
    
    var description: String {
        switch self {
        case .I3:
            return "i3"
        case .I8:
            return "i8"
        }
    }
}

enum BMWiColor: String {
    
    // i3 2014 colors
    case B72 = "B72"
    case B74 = "B74"
    case B78 = "B78"
    case B81 = "B81"
    case B85 = "B85"
    
    // i3 2016 colors
    case C2U = "C2U"
    case C2V = "C2V"
    case C2W = "C2W"
    
    // i8 colors
    case C01 = "C01"
    
    case UnknownKey = "UNKNOWN"
    
    var description: String {
        switch self {
        case B72:
            return NSLocalizedString("Ionic Silver metallic", comment: "")
        case B74:
            return NSLocalizedString("Arravani Grey", comment: "")
        case B78:
            return NSLocalizedString("Solar Orange", comment: "")
        case B81:
            return NSLocalizedString("Andesit Silver metallic", comment: "")
        case B85:
            return NSLocalizedString("Capparis White", comment: "")
        case C2U:
            return NSLocalizedString("Platinum Silver", comment: "")
        case C2V:
            return NSLocalizedString("Mineral Grey", comment: "")
        case C2W:
            return NSLocalizedString("Fluid Black", comment: "")
        case C01:
            return NSLocalizedString("Protonic Blue", comment: "")
        case .UnknownKey:
            return NSLocalizedString("Unknown color", comment: "")
        }
    }
    
    init(string: String?) {
        if let string = string, status = BMWiColor(rawValue: string) {
            self = status
        } else {
            self = .UnknownKey
        }
    }
}

struct Vehicle {
    
    let model: BMWiModel
    let bodyType: String
    let year: Int
    let VIN: String
    let hub: BMWHub
    let color: BMWiColor
    let driveTrain: DriveTrain
    let countryCode: String

//    let canBlowHorn: Bool
//    let canFlashLight: Bool
//    let canReceivePOI: Bool
//    let vehicleFinderActivated: Bool
    
    var lastVehicleStatus: VehicleStatus?
}

extension Vehicle: Decodable {
    
    static func decode(json: AnyObject) throws -> Vehicle {
        
        return try Vehicle(
            model: BMWiModel(rawValue: json => "model")!,
            bodyType: json => "bodytype",
            year: json => "yearOfConstruction",
            VIN: json => "vin",
            hub: BMWHub(rawValue: json => "hub")!,
            color: BMWiColor(string: try? json => "colorCode"),
            driveTrain: DriveTrain(rawValue: json => "driveTrain")!,
            countryCode: json => "countryCode",
////            canBlowHorn: <#T##Bool#>,
////            canFlashLight: <#T##Bool#>,
////            canReceivePOI: <#T##Bool#>,
////            vehicleFinderActivated: <#T##Bool#>,
            lastVehicleStatus: nil
        )
    }
}
