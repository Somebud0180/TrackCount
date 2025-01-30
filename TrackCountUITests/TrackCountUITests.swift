//
//  TrackCountUITests.swift
//  TrackCountUITests
//
//  A UI test including sequences for guides
//

import XCTest
import SwiftUI
import SwiftData
@testable import TrackCount

@MainActor
final class TrackCountUITests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testGuideSequence() throws {
        try testCreateGroupSequence()
        try testAddCardSequence()
    }

    func testCreateGroupSequence() throws {
        // Launch the application
        let app = XCUIApplication()
        app.launch()
        
        // Create a group
        let startButton = app.buttons["Track It"]
        XCTAssertTrue(startButton.exists, "Track It button should exist")
        startButton.tap()
        
        let ellipsisButton = app.buttons["Ellipsis Button"]
        XCTAssertTrue(ellipsisButton.exists, "Ellipsis Menu button should exist")
        ellipsisButton.tapUnhittable()
        
        sleep(1)
        let addGroupOption = app.buttons["Add Group"]
        XCTAssertTrue(addGroupOption.exists, "Add Group option should exist in the Menu")
        addGroupOption.tap()
        
        sleep(1)
        let groupSymbolButton = app.buttons["Group Smybol Picker"]
        XCTAssertTrue(groupSymbolButton.exists, "Group Symbol button should exist")
        groupSymbolButton.tap()
        
        sleep(1)
        app.swipeUp()
        let groupSymbolExample = app.images["person.circle"]
        XCTAssertTrue(groupSymbolExample.exists, "Group Symbol example should exist")
        groupSymbolExample.tap()
        
        sleep(1)
        let saveButton = app.buttons["Add Group"]
        XCTAssertTrue(saveButton.exists, "Save button should exist")
        saveButton.tap()
        
        sleep(1)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        
        sleep(3)
    }
    
    func testAddCardSequence() throws {
        // Launch the application
        let app = XCUIApplication()
        app.launch()
        
        // Create a group
        let startButton = app.buttons["Track It"]
        XCTAssertTrue(startButton.exists, "Track It button should exist")
        startButton.tap()
        
        let navigationButton = app.buttons["person.circle"]
        XCTAssertTrue(navigationButton.exists, "Navigation button should exist")
        navigationButton.tap()
        
        sleep(1)
        let ellipsisButton = app.buttons["Ellipsis Button"]
        XCTAssertTrue(ellipsisButton.exists, "Ellipsis Menu button should exist")
        ellipsisButton.tapUnhittable()
        
        sleep(1)
        let addGroupOption = app.buttons["Add Card"]
        XCTAssertTrue(addGroupOption.exists, "Add Card option should exist in the Menu")
        addGroupOption.tap()
        
        sleep(1)
        app.swipeUp()
        let titleTextField = app.textFields["Card Title Field"]
        XCTAssertTrue(titleTextField.exists, "Text Field should exist")
        titleTextField.tap()
        titleTextField.typeText(String("Wins"))
        
        sleep(1)
        let saveButton = app.buttons["Add Card"]
        XCTAssertTrue(saveButton.exists, "Save button should exist")
        saveButton.tap()
        
        sleep(1)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        
        sleep(1)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        
        sleep(3)
    }
    
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}

// From https://stackoverflow.com/a/62395465
extension XCUIElement {
    func tapUnhittable() {
        XCTContext.runActivity(named: "Tap \(self) by coordinate") { _ in
            coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }
}
