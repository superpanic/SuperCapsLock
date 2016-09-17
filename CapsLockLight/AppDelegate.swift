//
//  AppDelegate.swift
//  SuperCapsLock
//
//  Created by Fredrik Josefsson on 29/8/16.
//  Copyright © 2016 Fredrik Josefsson. All rights reserved.
//

import Cocoa
import Carbon
import CoreServices
import ServiceManagement

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

//	@IBOutlet weak var window: NSWindow!
	
	@IBOutlet weak var window: NSWindow!
	@IBOutlet weak var menu: NSMenu!
	@IBOutlet weak var settingsWindow: NSWindow!
	
	@IBOutlet weak var lowLightSettingsSlider: NSSliderCell!
	@IBOutlet weak var highLightSettingsSlider: NSSliderCell!
	@IBOutlet weak var shiftIsActiveSettingsCheckBox: NSButtonCell!
	@IBOutlet weak var launchAtLoginCheckBox: NSButton!
	
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

		// read user settings
	let defaults = NSUserDefaults.standardUserDefaults()
	
	func applicationDidFinishLaunching(aNotification: NSNotification) {
		
			// user needs to set accessability privileges for this app
		acquirePrivileges()
		
		
		
		
			// launch at startup
		let launcherAppIdentifier = "com.superpanic.LauncherApplication"
		
		// you should move this next line to somehwre else, this is for testing purposes only!
		SMLoginItemSetEnabled(launcherAppIdentifier, true)
		
		var startedAtLogin = false
		for app in NSWorkspace.sharedWorkspace().runningApplications {
			if app.bundleIdentifier == launcherAppIdentifier {
				startedAtLogin = true
			}
		}

		if startedAtLogin {
			NSDistributedNotificationCenter.defaultCenter().postNotificationName("killme", object: NSBundle.mainBundle().bundleIdentifier!)
			print("Trying to kill the launcher app")
		}
		
		
		
		
		
		
			/* user defaults */
		
		print("User defaults: \(Array(defaults.dictionaryRepresentation().keys).count)")
		
			// remove all user defaults
		// let appDomain = NSBundle.mainBundle().bundleIdentifier!
		// defaults.removePersistentDomainForName(appDomain)

		print("User defaults: \(Array(defaults.dictionaryRepresentation().keys).count)")
		
			// read settings for high and low light
		var defInt : AnyObject?
		defInt = defaults.objectForKey("lowLightVal")
		
		//	let aoInt: AnyObject = Int(1) as NSNumber
		
		print("defInt: \(defInt?.integerValue)")
		if (defInt != nil) {
			lowLightVal = defInt!.integerValue
			lowLightSettingsSlider.integerValue = lowLightVal
		}
		
		defInt = defaults.objectForKey("highLightVal")

		print("defInt: \(defInt?.integerValue)")
		if (defInt != nil) {
			highLightVal = defInt!.integerValue
			highLightSettingsSlider.integerValue = highLightVal
		}

			// read settings for active shift key
		var defBool : AnyObject?
		defBool = defaults.objectForKey("shiftIsActive")
		// defBool = nil

		print("shiftIsActive: \(defBool?.boolValue)")
		if (defBool != nil) {
			shiftIsActive = defBool!.boolValue
			if(shiftIsActive) {
				shiftIsActiveSettingsCheckBox.state = NSOnState
			} else {
				shiftIsActiveSettingsCheckBox.state = NSOffState
			}
		}
		
		
		
		
		
		
		
			// setup the menu icon
		button = statusItem.button
		button.image = NSImage(named: "StatusItemIconOff")
		button.alternateImage = NSImage(named: "StatusItemIconOn")
		
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
		let lowLightValNum: AnyObject = Int(lowLightSettingsSlider.integerValue) as NSNumber
		defaults.setObject(lowLightValNum, forKey: "lowLightVal")
		lowLightVal = lowLightValNum.integerValue
		if( isCapsLockOn() == false ) { deactivateCapsLock() }
	}
	
	@IBAction func highLightSettingsSliderAdjusted(sender: AnyObject) {
		print("High light settings slider adjusted")
		let highLightValNum: AnyObject = Int(highLightSettingsSlider.integerValue) as NSNumber
		defaults.setObject(highLightValNum, forKey: "highLightVal")
		highLightVal = highLightValNum.integerValue
		if( isCapsLockOn() == true ) { activateCapsLock() }
	}
	
	@IBAction func shiftIsActiveSettingsClicked(sender: AnyObject) {
		print("Shift is active settings clicked")
		let shiftIsActiveSettingsCheckBoxNum: AnyObject = Int(shiftIsActiveSettingsCheckBox.state) as NSNumber
		defaults.setObject(shiftIsActiveSettingsCheckBoxNum, forKey: "shiftIsActive")
		shiftIsActive = (shiftIsActiveSettingsCheckBox.state > 0)
	}

	
	
	
	@IBAction func launchAtLoginCheckBoxClicked(sender: AnyObject) {
		print("Launch at login checked")
	}
	
	
	
	func isCapsLockOn() -> Bool {
		let eventModifier: UInt32 = GetCurrentKeyModifiers()
		return eventModifier == 1024
	}
	
	func activateCapsLock() {
		button.highlighted = true
		//button.state = NSOnState
		menu.itemWithTag(menuTags.SUPERCAPSLOCK.rawValue)?.setTitleWithMnemonic("CAPS LOCK ON&")
		print("highLightval: \(highLightVal)")
		keyboard_light.set(UInt64(highLightVal))
	}
	
	func deactivateCapsLock() {
		button.highlighted = false
		//button.state = NSOffState
		menu.itemWithTag(menuTags.SUPERCAPSLOCK.rawValue)?.setTitleWithMnemonic("Caps lock off&")
		print("lowLightVal: \(lowLightVal)")
		keyboard_light.set(UInt64(lowLightVal))
	}

	func capsLockOnEventLocal(event: NSEvent)->NSEvent {
			// is the keyboard event a Caps Lock event (Caps Lock is keyCode 57)
		if(event.keyCode == UInt16(kVK_CapsLock)) {
				// check if CAPS LOCK is turned on
			if event.modifierFlags.contains(.AlphaShiftKeyMask)		{ activateCapsLock() }
				// only deactivate keyboard light of caps lock is off
			else								{ deactivateCapsLock() }
		}
			// check if SHIFT key is pressed
		if(shiftIsActive && event.keyCode == UInt16(kVK_Shift)) {
				// check if SHIFT is turned on
			if event.modifierFlags.contains(.ShiftKeyMask)			{ activateCapsLock() }
				// only deactivate keyboard light of CAPS LOCK is off
			else if !(event.modifierFlags.contains(.AlphaShiftKeyMask))	{ deactivateCapsLock() }
		}
		return event
	}
	
	func capsLockOnEventGlobal(event: NSEvent) {
			// is the keyboard event a Caps Lock event (Caps Lock is keyCode 57)
		if(event.keyCode == UInt16(kVK_CapsLock)) {
			// check if Caps Lock is turned on
			if event.modifierFlags.contains(.AlphaShiftKeyMask)		{ activateCapsLock() }
			else								{ deactivateCapsLock() }
		}
			// shift key
		if(shiftIsActive && event.keyCode == UInt16(kVK_Shift)) {
			if event.modifierFlags.contains(.ShiftKeyMask)			{ activateCapsLock() }
			else if !(event.modifierFlags.contains(.AlphaShiftKeyMask))	{ deactivateCapsLock() }
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
