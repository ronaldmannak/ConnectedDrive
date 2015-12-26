//
//  AppDelegate.swift
//  i3Bar
//
//  Created by Ronald Mannak on 12/13/15.
//  Copyright © 2015 Ronald Mannak. All rights reserved.
//

import Cocoa
import MapKit
import ConnectedDrive

enum FetchInterval: NSTimeInterval {
    case Regular =  600 // 10 minutes
    case Often =    60  // 1 minute
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-2)
    let popup = NSPopover()
    var eventMonitor: EventMonitor?
    let connectedDrive = ConnectedDrive()
    var timer: NSTimer?
    
    // Cache of latest vehicle data
    var vehicleList: [Vehicle]?
    var vehicle: Vehicle?
    var vehicleStatus: VehicleStatus?  {
        didSet {
            updateOnScreenStatus()
        }
    }
    var rangeMap: RangeMap? {
        didSet {
            updateOnScreenStatus()
        }
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        
//        connectedDrive.deleteStoredItems() // For debug purposes only
        connectedDrive.delegate = self
        
        // Register for sleep and wake notifications
        NSWorkspace.sharedWorkspace().notificationCenter.addObserver(self, selector: Selector("wakeNotification:"), name: NSWorkspaceDidWakeNotification, object: nil)
        NSWorkspace.sharedWorkspace().notificationCenter.addObserver(self, selector: Selector("sleepNotification:"), name: NSWorkspaceWillSleepNotification, object: nil)
        
        // Create EventMonitor to hide popup windows when user clicks elsewhere on the screen
        eventMonitor = EventMonitor(mask: NSEventMask.LeftMouseDownMask) { [unowned self] event in
            if self.popup.shown {
                self.closePopup(event)
            }
        }
        eventMonitor?.start()
        
        connectedDrive.autoLogin { result in
            self.updateOnScreenStatus()
        }
    }
    
    func applicationWillTerminate(notification: NSNotification) {
        NSWorkspace.sharedWorkspace().notificationCenter.removeObserver(self)
    }
    

    func wakeNotification(notification: NSNotification) {
        connectedDrive.autoLogin { result in
            self.createTimer(.Regular)
        }
    }
    
    func sleepNotification(notification: NSNotification) {
        removeTimer()
    }
}

/*
 *  Fetch status
 */

extension AppDelegate {
    
    func createTimer(interval: FetchInterval) {

        timer?.invalidate()
        timer = NSTimer.scheduledTimerWithTimeInterval(interval.rawValue, target: self, selector: Selector("fetchStatusFromServer"), userInfo: nil, repeats: true)
        timer?.fire()
    }
    
    func removeTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func fetchVehicleList() {
        
        self.connectedDrive.vehicles { result in
            
            switch result {
            case .Success(let vehicles):
                
                self.vehicleList = vehicles
                self.vehicle = vehicles.first
                
                self.createTimer(.Regular) // Timer fetches vehicle status immediately
                
            case .Failure(let error):
                // TODO:
                print(error)
            }
            
        }
    }
    
    func fetchStatusFromServer() {
        
        guard let vehicle = vehicle else {
            return
        }
        
        connectedDrive.vehicleStatus(vehicle) { status in
            
            switch status {
            case .Success(let status):
                
                if let previousVehicleStatus = self.vehicleStatus where previousVehicleStatus.updateReason.rawValue != status.updateReason.rawValue {
    
                    // Received a new update reason, show banner to notify user
                    let timeFormat = NSDateFormatter()
                    timeFormat.dateFormat = "h:mm a"
                    let timeStamp = timeFormat.stringFromDate(status.updateTime)
                
                    let notification = NSUserNotification()
                    notification.title =  status.updateReason.description + " " + timeStamp
                    notification.informativeText = NSLocalizedString("Previous: ", comment: "") + previousVehicleStatus.updateReason.description
                    
                    NSUserNotificationCenter.defaultUserNotificationCenter().delegate = self
                    NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
                }
                
                self.vehicleStatus = status
                
                // Fetch rangemap
                self.connectedDrive.rangeMap(vehicle) { map in
                    
                    switch map {
                    case .Success(let rangeMap):
                        
                        self.rangeMap = rangeMap
                        
                    case .Failure(let error):
                        print(error)
                    }
                }

            case .Failure(let error):
                print(error)
                self.updateLabel("x", color: NSColor.redColor())
            }
        }
    }
    
    func clearVehicleCache() {
        vehicleList = nil
        vehicle = nil
        vehicleStatus = nil
        rangeMap = nil
    }
    
    func selectVehicleMenuAction(sender: AnyObject) {
        guard let menuItem = sender as? NSMenuItem, vehicleList = vehicleList where menuItem.tag < vehicleList.count else {
            return
        }
        selectVehicle(vehicleList[menuItem.tag])
    }
    
    func selectVehicle(vehicle: Vehicle) {
        self.vehicle = vehicle
        self.vehicleStatus = nil
        self.rangeMap = nil
        fetchStatusFromServer()
    }
}

/*
 *  Menu
 */

