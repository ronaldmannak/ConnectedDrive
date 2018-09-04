//
//  VehicleStatusEnum.swift
//  i3Trip
//
//  Created by Ronald Mannak on 12/14/15.
//  Copyright © 2015 Ronald Mannak. All rights reserved.
//

import Foundation
import Decodable

/// Wraps the "hub" value of Vehicle
///
/// BMW has three geographically different servers: China, Europa and USA. 
/// While a ConnectedDrive user can login to any server and retrieve their vehicle list,
/// the app needs to communicate with one specific server for vehicle status and vehicle commands.
///
/// The rawValues correspond with "hub" JSON value of the server vehicle list.
/// Note: "HUB_CN" is not verified to be the code for the Chinese server.

public enum BMWHub: String {
    
    case China                  = "HUB_CN"
    case Europe                 = "HUB_ECE"         // And rest of the world
    case USA                    = "HUB_US"
    
    var baseURLString: String {
        switch self {
        case .China:
            return "https://b2vapi.bmwgroup.cn:8592"
        case .Europe:
            return "https://b2vapi.bmwgroup.com"
        case .USA:
            return "https://b2vapi.bmwgroup.us"
        }
    }
}

/// Wrapper for the "chargingstatus" field in the vehicle status JSON. Uses Localizable.strings for localized descriptions.
public enum ChargingStatus: String {
    
    case NotConnected           = "INVALID"
    case Charging               = "CHARGING"
    case FinishedFullyCharged   = "FINISHED_FULLY_CHARGED"
    case FinishedNotFull        = "FINISHED_NOT_FULL"
    case WaitingForCharging     = "WAITING_FOR_CHARGING"
    case NotCharging            = "NOT_CHARGING"
    case Error                  = "ERROR"
    case UnknownKey             = "UNKNOWNKEY"      // Used when API returns unknown key
    
    
    // Human readable description, stored in Localizable.string
    public var description: String {
        return NSLocalizedString(self.rawValue, tableName: nil, bundle: Bundle(for: ConnectedDrive.self), value: "", comment: "")
    }
    
    init(string: String?) {
        if let string = string, status = ChargingStatus(rawValue: string) {
            self = status
        } else {
            self = .UnknownKey
        }
    }
}

/// Wrapper for both "connectionStatus" and "updateReason" vehicle status fields.
public enum ConnectionStatus: String {
    case Connected              = "CONNECTED"
    case ChargingDone           = "CHARGING_DONE"
    case ChargingInterrupted    = "CHARGING_INTERRUPED"
    case ChargingPaused         = "CHARGING_PAUSED"
    case ChargingStarted        = "CHARGING_STARTED"
    case ChargingStarted2       = "CHARGIN_STARTED" // Typo in connectionStatus
    case CyclicRecharging       = "CYCLIC_RECHARGING"
    case DoorStateChanged       = "DOOR_STATE_CHANGED"
    case NoCyclicRecharging     = "NO_CYCLIC_RECHARGING"
    case NoLSCTrigger           = "NO_LSC_TRIGGER"
    case OnDemand               = "ON_DEMAND"
    case PredictionUpdate       = "PREDICTION_UPDATE"
    case TempPowerSupplyFailure = "TEMPORARY_POWER_SUPPLY_FAILURE"
    case Unknown                = "UNKNOWN"
    case VehicleMoving          = "VEHICLE_MOVING"
    case VehicleSecured         = "VEHICLE_SECURED"
    case VehicleShutdown        = "VEHICLE_SHUTDOWN"
    case VehicleShutdownSecured = "VEHICLE_SHUTDOWN_SECURED"
    case VehicleUnsecured       = "VEHICLE_UNSECURED"
    case Disconnected           = "DISCONNECTED"
    case UnknownKey             = "UNKNOWNKEY"      // Used when API returns unknown key

    // Human readable description, stored in Localizable.string
    public var description: String {
        return NSLocalizedString(self.rawValue, tableName: nil, bundle: Bundle(for: ConnectedDrive.self), value: "", comment: "")
    }
    
    init(string: String?) {
        if let string = string, status = ConnectionStatus(rawValue: string) {
            self = status
        } else {
            self = .UnknownKey
        }
    }
}

/// Wrapper for door and window fields. Window can only be Open or Closed
public enum DoorStatus: String {
    case Open                   = "OPEN"
    case Closed                 = "CLOSED"
    case Secured                = "SECURED"
    case Invalid                = "INVALID"
    case Intermediate           = "INTERMEDIATE"
    case Unlocked               = "UNLOCKED"
    case Locked                 = "LOCKED"
    case SelectiveLocked        = "SELECTIVE_LOCKED"
    case UnknownKey             = "UNKNOWNKEY"      // Used when API returns unknown key
    
