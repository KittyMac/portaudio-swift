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
    
    init(_ stream: PaStream) {
        self.stream = stream
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
    
    func sleep(_ ms: Int) {
        Pa_Sleep(ms)
    }
}

extension PortAudio {
    
    func openStream(_ inputParameters: UnsafePointer<PaStreamParameters>?,
                    _ outputParameters: UnsafePointer<PaStreamParameters>?,
                    _ userData: UnsafeMutableRawPointer,
                    _ streamData: PaStreamDataClosure!,
                    _ streamFinished: PaStreamFinishedClosure? = nil) -> PortAudioStream? {
        
        let SAMPLE_RATE: Double = 44100
        let FRAMES_PER_BUFFER: UInt = 64
                
        var stream:PaStream? = nil
        let err = Pa_OpenStream(&stream,
                                inputParameters,
                                outputParameters,
                                SAMPLE_RATE,
                                FRAMES_PER_BUFFER,
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
            return PortAudioStream(stream)
        }
        
        return nil
    }
    
}
