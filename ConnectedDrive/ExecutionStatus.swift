//
//  ExecutionStatus.swift
//  ConnectedDrive
//
//  Created by Ronald Mannak on 12/26/15.
//  Copyright © 2015 Ronald Mannak. All rights reserved.
//

import Foundation
import Decodable

public struct ExecutionStatus {
    let serviceType: VehicleService
    let status: RequestStatus
    let eventID: String
}

extension ExecutionStatus: Decodable {
    
    public static func decode(_ json: AnyObject) throws -> ExecutionStatus {
        
        let status = try json => "executionStatus"
        
        return try ExecutionStatus(serviceType: VehicleService(string: try! status => "serviceType"), status: RequestStatus(string: try! status => "status"), eventID: status => "eventId")
    }
}
