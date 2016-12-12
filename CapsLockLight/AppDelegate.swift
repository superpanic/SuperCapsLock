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

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

//	@IBOutlet weak var window: NSWindow!
	
	@IBOutlet weak var window: NSWindow!
	@IBOutlet weak var menu: NSMenu!
	@IBOutlet weak var settingsWindow: NSWindow!
	@IBOutlet weak var indicatorWindow: NSWindow!
	
	@IBOutlet weak var lowLightSettingsSlider: NSSliderCell!
	@IBOutlet weak var highLightSettingsSlider: NSSliderCell!
	@IBOutlet weak var shiftIsActiveSettingsCheckBox: NSButtonCell!
	@IBOutlet weak var launchAtLoginSettingsCheckBox: NSButton!
	@IBOutlet weak var greenScreenSettingsCheckBox: NSButton!
	
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
	
		// loginItemsManager
	let loginItemsManager = LoginItemsManager()
	
	var highLightVal: Int = 0xfff
	var lowLightVal: Int = 0x0
	var shiftIsActive: Bool = false
	var launchAtLogin: Bool = false
	var greenIndicatorIsActive: Bool = false

		// read user settings
	let defaults = NSUserDefaults.standardUserDefaults()
	
	func applicationDidFinishLaunching(aNotification: NSNotification) {
		
			// user needs to set accessability privileges for this app
		assert(acquirePrivileges())
		
		
		
			/* user defaults */
		
		print("User defaults: \(Array(defaults.dictionaryRepresentation().keys).count)")
		
			// remove all user defaults
//		let appDomain = NSBundle.mainBundle().bundleIdentifier!
//		defaults.removePersistentDomainForName(appDomain)
		

		print("User defaults: \(Array(defaults.dictionaryRepresentation().keys).count)")
		
			// read settings for high and low light
		var defInt : AnyObject?
		defInt = defaults.objectForKey("lowLightVal")
		
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

		print("shiftIsActive: \(defBool?.boolValue)")
		if (defBool != nil) {
			shiftIsActive = defBool!.boolValue
			if(shiftIsActive) {
				shiftIsActiveSettingsCheckBox.state = NSOnState
			} else {
				shiftIsActiveSettingsCheckBox.state = NSOffState
			}
		}
		
			// read settings for green indicator
		defBool = defaults.objectForKey("greenIndicator")
		print("greenIndicator: \(defBool?.boolValue)")
		if(defBool != nil) {
			greenIndicatorIsActive = defBool!.boolValue
			if(greenIndicatorIsActive) {
				greenScreenSettingsCheckBox.state = NSOnState
			} else {
				greenScreenSettingsCheckBox.state = NSOffState
			}
		}
		
			// read settings for start at login
		defBool = defaults.objectForKey("launchAtLogin")
		print("launchAtLogin: \(defBool?.launchAtLogin)")
		if (defBool != nil) {
			launchAtLogin = defBool!.boolValue
			if(launchAtLogin) {
				launchAtLoginSettingsCheckBox.state = NSOnState
				if !loginItemsManager.startAtLogin { loginItemsManager.toggleStartAtLogin() }
			} else {
				launchAtLoginSettingsCheckBox.state = NSOffState
				if loginItemsManager.startAtLogin { loginItemsManager.toggleStartAtLogin() }
			}
		}
		
		
/*
if(loginItemsManager.startAtLogin) {
loginItemsManager.toggleStartAtLogin()
}
*/


		indicatorWindow.alphaValue = 0.2
		let col = NSColor.greenColor()
		indicatorWindow.backgroundColor = col

		let f1:NSRect = NSScreen.mainScreen()!.frame

/* use this for a green border at bottom of screen
		let f2:NSRect = NSRect.init(x: f1.minX, y: f1.minY, width: f1.maxX, height: f1.height/20)
		indicatorWindow.setFrame(f2, display: true)
*/
		
// use this for full screen green indicator
		indicatorWindow.setFrame(f1, display: true)

		
		indicatorWindow.ignoresMouseEvents = true

		indicatorWindow.level = Int(CGWindowLevelForKey(.FloatingWindowLevelKey))
		indicatorWindow.level = Int(CGWindowLevelForKey(.MaximumWindowLevelKey))
		
		
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
		NSEvent.addLocalMonitorForEventsMatchingMask(NSEventMask.FlagsChanged, handler: capsLockOnEventLocal )
		NSEvent.addGlobalMonitorForEventsMatchingMask(NSEventMask.FlagsChanged, handler: capsLockOnEventGlobal )
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
		let checkBoxState: AnyObject = Int(shiftIsActiveSettingsCheckBox.state) as NSNumber
		defaults.setObject(checkBoxState, forKey: "shiftIsActive")
		shiftIsActive = (shiftIsActiveSettingsCheckBox.state > 0)
	}
	
	@IBAction func launchAtLoginSettingsClicked(sender: AnyObject) {
		print("Launch at login settings clicked")
		let checkBoxState: AnyObject = Int(launchAtLoginSettingsCheckBox.state) as NSNumber
		defaults.setObject(checkBoxState, forKey: "launchAtLogin")
		if(checkBoxState.intValue > 0) {
				// turn on
			if !loginItemsManager.startAtLogin { loginItemsManager.toggleStartAtLogin() }
		} else {
				// turn off
			if loginItemsManager.startAtLogin { loginItemsManager.toggleStartAtLogin() }
		}
	}
	
	@IBAction func greenScreenSettingsClicked(sender: AnyObject) {
		print("Green screen settings clicked")
		let checkBoxState: AnyObject = Int(greenScreenSettingsCheckBox.state) as NSNumber
		defaults.setObject(checkBoxState, forKey: "greenIndicator")
		greenIndicatorIsActive = (greenScreenSettingsCheckBox.state > 0)
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
		if(greenIndicatorIsActive) { indicatorWindow.setIsVisible(true) };
	}
	
	func deactivateCapsLock() {
		button.highlighted = false
		//button.state = NSOffState
		menu.itemWithTag(menuTags.SUPERCAPSLOCK.rawValue)?.setTitleWithMnemonic("Caps lock off&")
		print("lowLightVal: \(lowLightVal)")
		keyboard_light.set(UInt64(lowLightVal))
		indicatorWindow.setIsVisible(false);
	}

	func capsLockOnEventLocal(event: NSEvent)->NSEvent {
			// is the keyboard event a Caps Lock event (Caps Lock is keyCode 57)
		if(event.keyCode == UInt16(kVK_CapsLock)) {
				// check if CAPS LOCK is turned on
			if event.modifierFlags.contains(.CapsLock)		{ activateCapsLock() }
				// only deactivate keyboard light of caps lock is off
			else								{ deactivateCapsLock() }
		}
			// check if SHIFT key is pressed
		if(shiftIsActive && event.keyCode == UInt16(kVK_Shift)) {
				// check if SHIFT is turned on
			if event.modifierFlags.contains(.Shift)			{ activateCapsLock() }
				// only deactivate keyboard light of CAPS LOCK is off
			else if !(event.modifierFlags.contains(.CapsLock))	{ deactivateCapsLock() }
		}
		return event
	}
	
	func capsLockOnEventGlobal(event: NSEvent) {
			// is the keyboard event a Caps Lock event (Caps Lock is keyCode 57)
		if(event.keyCode == UInt16(kVK_CapsLock)) {
			// check if Caps Lock is turned on
			if event.modifierFlags.contains(.CapsLock)		{ activateCapsLock() }
			else								{ deactivateCapsLock() }
		}
			// shift key
		if(shiftIsActive && event.keyCode == UInt16(kVK_Shift)) {
			if event.modifierFlags.contains(.Shift)			{ activateCapsLock() }
			else if !(event.modifierFlags.contains(.CapsLock))	{ deactivateCapsLock() }
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
