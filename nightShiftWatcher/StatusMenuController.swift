//
//  StatusMenuController.swift
//  nightShiftWatcher
//
//  Created by marco.massarotto on 02/11/2017.
//  Copyright © 2017 brokenmass. All rights reserved.
//

import Cocoa

class StatusMenuController: NSObject {
    @IBOutlet weak var statusMenu: NSMenu!

    var weatherMenuItem: NSMenuItem!
    var statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    var scriptObject : NSAppleScript!
    
    var screenCount: Int!;
    
    func setStatusIcon(image : NSImage) {
        image.isTemplate = true
        statusItem.image = image
    }
    
    func handleWorkspaceChange(incoming : Notification) -> Void {
        print("Received workspace change notification", incoming.name)
        
        if (screenCount > 1) {
            executeScript()
        }
    }
    
    func handleScreenChange(incoming : Notification) -> Void {
        print("Received screen change notification", incoming.name)
        let newScreenCount = NSScreen.screens.count
        if(newScreenCount != screenCount) {
            if (newScreenCount > screenCount) {
                executeScript()
            }
            screenCount = newScreenCount
        }
    }
    
    
    func executeScript() -> Void {
        print("Running screen reset");
        
        setStatusIcon(image: #imageLiteral(resourceName: "running"));
        
        var possibleError: NSDictionary?
        scriptObject?.executeAndReturnError(&possibleError)
        
        setStatusIcon(image: #imageLiteral(resourceName: "status"));
        
        if let error = possibleError {
            print("ERROR: \(error)")
        }
    }

    func acquirePrivileges() -> Void {
        let trusted = kAXTrustedCheckOptionPrompt.takeUnretainedValue()
        
        let privOptions = [trusted: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(privOptions as CFDictionary)
        
        if !accessEnabled {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "Enable NightShiftWatcher"
            alert.informativeText = "Once you have enabled NightShiftWatcher in System Preferences, click OK."
            alert.addButton(withTitle: "OK")
            print(alert.runModal())
            if !AXIsProcessTrustedWithOptions(privOptions as CFDictionary) {
                NSApp.terminate(self)
            }
        }
    }
    
    override func awakeFromNib() {
        acquirePrivileges()
        
        screenCount = NSScreen.screens.count;
        scriptObject = NSAppleScript(source: """
            tell application \"System Preferences\"
            activate
            set the current pane to pane id \"com.apple.preference.displays\"
            reveal anchor \"displaysNightShiftTab\" of pane id \"com.apple.preference.displays\"
            delay 1\n
            tell application \"System Events\" to tell application process \"System Preferences\"\n
            increment slider 1 of tab group 1 of window \"Built-in Retina Display\"\n
            decrement slider 1 of tab group 1 of window \"Built-in Retina Display\"\n
            end tell\n
            quit\n
            end tell
        """)
        
        statusItem.menu = statusMenu
        setStatusIcon(image: #imageLiteral(resourceName: "status"));
        
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification,
                                               object: nil,
                                               queue: OperationQueue.main,
                                               using: handleWorkspaceChange)
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.screensDidWakeNotification,
                                               object: nil,
                                               queue: OperationQueue.main,
                                               using: handleWorkspaceChange)
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.sessionDidBecomeActiveNotification,
                                               object: nil,
                                               queue: OperationQueue.main,
                                               using: handleWorkspaceChange)
        
        NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification,
                                               object: nil,
                                               queue: OperationQueue.main,
                                               using: handleScreenChange)
        
        if (screenCount > 1) {
            executeScript()
        }
        
        print("Application initialised")
        print("Screen count ", screenCount)
    }
    

    
    @IBAction func forceClicked(_ sender: Any) {
        executeScript()
    }
    
    @IBAction func quitClicked(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
    }
}
