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
	
	// the status menu item
	let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSSquareStatusItemLength)
	
	// the menu
//	let menu = NSMenu()
	
	// tags used for the menu items
	enum menuTags: Int {
		case SUPERCAPSLOCK = 1
		case ABOUT
		case QUIT
	}
	
	// the menu icon
	var button: NSStatusBarButton!
	
	// keyboard light controller
	let keyboard_light = KeyboardBacklight()
	
	func applicationDidFinishLaunching(aNotification: NSNotification) {
		
		// user needs to set accessability privileges for this app
		acquirePrivileges()

		// setup the menu icon
		button = statusItem.button
		button.image = NSImage(named: "StatusItemIconBlk")
		
		menu.addItem( NSMenuItem(title: "Caps lock off", action: nil, keyEquivalent: ""))
		menu.itemAtIndex(menu.numberOfItems-1)?.tag = menuTags.SUPERCAPSLOCK.rawValue

		menu.addItem( NSMenuItem(title: "About SuperCapsLock", action: #selector(AppDelegate.openAboutWindow(_:)), keyEquivalent: "") )
		menu.itemAtIndex(menu.numberOfItems-1)?.tag = menuTags.ABOUT.rawValue
		
		menu.addItem( NSMenuItem.separatorItem() )
		menu.addItem( NSMenuItem(title: "Quit SuperCapsLock", action: #selector(AppDelegate.quit(_:)), keyEquivalent: "") )
		menu.itemAtIndex(menu.numberOfItems-1)?.tag = menuTags.QUIT.rawValue
		statusItem.menu = menu
		
		// turn on light if caps lock is already on
		if(isCapsLockOn()) {
			activateCapsLock()
		} else {
			deactivateCapsLock()
		}
		
		// set up listeners for local and global keyboard events
		NSEvent.addLocalMonitorForEventsMatchingMask(  NSEventMask.FlagsChangedMask, handler: capsLockOnEventLocal )
		NSEvent.addGlobalMonitorForEventsMatchingMask( NSEventMask.FlagsChangedMask, handler: capsLockOnEventGlobal )
	}

	func openAboutWindow(sender: AnyObject) {
		print("Open About window")
		window.setIsVisible(true)
		NSApp.activateIgnoringOtherApps(true)
	}
	
	func quit(sender: AnyObject) {
		print("Quit application")
		NSApp.terminate(self)
	}

	func isCapsLockOn() -> Bool {
		let eventModifier: UInt32 = GetCurrentKeyModifiers()
		return eventModifier == 1024
	}
	
	func activateCapsLock() {
		button.highlighted = true
		menu.itemWithTag(menuTags.SUPERCAPSLOCK.rawValue)?.setTitleWithMnemonic("CAPS LOCK ON&")
		keyboard_light.set(UInt64(0xfff))
	}
	
	func deactivateCapsLock() {
		button.highlighted = false
		menu.itemWithTag(menuTags.SUPERCAPSLOCK.rawValue)?.setTitleWithMnemonic("Caps lock off&")
		keyboard_light.set(0)
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
