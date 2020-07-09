import XCTest

import portaudioTests

var tests = [XCTestCaseEntry]()
tests += portaudioTests.allTests()
XCTMain(tests)
