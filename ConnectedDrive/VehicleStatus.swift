
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

struct VehicleStatus {
    
    let fetchTime: NSDate                   // Time of last fetch
    let updateTime: NSDate                  // Time of last update reason (not the time the information was fetched)
    let chargingLevelHv: Int
    let chargingStatus: ChargingStatus
    let connectionStatus: ConnectionStatus
    let updateReason: ConnectionStatus
    let chargingTimeRemaining: Int?
    let lastChargingEndReason: String       // Always UNKNOWN?
    let lastChargingEndResult: String       // Always UNKNOWN?
    let maxRangeKM: Int
    let maxRangeMi: Int
    let remainingRangeKM: Int
    let remainingRangeMi: Int
    let remainingFuel: Int
    let mileage: Int
    let location: CLLocation?
    
    // Doors and Windows
    let doorLockState: DoorStatus
    let convertibleRoof: DoorStatus
    let doorDriverFront: DoorStatus
    let doorDriverRear: DoorStatus
    let doorPassengerFront: DoorStatus
    let doorPassengerRear: DoorStatus
    let hood: DoorStatus
    let parkingLight: LightStatus
    let positionLight: LightStatus
    let windowDriverFront: DoorStatus
    let windowDriverRear: DoorStatus
    let windowPassengerFront: DoorStatus
    let windowPassengerRear: DoorStatus
    
    var chargingTimeRemainingString: String {
        get {
            guard let chargingTimeRemaining = chargingTimeRemaining else { return "" }
            
            let hours = chargingTimeRemaining / 60
            let minutes = chargingTimeRemaining % 60
            return "\(hours):" + String(format: "%02d", minutes) + " " + (hours > 0 ? NSLocalizedString("hours", comment: "") : NSLocalizedString("minutes", comment: ""))
        }
    }
    
    var carIsSecured: Bool {
        
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
    
    static func decode(json: AnyObject) throws -> VehicleStatus {
        
        let status = try json => "vehicleStatus"

        return try VehicleStatus(
            fetchTime: NSDate(),
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
