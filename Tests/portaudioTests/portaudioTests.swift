import XCTest
@testable import portaudio
import libportaudio

final class portaudioTests: XCTestCase {
    
    func testPrintInfo() {
		PortAudio().print()
    }
    
    func testPrintDefaultDevicesOnly() {
        let portaudio = PortAudio()
        if let (inputDevice, inputDeviceIdx) = portaudio.defaultInputDevice {
            inputDevice.print(inputDeviceIdx)
        }
        if let (outputDevice, outputDeviceIdx) = portaudio.defaultOutputDevice {
            outputDevice.print(outputDeviceIdx)
        }
    }
    
    func testPlaySineWave() {
        
        struct paSineData {
            var sine:[Float]
            var left_phase:Int
            var right_phase:Int
            
            init(_ tableSize:Int) {
                sine = Array(repeating: 0, count: tableSize)
                left_phase = 0
                right_phase = 0
                
                for idx in 0..<tableSize {
                    sine[idx] = Float(sin( (Double(idx) / Double(tableSize)) * Double.pi * 2.0 )) * 0.5
                }
            }
        }
        
        
        let portaudio = PortAudio()
        
        if let (outputDevice, outputDeviceIdx) = portaudio.defaultOutputDevice {
            var outputParameters = PaStreamParameters()
            outputParameters.device = outputDeviceIdx
            outputParameters.channelCount = 2               /* stereo output */
            outputParameters.sampleFormat = paFloat32       /* 32 bit floating point output */
            outputParameters.suggestedLatency = outputDevice.defaultLowOutputLatency
            outputParameters.hostApiSpecificStreamInfo = nil
                        
            let processAudio: PaStreamDataClosure = { (inputBuffer, outputBuffer, framesPerBuffer, timeInfoPtr, statusFlags, userData) -> Int32 in
                
                if let outputBuffer = outputBuffer {
                    var outPtr = outputBuffer.assumingMemoryBound(to: Float.self)
                    let dataPtr = userData?.assumingMemoryBound(to: paSineData.self)
                    if var data = dataPtr?.pointee {
                        for _ in 0..<framesPerBuffer {
                            outPtr.pointee = data.sine[data.left_phase]
                            outPtr += 1
                            outPtr.pointee = data.sine[data.right_phase]
                            outPtr += 1

                            data.left_phase += 1
                            if data.left_phase >= 200 {
                                data.left_phase -= 200
                            }
                            data.right_phase += 3
                            if data.right_phase >= 200 {
                                data.right_phase -= 200
                            }
                        }
                    }
                }
                return Int32(paContinue.rawValue)
            }
            
            let streamFinished: PaStreamFinishedClosure = { (userData) in
                print("stream finished")
            }
            
            var data = paSineData(200)
            if let stream = portaudio.openStream(nil, &outputParameters, &data, processAudio, streamFinished) {
                print("stream opened!")
                stream.start()
                stream.sleep(1000)
                stream.stop()
                stream.close()
            }

        }
    }

    static var allTests = [
        ("testPrintInfo", testPrintInfo),
        ("testPrintDefaultDevicesOnly", testPrintDefaultDevicesOnly),
        ("testPlaySineWave", testPlaySineWave),
    ]
}
