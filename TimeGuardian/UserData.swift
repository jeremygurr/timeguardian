//
//  UserData.swift
//  Time Guardian
//
//  Created by Jeremy Gurr on 7/6/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import CoreData

class TestDataBuilder {
	let context: NSManagedObjectContext
	
	init(context: NSManagedObjectContext) {
		self.context = context
	}
	
	func save() {
		if context.hasChanges {
			do {
				try context.save()
			} catch {
				// Replace this implementation with code to handle the error appropriately.
				// fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
				let nserror = error as NSError
				fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
			}
		}
	}
	
	func createTestData() {
		deleteExistingData()
		createBudget(name: "Work")
		createBudget(name: "Home")
		createBudget(name: "Play")
		createBudget(name: "Sunday")
		save()
	}
	
	func deleteExistingData() {
		let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "TimeBudget")
		let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
		
		do {
			try context.execute(batchDeleteRequest)
		} catch {
			let nserror = error as NSError
			fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
		}
	}

	func createBudget(name: String) {
		let budget = TimeBudget(context: context)
		budget.name = name
	}
}
