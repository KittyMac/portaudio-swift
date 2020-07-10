import XCTest
@testable import portaudio

final class portaudioTests: XCTestCase {
    func testExample() {
        
		let pa = PortAudio()
        
        pa.print()
		
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
