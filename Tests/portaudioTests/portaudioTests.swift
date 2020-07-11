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
            if let stream = portaudio.openStream(nil, &outputParameters, 44100, 512, &data, processAudio, streamFinished) {
                print("stream opened!")
                stream.start()
                stream.sleep(1000)
                stream.stop()
                stream.close()
            }

        }
    }
    
    func testSimplePassthrough() {
        
        let portaudio = PortAudio()
        
        if let (outputDevice, outputDeviceIdx) = portaudio.defaultOutputDevice,
            let (inputDevice, inputDeviceIdx) = portaudio.defaultInputDevice {
            
            inputDevice.print(inputDeviceIdx)
            
            outputDevice.print(outputDeviceIdx)
            
            let numChannels = inputDevice.maxInputChannels < outputDevice.maxOutputChannels ? inputDevice.maxInputChannels : outputDevice.maxOutputChannels
                        
            var inputParameters = PaStreamParameters()
            inputParameters.device = inputDeviceIdx
            inputParameters.channelCount = numChannels
            inputParameters.sampleFormat = paFloat32
            inputParameters.suggestedLatency = inputDevice.defaultLowInputLatency
            inputParameters.hostApiSpecificStreamInfo = nil
            
            var outputParameters = PaStreamParameters()
            outputParameters.device = outputDeviceIdx
            outputParameters.channelCount = numChannels
            outputParameters.sampleFormat = paFloat32
            outputParameters.suggestedLatency = outputDevice.defaultLowOutputLatency
            outputParameters.hostApiSpecificStreamInfo = nil
                                    
            let sampleRate: Double = 44100
            let framePerBuffer: Int = 512
            if let stream = portaudio.openStream(&inputParameters, &outputParameters, sampleRate, framePerBuffer) {
                stream.start()
                
                let buffer = UnsafeMutablePointer<Float>.allocate(capacity: framePerBuffer * Int(numChannels))
                buffer.initialize(to: 0)
                                
                while true {
                    if !stream.write(buffer) { break }
                    if !stream.read(buffer) { break }
                }
                
                buffer.deallocate()
                
                stream.stop()
                stream.close()
            }

        }
    }

    func testInput() {
        
        let portaudio = PortAudio()
        
        if let (inputDevice, inputDeviceIdx) = portaudio.defaultInputDevice {
            
            inputDevice.print(inputDeviceIdx)
            
            var inputParameters = PaStreamParameters()
            inputParameters.device = inputDeviceIdx
            inputParameters.channelCount = inputDevice.maxInputChannels
            inputParameters.sampleFormat = paFloat32
            inputParameters.suggestedLatency = inputDevice.defaultLowInputLatency
            inputParameters.hostApiSpecificStreamInfo = nil
                        
            let processAudio: PaStreamDataClosure = { (inputBuffer, outputBuffer, framesPerBuffer, timeInfoPtr, statusFlags, userData) -> Int32 in
                if let inputBuffer = inputBuffer {
                    let inPtr = inputBuffer.assumingMemoryBound(to: Float.self)
                    
                    var avg: Float = 0
                    for idx in 0..<Int(framesPerBuffer) {
                        avg += inPtr[idx]
                    }
                    avg /= Float(framesPerBuffer)
                    if avg > 0 {
                        print(avg)
                    }
                }
                return Int32(paContinue.rawValue)
            }
            
            let streamFinished: PaStreamFinishedClosure = { (userData) in
                print("stream finished")
            }
            
            var data: Int = 0
            if let stream = portaudio.openStream(&inputParameters, nil, 44100, 512, &data, processAudio, streamFinished) {
                stream.start()
                stream.sleep(10000)
                stream.stop()
                stream.close()
            }

        }
    }
    
    static var allTests = [
        //("testPrintInfo", testPrintInfo),
        //("testPrintDefaultDevicesOnly", testPrintDefaultDevicesOnly),
        //("testPlaySineWave", testPlaySineWave),
        ("testInput", testInput),
        //("testSimplePassthrough", testSimplePassthrough),
    ]
}