extension AppDelegate {
    
    func updateOnScreenStatus() {
        
        if let status = vehicleStatus {
            
            let percentage = status.chargingLevelHv
            let color: NSColor
            if percentage == 100 {
                color = NSColor.greenColor()
            } else if status.chargingStatus == .Charging {
                color = NSColor.blueColor()
            } else if percentage <= 5 {
                color = NSColor.redColor()
            } else {
                color = NSColor.blackColor()
            }
            updateLabel("\(percentage)" + (percentage == 100 ? "" : "%"), color: color)
            
        } else {
            
            updateLabel("...", color: NSColor.grayColor())
        }
        
        updateMenu()
    }
    
    func updateLabel(percentage: String, color: NSColor) {
        
        guard let button = statusItem.button else { return }
        
        let title = NSAttributedString(string: percentage, attributes: [NSForegroundColorAttributeName: color])
        button.attributedTitle = title
    }
    
    func updateMenu() {
        
        let menu: NSMenu
        switch connectedDrive.state {
        case .LoggedIn:
            menu = createLoggedInMenu()
        case .LoggedOut:
            menu = createLoggedOutMenu()
        case .LoggingIn:
            menu = createLoggingInMenu()
        }
        statusItem.menu = menu
    }

    func createLoggedInMenu() -> NSMenu {
        
        guard let currentVehicle = vehicle, status = vehicleStatus else {
            return createLoggingInMenu()
        }
        
        let menu = NSMenu()
        
        // If more than one vehicle is linked to the account, add a choose vehicle submenu
        let vehicleItem = NSMenuItem(title: "BMW " + currentVehicle.model.description + " " + currentVehicle.color.description , action: nil, keyEquivalent: "")
        menu.addItem(vehicleItem)
        vehicleItem.submenu = createVehicleSelectMenu()
        
        // Last Event
        let timeFormat = NSDateFormatter()
        timeFormat.dateFormat = "h:mm a"
        menu.addItemWithTitle(status.updateReason.description + NSLocalizedString(" at ", comment: "") + timeFormat.stringFromDate(status.updateTime), action: nil, keyEquivalent: "")        
        menu.addItem(NSMenuItem.separatorItem())
        
        // If charging, add estimated time until full
        if status.chargingTimeRemaining != nil {
            menu.addItemWithTitle("Time until full: \(status.chargingTimeRemainingString)", action: nil, keyEquivalent: "")
        }
        
        // Range
        menu.addItemWithTitle("Range: \(status.remainingRangeMi) miles", action: nil, keyEquivalent: "")
        
        // Doors and windows
        menu.addItemWithTitle(NSLocalizedString("Doors:", comment: "") + " " + status.doorLockState.description, action: nil, keyEquivalent: "")
        menu.addItemWithTitle(NSLocalizedString("Windows:", comment: "") + " " + status.windowState.description, action: nil, keyEquivalent: "")
        
        // Update Now
        menu.addItemWithTitle(NSLocalizedString("Update now", comment: "") + " (last update \(timeFormat.stringFromDate(status.fetchTime)))", action: Selector("fetchStatusFromServer"), keyEquivalent: "u")

        menu.addItem(NSMenuItem.separatorItem())

        // Vehicle location
        if let location = status.location {

            let vehicleLocationItem = NSMenuItem(title: NSLocalizedString("Vehicle location", comment: ""), action: Selector("viewVehicleLocation:"), keyEquivalent: "l")
            menu.addItem(vehicleLocationItem)

            let vehicleLocationSubmenu = NSMenu()
            let mapItem = NSMenuItem()

            mapItem.view = createMapView(location)
            vehicleLocationSubmenu.addItem(mapItem)
            vehicleLocationItem.submenu = vehicleLocationSubmenu
        }
        
        // Range map
        if let rangeMap = rangeMap {

            let rangeItem = NSMenuItem(title: NSLocalizedString("Range map", comment: ""), action: Selector("viewRange:"), keyEquivalent: "r")
            menu.addItem(rangeItem)
            menu.addItem(NSMenuItem.separatorItem())

            let rangeSubmenu = NSMenu()
            let rangeMapItem = NSMenuItem()

            rangeMapItem.view = createMapView(rangeMap: rangeMap)
            rangeSubmenu.addItem(rangeMapItem)
            rangeItem.submenu = rangeSubmenu
        } else {
            menu.addItemWithTitle(NSLocalizedString("Range map is loading...", comment: ""), action: nil, keyEquivalent: "")
        }
        
        // Quit
        if menu.itemArray.last != NSMenuItem.separatorItem() {
            menu.addItem(NSMenuItem.separatorItem())
        }
        menu.addItemWithTitle(NSLocalizedString("Log out", comment: ""), action: Selector("logout:"), keyEquivalent: "l")
        menu.addItemWithTitle(NSLocalizedString("Quit", comment: ""), action: Selector("terminate:"), keyEquivalent: "q")
        return menu
    }

    func createLoggedOutMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItemWithTitle("Login", action: Selector("showLogin:"), keyEquivalent: "l")
        
