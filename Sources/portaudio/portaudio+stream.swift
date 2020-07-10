import libportaudio

typealias PaStream = UnsafeMutableRawPointer

typealias PaStreamDataClosure = (@convention(c) (  _ inputBuffer: UnsafeRawPointer?,
    _ outputBuffer: UnsafeMutableRawPointer?,
    _ framesPerBuffer: UInt,
    _ timeInfo: UnsafePointer<PaStreamCallbackTimeInfo>?,
    _ statusFlags: PaStreamCallbackFlags,
    _ userData: UnsafeMutableRawPointer?) -> Int32)

typealias PaStreamFinishedClosure = (@convention(c) (_ userData: UnsafeMutableRawPointer?) -> Void)

class PortAudioStream {
    var stream: PaStream
    let framePerBuffer: UInt
    
    init(_ stream: PaStream, _ framePerBuffer: UInt) {
        self.stream = stream
        self.framePerBuffer = framePerBuffer
    }
    
    @discardableResult
    func start() -> Bool {
        let err = Pa_StartStream(stream)
        if err != paNoError.rawValue {
            _printf("ERROR:  Pa_StartStream returned error \(PaErrorAsString(err))\n")
            return false
        }
        return true
    }
    
    @discardableResult
    func stop() -> Bool {
        let err = Pa_StopStream(stream)
        if err != paNoError.rawValue {
            _printf("ERROR:  Pa_StopStream returned error \(PaErrorAsString(err))\n")
            return false
        }
        return true
    }
    
    @discardableResult
    func close() -> Bool {
        let err = Pa_CloseStream(stream)
        if err != paNoError.rawValue {
            _printf("ERROR:  Pa_CloseStream returned error \(PaErrorAsString(err))\n")
            return false
        }
        return true
    }
    
    @discardableResult
    func abort() -> Bool {
        let err = Pa_AbortStream(stream)
        if err != paNoError.rawValue {
            _printf("ERROR:  Pa_AbortStream returned error \(PaErrorAsString(err))\n")
            return false
        }
        return true
    }
    
    @discardableResult
    func read(_ buffer:UnsafeMutableRawPointer) -> Bool {
        let err = Pa_ReadStream(stream, buffer, framePerBuffer)
        if err != paNoError.rawValue {
            _printf("ERROR:  Pa_ReadStream returned error \(PaErrorAsString(err))\n")
            return false
        }
        return true
    }
    
    @discardableResult
    func write(_ buffer:UnsafeMutableRawPointer) -> Bool {
        let err = Pa_WriteStream(stream, buffer, framePerBuffer)
        if err != paNoError.rawValue {
            _printf("ERROR:  Pa_WriteStream returned error \(PaErrorAsString(err))\n")
            return false
        }
        return true
    }
    
    func sleep(_ ms: Int) {
        Pa_Sleep(ms)
    }
}

extension PortAudio {
    
    func openStream(_ inputParameters: UnsafePointer<PaStreamParameters>?,
                    _ outputParameters: UnsafePointer<PaStreamParameters>?,
                    _ sampleRate: Double = 44100,
                    _ framePerBuffer: Int = 512,
                    _ userData: UnsafeMutableRawPointer? = nil,
                    _ streamData: PaStreamDataClosure! = nil,
                    _ streamFinished: PaStreamFinishedClosure? = nil) -> PortAudioStream? {
                        
        var stream:PaStream? = nil
        let err = Pa_OpenStream(&stream,
                                inputParameters,
                                outputParameters,
                                sampleRate,
                                UInt(framePerBuffer),
                                paClipOff,
                                streamData,
                                userData)
        if err != paNoError.rawValue {
            _printf("ERROR:  Pa_OpenStream returned error \(PaErrorAsString(err))\n")
            return nil
        }
        
        if let streamFinished = streamFinished {
            Pa_SetStreamFinishedCallback(&stream, streamFinished)
        }
        
        if let stream = stream {
            return PortAudioStream(stream, UInt(framePerBuffer))
        }
        
        return nil
    }
    
}
