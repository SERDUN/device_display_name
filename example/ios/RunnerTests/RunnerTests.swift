import Flutter
import UIKit
import XCTest

@testable import device_display_name

class RunnerTests: XCTestCase {

  func testReadGivesTheIdentifierAndTheIdiom() {
    let plugin = DeviceDisplayNamePlugin()
    let call = FlutterMethodCall(methodName: "read", arguments: nil)

    let resultExpectation = expectation(description: "result block must be called.")
    plugin.handle(call) { result in
      let map = result as? [String: String]
      XCTAssertFalse((map?["machine"] ?? "").isEmpty)
      XCTAssertTrue(["phone", "pad", "tv", "carPlay", "mac", "vision", "unspecified"].contains(map?["idiom"] ?? ""))
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

  func testAnotherMethodIsNotImplemented() {
    let plugin = DeviceDisplayNamePlugin()
    let call = FlutterMethodCall(methodName: "getPlatformVersion", arguments: nil)

    let resultExpectation = expectation(description: "result block must be called.")
    plugin.handle(call) { result in
      XCTAssertTrue((result as AnyObject) === FlutterMethodNotImplemented)
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }
}