    // Human readable description, stored in Localizable.string
    public var description: String {
        return NSLocalizedString(self.rawValue, tableName: nil, bundle: Bundle(for: ConnectedDrive.self), value: "", comment: "")
    }
    
    init(string: String?) {
        if let string = string, status = DoorStatus(rawValue: string) {
            self = status
        } else {
            self = .UnknownKey
        }
    }
}


/// Wrapper for positionLight and parkingLight
public enum LightStatus: String {
    case On                     = "ON"
    case Off                    = "OFF"
    case Invalid                = "Invalid"
    case UnknownKey             = "UNKNOWNKEY"      // Used when API returns unknown key
    
    // Human readable description, stored in Localizable.string
    public var description: String {
        return NSLocalizedString(self.rawValue, tableName: nil, bundle: Bundle(for: ConnectedDrive.self), value: "", comment: "")
    }
    
    init(string: String?) {
        if let string = string, status = LightStatus(rawValue: string) {
            self = status
        } else {
            self = .UnknownKey
        }
    }
}

/**
 Wrapper for car commands
 
 - ChargeNow:              <#ChargeNow description#>
 - ChargingControl:        <#ChargingControl description#>
 - ClimateControl:         <#ClimateControl description#>
 - ClimateControlStart:    <#ClimateControlStart description#>
 - DoorLock:               <#DoorLock description#>
 - DoorUnlock:             <#DoorUnlock description#>
 - AllImages:              <#AllImages description#>
 - PasswordReset:          <#PasswordReset description#>
 - Vehicles:               <#Vehicles description#>
 - VehicleImage:           <#VehicleImage description#>
 - VehicleStatus:          <#VehicleStatus description#>
 - HornBlow:               <#HornBlow description#>
 - LightFlash:             <#LightFlash description#>
 - LocalSearch:            <#LocalSearch description#>
 - LocalSearchSuggestions: <#LocalSearchSuggestions description#>
 - Login:                  <#Login description#>
 - Logout:                 <#Logout description#>
 - SendPOIToCar:           <#SendPOIToCar description#>
 - VehicleFinder:          <#VehicleFinder description#>
 */
public enum VehicleService: String {
    case ChargeNow              = "CHARGE_NOW"
    case ChargingControl        = "CHARGING_CONTROL"
    case ClimateControl         = "CLIMATE_CONTROL"
    case ClimateControlStart    = "CLIMATE_NOW"
    case DoorLock               = "DOOR_LOCK"
    case DoorUnlock             = "DOOR_UNLOCK"
    case AllImages              = "GET_ALL_IMAGES"
    case PasswordReset          = "GET_PASSWORD_RESET_INFO"
    case Vehicles               = "GET_VEHICLES"
    case VehicleImage           = "GET_VEHICLE_IMAGE"
    case VehicleStatus          = "GET_VEHICLE_STATUS"
    case HornBlow               = "HORN_BLOW"
    case LightFlash             = "LIGHT_FLASH"
    case LocalSearch            = "LOCAL_SEARCH"
    case LocalSearchSuggestions = "LOCAL_SEARCH_SUGGESTIONS"
    case Login                  = "LOGIN"
    case Logout                 = "LOGOUT"
    case SendPOIToCar           = "SEND_POI_TO_CAR"
    case VehicleFinder          = "VEHICLE_FINDER"
    
    // Human readable description, stored in Localizable.string
    public var description: String {
        return NSLocalizedString(self.rawValue, tableName: nil, bundle: Bundle(for: ConnectedDrive.self), value: "", comment: "")
    }
    
    init(string: String) {
        self = VehicleService(rawValue: string)!
    }
}

/**
 Wrapper of sent command status
 
 - Delivered:   <#Delivered description#>
 - Executed:    <#Executed description#>
 - Initiated:   <#Initiated description#>
 - NotExecuted: <#NotExecuted description#>
 - Pending:     <#Pending description#>
 - TimedOut:    <#TimedOut description#>
 */
public enum RequestStatus: String {
    case Delivered              = "DELIVERED"
    case Executed               = "EXECUTED"
    case Initiated              = "INITIATED"
    case NotExecuted            = "NOT_EXECUTED"
    case Pending                = "PENDING"
    case TimedOut               = "TIMED_OUT"
    
    // Human readable description, stored in Localizable.string
    public var description: String {
        return NSLocalizedString(self.rawValue, tableName: nil, bundle: Bundle(for: ConnectedDrive.self), value: "", comment: "")
    }
    
    init(string: String) {
        self = RequestStatus(rawValue: string)!
    }
}
