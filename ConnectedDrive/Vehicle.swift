//
//  Vehicle.swift
//  i3Trip
//
//  Created by Ronald Mannak on 12/10/15.
//  Copyright © 2015 Ronald Mannak. All rights reserved.
//

import Foundation
import Decodable

/**
 <#Description#>
 
 - BEV: Battery Electric Vehicle
 - REX: Range Extender
 */
public enum DriveTrain: String {
    case BEV = "BEV"
    case REX = "REX"
}

public enum BMWiModel: String {
    case I3 = "I3"
    case I8 = "I8"
    
    public var description: String {
        switch self {
        case .I3:
            return "i3"
        case .I8:
            return "i8"
        }
    }
}

/// BMW Color codes
public enum BMWiColor: String {
    
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
    
    /// Returns localized description from Localizable.string
    public var description: String {
        switch self {
        case B72:
            return NSLocalizedString("Ionic Silver metallic", tableName: nil, bundle: Bundle(for: ConnectedDrive.self), value: "", comment: "")
        case B74:
            return NSLocalizedString("Arravani Grey", tableName: nil, bundle: Bundle(for: ConnectedDrive.self), value: "", comment: "")
        case B78:
            return NSLocalizedString("Solar Orange", tableName: nil, bundle: Bundle(for: ConnectedDrive.self), value: "", comment: "")
        case B81:
            return NSLocalizedString("Andesit Silver metallic", tableName: nil, bundle: Bundle(for: ConnectedDrive.self), value: "", comment: "")
        case B85:
            let isStarWarsDay: Bool = {
                // Star Wars day is May 4th
                let calendar    = Calendar.current
                let starWarsDay: Date = {
                    var components      = DateComponents()
                    components.day      = 4
                    components.month    = 5
                    return calendar.date(from: components)!
                }()
                return calendar.isDate(Date(), inSameDayAs: starWarsDay)
            }()
            if isStarWarsDay {
                return NSLocalizedString("Stormtrooper", tableName: nil, bundle: Bundle(for: ConnectedDrive.self), value: "", comment: "")
            }
            return NSLocalizedString("Capparis White", tableName: nil, bundle: Bundle(for: ConnectedDrive.self), value: "", comment: "")
        case C2U:
            return NSLocalizedString("Platinum Silver", tableName: nil, bundle: Bundle(for: ConnectedDrive.self), value: "", comment: "")
        case C2V:
            return NSLocalizedString("Mineral Grey", tableName: nil, bundle: Bundle(for: ConnectedDrive.self), value: "", comment: "")
        case C2W:
            return NSLocalizedString("Fluid Black", tableName: nil, bundle: Bundle(for: ConnectedDrive.self), value: "", comment: "")
        case C01:
            return NSLocalizedString("Protonic Blue", tableName: nil, bundle: Bundle(for: ConnectedDrive.self), value: "", comment: "")
        case .UnknownKey:
            return NSLocalizedString("Unknown color", tableName: nil, bundle: Bundle(for: ConnectedDrive.self), value: "", comment: "")
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

/**
 *  Vehicle info
 */
public struct Vehicle {
    
    public let model: BMWiModel
    public let bodyType: String
    public let year: Int
    public let VIN: String
    public let hub: BMWHub
    public let color: BMWiColor
    public let driveTrain: DriveTrain
    public let countryCode: String

//    public let canBlowHorn: Bool
//    public let canFlashLight: Bool
//    public let canReceivePOI: Bool
//    public let vehicleFinderActivated: Bool
    
    public var lastVehicleStatus: VehicleStatus?
}

extension Vehicle: Decodable {
    
    public static func decode(_ json: AnyObject) throws -> Vehicle {
        
        return try Vehicle(
            model: BMWiModel(rawValue: json => "model")!,
            bodyType: json => "bodytype",
            year: json => "yearOfConstruction",
            VIN: json => "vin",
            hub: BMWHub(rawValue: json => "hub")!,
            color: BMWiColor(string: try? json => "colorCode"),
            driveTrain: DriveTrain(rawValue: json => "driveTrain")!,
            countryCode: json => "countryCode",
//            canBlowHorn: <#T##Bool#>,
//            canFlashLight: <#T##Bool#>,
//            canReceivePOI: <#T##Bool#>,
//            vehicleFinderActivated: <#T##Bool#>,
            lastVehicleStatus: nil
        )
    }
}
