//
//  AppDelegate.swift
//  LauncherApplication
//
//  Created by Fredrik Josefsson on 16/9/16.
//  Copyright © 2016 Fredrik Josefsson. All rights reserved.
//

import Cocoa
import ServiceManagement

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	
	func applicationDidFinishLaunching(aNotification: NSNotification) {
		
		let mainAppIdentifier = "com.superpanic.SuperCapsLock"
		
		let running = NSWorkspace.sharedWorkspace().runningApplications
		var alreadyRunning = false
		
		for app in running {
			print(app)
			if app.bundleIdentifier == mainAppIdentifier {
				alreadyRunning = true
				break
			}
		}
		
		if !alreadyRunning {
			NSDistributedNotificationCenter.defaultCenter().addObserver(self, selector: "terminate", name: "killme", object: mainAppIdentifier)
			let path = NSBundle.mainBundle().bundlePath as NSString
			var components = path.pathComponents
			print(components)
			components.removeLast()
			components.removeLast()
			components.removeLast()
			components.append("MacOS")
			components.append("SuperCapsLock")
			let newPath = NSString.pathWithComponents(components)
			NSWorkspace.sharedWorkspace().launchApplication(newPath)
		} else {
			self.terminate()
		}
	}
	
	func terminate() {
		NSApp.terminate(self)
	}

}

