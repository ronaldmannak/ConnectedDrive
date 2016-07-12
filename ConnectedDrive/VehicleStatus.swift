
//  VehicleStatus.swift
//  i3Trip
//
//  Created by Ronald Mannak on 12/10/15.
//  Copyright © 2015 Ronald Mannak. All rights reserved.
//

import Foundation
import Alamofire
import CoreLocation
import Decodable

/**
 *  Detailed vehicle status
 */
public struct VehicleStatus {
    
    public let fetchTime: Date                   // Time of last fetch
    public let updateTime: Date                  // Time of last update reason (not the time the information was fetched)
    public let chargingLevelHv: Int
    public let chargingStatus: ChargingStatus
    public let connectionStatus: ConnectionStatus
    public let updateReason: ConnectionStatus
    public let chargingTimeRemaining: Int?
    public let lastChargingEndReason: String       // Always UNKNOWN?
    public let lastChargingEndResult: String       // Always UNKNOWN?
    public let maxRangeKM: Int
    public let maxRangeMi: Int
    public let remainingRangeKM: Int
    public let remainingRangeMi: Int
    public let remainingFuel: Int
    public let mileage: Int
    public let location: CLLocation?
    
    // Doors and Windows
    public let doorLockState: DoorStatus
    public let convertibleRoof: DoorStatus
    public let doorDriverFront: DoorStatus
    public let doorDriverRear: DoorStatus
    public let doorPassengerFront: DoorStatus
    public let doorPassengerRear: DoorStatus
    public let hood: DoorStatus
    public let parkingLight: LightStatus
    public let positionLight: LightStatus
    public let windowDriverFront: DoorStatus
    public let windowDriverRear: DoorStatus
    public let windowPassengerFront: DoorStatus
    public let windowPassengerRear: DoorStatus
    
    public var chargingTimeRemainingString: String {
        get {
            guard let chargingTimeRemaining = chargingTimeRemaining else { return "" }
            
            let hours = chargingTimeRemaining / 60
            let minutes = chargingTimeRemaining % 60
            return "\(hours):" + String(format: "%02d", minutes) + " " + (hours > 0 ? NSLocalizedString("hours", tableName: nil, bundle: Bundle(for: ConnectedDrive.self), value: "", comment: "") : NSLocalizedString("minutes", tableName: nil, bundle: Bundle(for: ConnectedDrive.self), value: "", comment: ""))
        }
    }
    
    public var windowState: DoorStatus {
        if windowDriverFront == .Open || windowPassengerFront == .Open || windowDriverRear == .Open || windowPassengerRear == .Open {
            return .Open
        } else {
            return .Closed
        }
    }
    
    public var carIsSecured: Bool {
        
        return doorLockState        == .Secured &&
            windowDriverFront       == .Closed &&
            windowDriverRear        == .Closed &&
            windowPassengerFront    == .Closed &&
            windowPassengerRear     == .Closed &&
            doorDriverFront         == .Closed &&
            doorDriverRear          == .Closed &&
            doorPassengerFront      == .Closed &&
            doorPassengerRear       == .Closed &&
            (convertibleRoof        == .Invalid ||
            convertibleRoof         == .Closed)
    }
}

extension VehicleStatus: Decodable {
    
    public static func decode(_ json: AnyObject) throws -> VehicleStatus {
        
        let status = try json => "vehicleStatus"

        return try VehicleStatus(
            fetchTime: Date(),
            updateTime: status => "updateTime",
            chargingLevelHv: status => "chargingLevelHv",
            chargingStatus: ChargingStatus(string: try? status => "chargingStatus"),
            connectionStatus: ConnectionStatus(string: try? status => "connectionStatus"),
            updateReason: ConnectionStatus(string: try? status => "updateReason"),
            chargingTimeRemaining: try? status => "chargingTimeRemaining",
            lastChargingEndReason: status => "lastChargingEndReason",
            lastChargingEndResult: status => "lastChargingEndResult",
            maxRangeKM: status => "maxRangeElectric",
            maxRangeMi: status => "maxRangeElectricMls",
            remainingRangeKM: status => "remainingRangeElectric",
            remainingRangeMi: status => "remainingRangeElectricMls",
            remainingFuel: status => "remainingFuel",
            mileage: status => "mileage",
            location: try? status => "position",
            doorLockState: DoorStatus(string: try? status => "doorLockState"),
            convertibleRoof: DoorStatus(string: try? status => "convertibleRoofState"),
            doorDriverFront: DoorStatus(string: try? status => "doorDriverFront"),
            doorDriverRear: DoorStatus(string: try? status => "doorDriverRear"),
            doorPassengerFront: DoorStatus(string: try? status => "doorPassengerFront"),
            doorPassengerRear: DoorStatus(string: try? status => "doorPassengerRear"),
            hood: DoorStatus(string: try? status => "hood"),
            parkingLight: LightStatus(string: try? status => "parkingLight"),
            positionLight: LightStatus(string: try? status => "positionLight"),
            windowDriverFront: DoorStatus(string: try? status => "windowDriverFront"),
            windowDriverRear: DoorStatus(string: try? status => "windowDriverRear"),
            windowPassengerFront: DoorStatus(string: try? status => "windowPassengerFront"),
            windowPassengerRear: DoorStatus(string: try? status => "windowPassengerRear")
        )
    }
}
