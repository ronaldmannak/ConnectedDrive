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

enum FetchInterval: TimeInterval {
    case regular    = 600 // 10 minutes
    case often      = 60  // 1 minute
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    
    let statusItem = NSStatusBar.system().statusItem(withLength: -2)
    let popup = NSPopover()
    var eventMonitor: EventMonitor?
    let connectedDrive = ConnectedDrive()
    var timer: Timer?
    
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
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
//        connectedDrive.deleteStoredItems() // For debug purposes only
        connectedDrive.delegate = self
        
        // Register for sleep and wake notifications
        NSWorkspace.shared().notificationCenter.addObserver(self, selector: #selector(AppDelegate.wakeNotification(_:)), name: NSNotification.Name.NSWorkspaceDidWake, object: nil)
        NSWorkspace.shared().notificationCenter.addObserver(self, selector: #selector(AppDelegate.sleepNotification(_:)), name: NSNotification.Name.NSWorkspaceWillSleep, object: nil)
        
        // Create EventMonitor to hide popup windows when user clicks elsewhere on the screen
        eventMonitor = EventMonitor(mask: NSEventMask.leftMouseDown) { [unowned self] event in
            if self.popup.isShown {
                self.closePopup(event)
            }
        }
        eventMonitor?.start()
        
        connectedDrive.autoLogin { result in
            self.updateOnScreenStatus()
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        NSWorkspace.shared().notificationCenter.removeObserver(self)
    }
    

    func wakeNotification(_ notification: Notification) {
        connectedDrive.autoLogin { result in
            self.createTimer(.regular)
        }
    }
    
    func sleepNotification(_ notification: Notification) {
        removeTimer()
    }
}

/*
 *  Fetch status
 */

extension AppDelegate {
    
    func createTimer(_ interval: FetchInterval) {

        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: interval.rawValue, target: self, selector: #selector(AppDelegate.fetchStatusFromServer), userInfo: nil, repeats: true)
        timer?.fire()
    }
    
    func removeTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func fetchVehicleList() {
        
        self.connectedDrive.vehicles { result in
            
            switch result {
            case .success(let vehicles):
                
                self.vehicleList = vehicles
                self.vehicle = vehicles.first
                
                self.createTimer(.regular) // Timer fetches vehicle status immediately
                
            case .failure(let error):
                // TODO:
                self.showNotification("\(error.code) " + error.localizedDescription, text: error.localizedFailureReason)
            }
            
        }
    }
    
    func fetchStatusFromServer() {
        
        guard let vehicle = vehicle else {
            return
        }
        
        connectedDrive.vehicleStatus(vehicle) { status in
            
            switch status {
            case .success(let status):
                
                if let previousVehicleStatus = self.vehicleStatus where previousVehicleStatus.updateReason.rawValue != status.updateReason.rawValue {
    
                    // Received a new update reason, show banner to notify user
                    let timeFormat = DateFormatter()
                    timeFormat.dateFormat = "h:mm a"
                    let timeStamp = timeFormat.string(from: status.updateTime)
                
                    self.showNotification(status.updateReason.description + " " + timeStamp, text: NSLocalizedString("Previous: ", comment: "") + previousVehicleStatus.updateReason.description)
                }
                
                self.vehicleStatus = status
                
                // Fetch rangemap
                self.connectedDrive.rangeMap(vehicle) { map in
                    
                    switch map {
                    case .success(let rangeMap):
                        
                        self.rangeMap = rangeMap
                        
                    case .failure(let error):
                        
                        self.showNotification("\(error.code) " + error.localizedDescription, text: error.localizedFailureReason)
                    }
                }

            case .failure(let error):
                
                self.showNotification("\(error.code) " + error.localizedDescription, text: error.localizedFailureReason)
                
                self.updateLabel("x", color: NSColor.red())
            }
        }
    }
    
    func clearVehicleCache() {
        vehicleList = nil
        vehicle = nil
        vehicleStatus = nil
        rangeMap = nil
    }
    
    func selectVehicleMenuAction(_ sender: AnyObject) {
        guard let menuItem = sender as? NSMenuItem, vehicleList = vehicleList where menuItem.tag < vehicleList.count else {
            return
        }
        selectVehicle(vehicleList[menuItem.tag])
    }
    
    func selectVehicle(_ vehicle: Vehicle) {
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
                color = NSColor.green()
            } else if status.chargingStatus == .Charging {
                color = NSColor.blue()
            } else if percentage <= 5 {
                color = NSColor.red()
            } else {
                color = NSColor.black()
            }
            updateLabel("\(percentage)" + (percentage == 100 ? "" : "%"), color: color)
            
        } else {
            
            updateLabel("...", color: NSColor.gray())
        }
        
        updateMenu()
    }
    
