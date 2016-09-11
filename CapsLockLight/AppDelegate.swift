//
//  AppDelegate.swift
//  SuperCapsLock
//
//  Created by Fredrik Josefsson on 29/8/16.
//  Copyright © 2016 Fredrik Josefsson. All rights reserved.
//

import Cocoa
import Carbon

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

//	@IBOutlet weak var window: NSWindow!
	
	@IBOutlet weak var window: NSWindow!
	@IBOutlet weak var menu: NSMenu!
	@IBOutlet weak var settingsWindow: NSWindow!
	
	@IBOutlet weak var lowLightSettingsSlider: NSSliderCell!
	@IBOutlet weak var highLightSettingsSlider: NSSliderCell!
	@IBOutlet weak var shiftIsActiveSettingsCheckBox: NSButtonCell!
	
	
	// the status menu item
	let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSSquareStatusItemLength)
	
	// tags used for the menu items
	enum menuTags: Int {
		case SUPERCAPSLOCK = 1
		case ABOUT
		case QUIT
		case SETTINGS
	}
	
	// the menu icon
	var button: NSStatusBarButton!
	
	// keyboard light controller
	let keyboard_light = KeyboardBacklight()
	
	var highLightVal: Int = 0xfff
	var lowLightVal: Int = 0x0
	var shiftIsActive: Bool = false
	
	func applicationDidFinishLaunching(aNotification: NSNotification) {
		
		// user needs to set accessability privileges for this app
		acquirePrivileges()
		
		
		// read user settings
		let defaults = NSUserDefaults.standardUserDefaults()
		
		// read settings for high and low light
		var defInt : Int?
		
		defInt = defaults.integerForKey("lowLightVal")
		if (defInt != nil) {
			lowLightVal = defInt!
			
		}
		
		defInt = defaults.integerForKey("highLoghtVal")
		if (defInt != nil) { highLightVal = defInt! }
		

		// read settings for active shift key
		var defBool : Bool?

		defBool = defaults.boolForKey("shiftIsActive")
		if (defBool != nil) { shiftIsActive = defBool! }
		
		

		
		// setup the menu icon
		button = statusItem.button
		button.image = NSImage(named: "StatusItemIconBlk")
		
		// set the status menu
		statusItem.menu = menu
		
		// turn on light if caps lock is already on
		if( isCapsLockOn() )	{ activateCapsLock() }
		else			{ deactivateCapsLock() }
		
		// set up listeners for local and global keyboard events
		NSEvent.addLocalMonitorForEventsMatchingMask(  NSEventMask.FlagsChangedMask, handler: capsLockOnEventLocal )
		NSEvent.addGlobalMonitorForEventsMatchingMask( NSEventMask.FlagsChangedMask, handler: capsLockOnEventGlobal )
	}

	@IBAction func openAboutWindow(sender: AnyObject) {
		print("Open About window")
		window.setIsVisible(true)
		NSApp.activateIgnoringOtherApps(true)
	}
	
	@IBAction func quit(sender: AnyObject) {
		print("Quit application")
		NSApp.terminate(self)
	}
	
	@IBAction func openSettingsWindow(sender: AnyObject) {
		print("Open Settings window")
		settingsWindow.setIsVisible(true)
		NSApp.activateIgnoringOtherApps(true)
	}
	
	@IBAction func lowLightSettingsSliderAdjusted(sender: AnyObject) {
		print("Low light settings slider adjusted")
	}
	
	@IBAction func highLightSettingsSliderAdjusted(sender: AnyObject) {
		print("High light settings slider adjusted")
	}
	
	@IBAction func shiftIsActiveSettingsClicked(sender: AnyObject) {
		print("Shift is active settings clicked")
	}

	func isCapsLockOn() -> Bool {
		let eventModifier: UInt32 = GetCurrentKeyModifiers()
		return eventModifier == 1024
	}
	
	func activateCapsLock() {
		button.highlighted = true
		menu.itemWithTag(menuTags.SUPERCAPSLOCK.rawValue)?.setTitleWithMnemonic("CAPS LOCK ON&")
		keyboard_light.set(UInt64(highLightVal))
	}
	
	func deactivateCapsLock() {
		button.highlighted = false
		menu.itemWithTag(menuTags.SUPERCAPSLOCK.rawValue)?.setTitleWithMnemonic("Caps lock off&")
		keyboard_light.set(UInt64(lowLightVal))
	}

	func capsLockOnEventLocal(event: NSEvent)->NSEvent {
		// is the keyboard event a Caps Lock event (Caps Lock is keyCode 57)
		if(event.keyCode == UInt16(kVK_CapsLock)) {
			// check if Caps Lock is turned on
			if event.modifierFlags.contains(.AlphaShiftKeyMask)	{ activateCapsLock() }
			else							{ deactivateCapsLock() }
		}
		return event
	}
	
	func capsLockOnEventGlobal(event: NSEvent) {
		// is the keyboard event a Caps Lock event (Caps Lock is keyCode 57)
		if(event.keyCode == UInt16(kVK_CapsLock)) {
			// check if Caps Lock is turned on
			if event.modifierFlags.contains(.AlphaShiftKeyMask)	{ activateCapsLock() }
			else							{ deactivateCapsLock() }
		}
		
	}

	func acquirePrivileges() -> Bool {
		// check if we have accessability privileges
		let accessEnabled = AXIsProcessTrustedWithOptions( [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] )
		return accessEnabled == true
	}
	
	func applicationWillTerminate(aNotification: NSNotification) {
		// Insert code here to tear down your application
	}

}