        // Quit
        menu.addItem(NSMenuItem.separatorItem())
        menu.addItem(NSMenuItem(title: NSLocalizedString("Quit", comment: ""), action: Selector("terminate:"), keyEquivalent: "q"))
        return menu
    }
    
    func createLoggingInMenu() -> NSMenu {
        
        let menu = NSMenu()
        menu.addItemWithTitle(NSLocalizedString("Logging in...", comment: ""), action: nil, keyEquivalent: "")
        
        // Quit
        menu.addItem(NSMenuItem.separatorItem())
        menu.addItem(NSMenuItem(title: NSLocalizedString("Quit", comment: ""), action: Selector("terminate:"), keyEquivalent: "q"))
        return menu
    }

    func createVehicleSelectMenu() -> NSMenu? {

        guard let vehicleList = vehicleList where vehicleList.count > 1 else {
            return nil
        }
        
        let menu = NSMenu()
        
        for i in 0 ..< vehicleList.count {
            let vehicle = vehicleList[i]
            let title = vehicle.model.description + " " + vehicle.color.description
            let item = NSMenuItem(title: title, action: Selector("selectVehicleMenuAction:"), keyEquivalent: "")
            item.tag = i
            menu.addItem(item)
        }
        
        return menu
    }
}

/*
 *  Maps
 */

extension AppDelegate {
    
    // Empty methods to force view vehicle menu item to become active
    func viewVehicleLocation(sender: AnyObject?) {}
    
    func viewRange(sender: AnyObject?) {}
    
    func createMapView(pinLocation: CLLocation? = nil, rangeMap: RangeMap? = nil) -> MKMapView {
        
        let mapView = MKMapView(frame: NSRect(x: 0, y: 0, width: 300, height: 300))
        
        if let pinLocation = pinLocation {
            let annotation = MKPointAnnotation()
            annotation.coordinate = pinLocation.coordinate
            mapView.addAnnotation(annotation)
            
            let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            let region = MKCoordinateRegion(center: pinLocation.coordinate, span: span)
            mapView.setRegion(region, animated: false)
            
        } else if let rangeMap = rangeMap {

            mapView.delegate = self
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = rangeMap.center
            mapView.addAnnotation(annotation)
            
            for polyLineStruct in rangeMap.polyLines {
                var polyLine = polyLineStruct.polyLine
                let polygon = MKPolygon(coordinates: &polyLine, count: polyLine.count)
                mapView.addOverlay(polygon, level: .AboveRoads)
                
                // Make sure all ranges fit in window
                if polyLineStruct.type == .EcoProPlus {
                    mapView.setVisibleMapRect(polygon.boundingMapRect, edgePadding: NSEdgeInsets(top: 10, left: 10, bottom: 10, right: 10), animated: false)
                }
            }
        }
        
        return mapView
    }
}

extension AppDelegate: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        
        if overlay.isKindOfClass(MKPolygon) {
            // draw the track
            let polyLine = overlay
            let polyLineRenderer = MKPolygonRenderer(overlay: polyLine)
            polyLineRenderer.strokeColor = NSColor.blueColor()
            polyLineRenderer.lineWidth = 1.0
            
            return polyLineRenderer
        }
        
        return MKOverlayRenderer()
    }
}

/*
 *  ConnectedDriveDelegate
 */

extension AppDelegate: ConnectedDriveDelegate {
    
    func startedFetchingData() {
        
    }
    

    func finshedFetchingData() {
        
    }

    func shouldPresentLoginWindow() {
        closePopup(self)
        showLogin(self)
    }
    

    func didLogin() {
        closePopup(self)
        
        if vehicleList == nil {
            fetchVehicleList()
        }
    }
    
    func didLogout() {
        vehicleList = nil
        vehicle = nil
        vehicleStatus = nil
        rangeMap = nil
        
        removeTimer()
    }
}

/*
*  Login
*/

extension AppDelegate {
    
    func showLogin(sender: AnyObject?) {
        let loginViewController = LoginViewController(delegate: self)
        popup.contentViewController = loginViewController
        showPopup(sender)
    }
    
    func logout(sender: AnyObject?) {
        connectedDrive.logout(true)
    }
    
    func showPopup(sender: AnyObject?) {
        if let button = statusItem.button {
            popup.showRelativeToRect(button.bounds, ofView: button, preferredEdge: NSRectEdge.MinY)
        }
    }
    
    func closePopup(sender: AnyObject?) {
        popup.performClose(sender)
    }
}


/*
*  LoginDelegate
*/

extension AppDelegate: LoginDelegate {
    
    func userProvidedUsername(username: String, password: String) {

        // Hide window
        closePopup(self)
        
        // Update menu
        updateOnScreenStatus()
        
        connectedDrive.login(username, password: password) { result in
            self.updateOnScreenStatus()
        }
    }
}

extension AppDelegate: NSUserNotificationCenterDelegate {
    
    // Forces notification to always show
    func userNotificationCenter(center: NSUserNotificationCenter, shouldPresentNotification notification: NSUserNotification) -> Bool {
        return true
    }
}