    func updateLabel(_ percentage: String, color: NSColor) {
        
        guard let button = statusItem.button else { return }
        
        let title = AttributedString(string: percentage, attributes: [NSForegroundColorAttributeName: color])
        button.attributedTitle = title
    }
    
    func updateMenu() {
        
        let menu: NSMenu
        switch connectedDrive.state {
        case .loggedIn:
            menu = createLoggedInMenu()
        case .loggedOut:
            menu = createLoggedOutMenu()
        case .loggingIn:
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
        let timeFormat = DateFormatter()
        timeFormat.dateFormat = "h:mm a"
        _ = menu.addItem(withTitle: status.updateReason.description + NSLocalizedString(" at ", comment: "") + timeFormat.string(from: status.updateTime), action: nil, keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        
        // If charging, add estimated time until full
        if status.chargingTimeRemaining != nil {
            menu.addItem(withTitle: "Time until full: \(status.chargingTimeRemainingString)", action: nil, keyEquivalent: "")
        }
        
        // Range
        menu.addItem(withTitle: "Range: \(status.remainingRangeMi) miles", action: nil, keyEquivalent: "")
        
        // Doors and windows
        menu.addItem(withTitle: NSLocalizedString("Doors:", comment: "") + " " + status.doorLockState.description, action: nil, keyEquivalent: "")
        menu.addItem(withTitle: NSLocalizedString("Windows:", comment: "") + " " + status.windowState.description, action: nil, keyEquivalent: "")
        
        // Update Now
        menu.addItem(withTitle: NSLocalizedString("Update now", comment: "") + " (last update \(timeFormat.string(from: status.fetchTime)))", action: #selector(AppDelegate.fetchStatusFromServer), keyEquivalent: "u")

        menu.addItem(NSMenuItem.separator())

        // Vehicle location
        if let location = status.location {

            let vehicleLocationItem = NSMenuItem(title: NSLocalizedString("Vehicle location", comment: ""), action: #selector(AppDelegate.viewVehicleLocation(_:)), keyEquivalent: "l")
            menu.addItem(vehicleLocationItem)

            let vehicleLocationSubmenu = NSMenu()
            let mapItem = NSMenuItem()

            mapItem.view = createMapView(location)
            vehicleLocationSubmenu.addItem(mapItem)
            vehicleLocationItem.submenu = vehicleLocationSubmenu
        }
        
        // Range map
        if let rangeMap = rangeMap {

            let rangeItem = NSMenuItem(title: NSLocalizedString("Range map", comment: ""), action: #selector(AppDelegate.viewRange(_:)), keyEquivalent: "r")
            menu.addItem(rangeItem)
            menu.addItem(NSMenuItem.separator())

            let rangeSubmenu = NSMenu()
            let rangeMapItem = NSMenuItem()

            rangeMapItem.view = createMapView(rangeMap: rangeMap)
            rangeSubmenu.addItem(rangeMapItem)
            rangeItem.submenu = rangeSubmenu
        } else {
            menu.addItem(withTitle: NSLocalizedString("Range map is loading...", comment: ""), action: nil, keyEquivalent: "")
        }
        
        // Command submenu
        let commandItem = NSMenuItem(title: NSLocalizedString("Send command", comment: ""), action: nil, keyEquivalent: "")
        let commandSubmenu = createCommandMenu()
        commandItem.submenu = commandSubmenu
        menu.addItem(commandItem)
        
        // Quit
        if menu.items.last != NSMenuItem.separator() {
            menu.addItem(NSMenuItem.separator())
        }
        menu.addItem(withTitle: NSLocalizedString("Log out", comment: ""), action: #selector(AppDelegate.logout(_:)), keyEquivalent: "l")
        menu.addItem(withTitle: NSLocalizedString("Quit", comment: ""), action: #selector(quitApp(_:)), keyEquivalent: "q")
        return menu
    }

    func createLoggedOutMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(withTitle: "Login", action: #selector(AppDelegate.showLogin(_:)), keyEquivalent: "l")
        
        // Quit
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: NSLocalizedString("Quit", comment: ""), action: #selector(quitApp(_:)), keyEquivalent: "q"))
        return menu
    }
    
    func createLoggingInMenu() -> NSMenu {
        
        let menu = NSMenu()
        menu.addItem(withTitle: NSLocalizedString("Logging in...", comment: ""), action: nil, keyEquivalent: "")
        
        // Quit
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: NSLocalizedString("Quit", comment: ""), action: #selector(quitApp(_:)), keyEquivalent: "q"))
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
            let item = NSMenuItem(title: title, action: #selector(AppDelegate.selectVehicleMenuAction(_:)), keyEquivalent: "")
            item.tag = i
            menu.addItem(item)
        }
        return menu
    }
    
    func createCommandMenu() -> NSMenu {
        
        let menu = NSMenu()
        
        // Horn
        let hornItem = NSMenuItem(title: NSLocalizedString("Horn", comment: ""), action: #selector(AppDelegate.hornBlow(_:)), keyEquivalent: "h")
        menu.addItem(hornItem)
        
        // Flash Headlights
        let flashHeadlights = NSMenuItem(title: NSLocalizedString("Flash headlights", comment: ""), action: #selector(AppDelegate.flashHeadlights(_:)), keyEquivalent: "f")
        menu.addItem(flashHeadlights)
        
        // Lock doors
        let lockDoorsItem = NSMenuItem(title: NSLocalizedString("Lock doors", comment: ""), action: #selector(AppDelegate.lockDoors(_:)), keyEquivalent: "l")
        menu.addItem(lockDoorsItem)
        
        return menu
    }
}

/*
 *  Commands
 */

extension AppDelegate {
    
    func hornBlow(_ sender: AnyObject) {
        sendCommand(.HornBlow)
    }
    
    func flashHeadlights(_ sender: AnyObject) {
        sendCommand(.LightFlash)
    }
    
    func lockDoors(_ sender: AnyObject) {
        sendCommand(.DoorLock)
    }
    
    func sendCommand(_ service: VehicleService) {
        guard let vehicle = vehicle else { return }
        connectedDrive.executeCommand(vehicle, service: service) { result in
            
            switch result {
            case .failure(let error):
                print (error)
            case .success(let status):
                print(status)
            }
        }
    }
}

/*
 *  Maps
 */

extension AppDelegate {
    
    // Empty methods to force view vehicle menu item to become active
    func viewVehicleLocation(_ sender: AnyObject?) {}
    
    func viewRange(_ sender: AnyObject?) {}
    
    func createMapView(_ pinLocation: CLLocation? = nil, rangeMap: RangeMap? = nil) -> MKMapView {
        
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
                mapView.add(polygon, level: .aboveRoads)
                
                // Make sure all ranges fit in window
                if polyLineStruct.type == .EcoProPlus {
                    mapView.setVisibleMapRect(polygon.boundingMapRect, edgePadding: EdgeInsets(top: 10, left: 10, bottom: 10, right: 10), animated: false)
                }
            }
        }
        
        return mapView
    }
}

extension AppDelegate: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        if overlay is MKPolygon {
            // draw the track
            let polyLine = overlay
            let polyLineRenderer = MKPolygonRenderer(overlay: polyLine)
            polyLineRenderer.strokeColor = NSColor.blue()
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
    
    func showLogin(_ sender: AnyObject?) {
        let loginViewController = LoginViewController(delegate: self)
        popup.contentViewController = loginViewController
        showPopup(sender)
    }
    
    func logout(_ sender: AnyObject?) {
        connectedDrive.logout(true)
    }
    
    func showPopup(_ sender: AnyObject?) {
        if let button = statusItem.button {
            popup.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
    }
    
    func closePopup(_ sender: AnyObject?) {
        popup.performClose(sender)
    }
    
    func quitApp(_ sender: AnyObject?) {
        NSApplication.shared().terminate(self)
    }
}


/*
*  LoginDelegate
*/

extension AppDelegate: LoginDelegate {
    
    func userProvidedUsername(_ username: String, password: String) {

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
    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }
}

/*
 *  Notifications
 */

extension AppDelegate {
    
    func showNotification(_ title: String?, text: String?) {
        let notification = NSUserNotification()
        notification.title = title ?? nil
        notification.informativeText = text ?? nil
        NSUserNotificationCenter.default.delegate = self
        NSUserNotificationCenter.default.deliver(notification)
    }
}
