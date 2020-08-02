//
//  FundListView.swift
//  TimeGuardian
//
//  Created by Jeremy Gurr on 7/16/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//

import SwiftUI
import Combine

struct FundListView: View {
	@Environment(\.editMode) var editMode
	@Environment(\.managedObjectContext) var managedObjectContext
	@EnvironmentObject var budgetStack: BudgetStack
	@FetchRequest var availableFunds: FetchedResults<TimeFund>
	@FetchRequest var spentFunds: FetchedResults<TimeFund>
	@FetchRequest var allFunds: FetchedResults<TimeFund>
	@State var newFundTop = ""
	@State var newFundBottom = ""
	@State var action: FundAction = .spend
	let appState: AppState

	init(budgetStack: BudgetStack, appState: AppState) {
		let budget = budgetStack.getTopBudget()
		_availableFunds = TimeFund.fetchAvailableRequest(budget: budget)
		_spentFunds = TimeFund.fetchSpentRequest(budget: budget)
		_allFunds = TimeFund.fetchAllRequest(budget: budget)
		self.appState = appState
	}
	
	var body: some View {
		VStack {
			MultiRowSegmentedPickerView(
				choices: FundAction.allCasesInRows,
				selectedIndex: self.$action,
				onChange: { (newValue: FundAction) in
					if newValue == .edit {
						self.editMode?.wrappedValue = .active
					} else {
						self.editMode?.wrappedValue = .inactive
						UIApplication.shared.endEditing(true)
					}
			}
			)
			Text(budgetStack.actionDetail)
				.font(.body)
			List {
				if self.action.canApplyToAll {
					FundAllRowView(
						allFunds: self.allFunds,
						action: self.$action,
						appState: self.appState
					)
				}
				FundSectionAvailableView(
					availableFunds: self.availableFunds,
					allFunds: self.allFunds,
					newFundTop: self.$newFundTop,
					newFundBottom: self.$newFundBottom,
					action: self.$action,
					appState: self.appState
				)
				FundSectionSpentView(
					spentFunds: self.spentFunds,
					allFunds: self.allFunds,
					action: self.$action,
					appState: self.appState
				)
				Text("").frame(height: listViewExtension)
			}
		}
	}
}

func fundInsets() -> EdgeInsets {
	return EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 20)
}

struct FundSectionAvailableView: View {
	var availableFunds: FetchedResults<TimeFund>
	var allFunds: FetchedResults<TimeFund>
	@Binding var newFundTop: String
	@Binding var newFundBottom: String
	@Binding var action : FundAction
	@Environment(\.editMode) var editMode
	@Environment(\.managedObjectContext) var managedObjectContext
	@EnvironmentObject var budgetStack: BudgetStack
	let appState: AppState

	var body: some View {
		Section(header: Text("Available")) {
			if self.editMode?.wrappedValue == .inactive {
				NewFundRowView(newFundName: $newFundTop, funds: availableFunds, posOfNewFund: .before)
			}
			ForEach(availableFunds, id: \.self) { fund in
				FundRowView(action: self.$action, fund: ObservedObject(initialValue: fund), funds: self.allFunds, appState: self.appState)
			}
			.onMove() { (source: IndexSet, destination: Int) in
				debugLog("FundListView.onMove")

				var newFunds: [TimeFund] = self.availableFunds.map() { $0 }
				newFunds.move(fromOffsets: source, toOffset: destination)
				for (index, fund) in newFunds.enumerated() {
					fund.order = Int16(index)
				}
				saveData(self.managedObjectContext)
			}
			.listRowInsets(fundInsets())
			if self.editMode?.wrappedValue == .inactive {
				NewFundRowView(newFundName: $newFundBottom, funds: availableFunds, posOfNewFund: .after)
			}
		}
	}
}

struct FundSectionSpentView: View {
	var spentFunds: FetchedResults<TimeFund>
	var allFunds: FetchedResults<TimeFund>
	@Binding var action : FundAction
	@Environment(\.managedObjectContext) var managedObjectContext
	@EnvironmentObject var budgetStack: BudgetStack
	let appState: AppState

	var body: some View {
		Section(header: Text("Spent")) {
			if self.action.canApplyToAll {
				FundAllSpentRowView(spentFunds: self.spentFunds, action: self.$action, appState: self.appState)
			}
			ForEach(self.spentFunds, id: \.self) { fund in
				FundRowView(action: self.$action, fund: ObservedObject(initialValue: fund), funds: self.allFunds, appState: self.appState)
			}.onMove() { (source: IndexSet, destination: Int) in
				var newFunds: [TimeFund] = self.spentFunds.map() { $0 }
				newFunds.move(fromOffsets: source, toOffset: destination)
				for (index, fund) in newFunds.enumerated() {
					fund.order = Int16(index)
				}
				saveData(self.managedObjectContext)
			}.listRowInsets(fundInsets())
		}
	}
}

struct FundListView_Previews: PreviewProvider {
	static var previews: some View {
		let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
		let testDataBuilder = TestDataBuilder(context: context)
		testDataBuilder.createTestData()
		let appState = AppState()
		let budget = testDataBuilder.budgets.first!
		let budgetStack = BudgetStack()
		budgetStack.push(budget: budget)
		return FundListView(budgetStack: budgetStack, appState: appState)
			.environment(\.managedObjectContext, context)
			.environmentObject(budgetStack)
//			.environment(\.colorScheme, .dark)
	}
}
