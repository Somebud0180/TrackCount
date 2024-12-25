// TrackCountUITests.swift
// TrackCountUITests
//
// Created by Ethan John Lagera on 11/20/24.

import XCTest

final class TrackCountUITests: XCTestCase {
    
    override func setUpWithError() throws {
        // Setup code here. This method is called before each test method.
        continueAfterFailure = false
    }
    
    override func tearDownWithError() throws {
        // Teardown code here. This method is called after each test method.
    }
    
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()
        
        // Example UI test case.
        XCTAssert(app.buttons["ExampleButton"].exists)
    }
    
    // TODO
    // Implement functional UI test
    func testIncrementButton() throws {
        let app = XCUIApplication()
        app.launch()
        
        let incrementButton = app.buttons["Increment"]
        incrementButton.tap()
        
        let counterLabel = app.staticTexts["CounterLabel"]
        XCTAssertEqual(counterLabel.label, "1", "Counter label should display 1 after increment")
    }
    
    func testDecrementButton() throws {
        let app = XCUIApplication()
        app.launch()
        
        let decrementButton = app.buttons["Decrement"]
        decrementButton.tap()
        
        let counterLabel = app.staticTexts["CounterLabel"]
        XCTAssertEqual(counterLabel.label, "-1", "Counter label should display -1 after decrement")
    }
}
