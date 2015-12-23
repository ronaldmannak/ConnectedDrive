//
//  VehicleStatusEnum.swift
//  i3Trip
//
//  Created by Ronald Mannak on 12/14/15.
//  Copyright © 2015 Ronald Mannak. All rights reserved.
//

import Foundation
import Decodable


/// BMW server addresses. The rawvalues correspond with "hub" value of the server vehicle list.

enum BMWHub: String {
    
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

enum ChargingStatus: String {
    
    case NotConnected           = "INVALID"
    case Charging               = "CHARGING"
    case FinishedFullyCharged   = "FINISHED_FULLY_CHARGED"
    case FinishedNotFull        = "FINISHED_NOT_FULL"
    case WaitingForCharging     = "WAITING_FOR_CHARGING"
    case NotCharging            = "NOT_CHARGING"
    case Error                  = "ERROR"
    case UnknownKey             = "UNKNOWNKEY"      // Used when API returns unknown key
    
    var description: String {
        return NSLocalizedString(self.rawValue, comment: "")
    }
    
    init(string: String?) {
        if let string = string, status = ChargingStatus(rawValue: string) {
            self = status
        } else {
            self = .UnknownKey
        }
    }
}

enum ConnectionStatus: String {
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
    
    var description: String {
        return NSLocalizedString(self.rawValue, comment: "")
    }
    
    init(string: String?) {
        if let string = string, status = ConnectionStatus(rawValue: string) {
            self = status
        } else {
            self = .UnknownKey
        }
    }
}

enum DoorStatus: String {
    case Open                   = "OPEN"
    case Closed                 = "CLOSED"
    case Secured                = "SECURED"
    case Invalid                = "INVALID"
    case UnknownKey             = "UNKNOWNKEY"      // Used when API returns unknown key
    
    var description: String {
        return NSLocalizedString(self.rawValue, comment: "")
    }
    
    init(string: String?) {
        if let string = string, status = DoorStatus(rawValue: string) {
            self = status
        } else {
            self = .UnknownKey
        }
    }
}

enum LightStatus: String {
    case On                     = "ON"
    case Off                    = "OFF"
    case Invalid                = "Invalid"
    case UnknownKey             = "UNKNOWNKEY"      // Used when API returns unknown key
    
    var description: String {
        return NSLocalizedString(self.rawValue, comment: "")
    }
    
    init(string: String?) {
        if let string = string, status = LightStatus(rawValue: string) {
            self = status
        } else {
            self = .UnknownKey
        }
    }
}

enum VehicleService: String {
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
}

//enum RequestStatus {
//    DELIVERED
//    EXECUTED
//    INITIATED
//    NOT_EXECUTED
//    PENDING
//    TIMED_OUT
//}