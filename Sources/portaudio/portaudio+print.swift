import libportaudio

func PaErrorAsString(_ error: PaError) -> String {
    switch PaErrorCode(rawValue: error) {
    case paNoError: return "paNoError"
    case paNotInitialized: return "paNotInitialized"
    case paUnanticipatedHostError: return "paUnanticipatedHostError"
    case paInvalidChannelCount: return "paInvalidChannelCount"
    case paInvalidSampleRate: return "paInvalidSampleRate"
    case paInvalidDevice: return "paInvalidDevice"
    case paInvalidFlag: return "paInvalidFlag"
    case paSampleFormatNotSupported: return "paSampleFormatNotSupported"
    case paBadIODeviceCombination: return "paBadIODeviceCombination"
    case paInsufficientMemory: return "paInsufficientMemory"
    case paBufferTooBig: return "paBufferTooBig"
    case paBufferTooSmall: return "paBufferTooSmall"
    case paNullCallback: return "paNullCallback"
    case paBadStreamPtr: return "paBadStreamPtr"
    case paTimedOut: return "paTimedOut"
    case paInternalError: return "paInternalError"
    case paDeviceUnavailable: return "paDeviceUnavailable"
    case paIncompatibleHostApiSpecificStreamInfo: return "paIncompatibleHostApiSpecificStreamInfo"
    case paStreamIsStopped: return "paStreamIsStopped"
    case paStreamIsNotStopped: return "paStreamIsNotStopped"
    case paInputOverflowed: return "paInputOverflowed"
    case paOutputUnderflowed: return "paOutputUnderflowed"
    case paHostApiNotFound: return "paHostApiNotFound"
    case paInvalidHostApi: return "paInvalidHostApi"
    case paCanNotReadFromACallbackStream: return "paCanNotReadFromACallbackStream"
    case paCanNotWriteToACallbackStream: return "paCanNotWriteToACallbackStream"
    case paCanNotReadFromAnOutputOnlyStream: return "paCanNotReadFromAnOutputOnlyStream"
    case paCanNotWriteToAnInputOnlyStream: return "paCanNotWriteToAnInputOnlyStream"
    case paIncompatibleStreamHostApi: return "paIncompatibleStreamHostApi"
    case paBadBufferPtr: return "paBadBufferPtr"
    default: return "unknown"
    }
}

func _printf(_ format:String,
            _ arg0:CVarArg = 0,
            _ arg1:CVarArg = 0,
            _ arg2:CVarArg = 0,
            _ arg3:CVarArg = 0,
            _ arg4:CVarArg = 0,
            _ arg5:CVarArg = 0,
            _ arg6:CVarArg = 0) {
    print(String(format:format, arg0, arg1, arg2, arg3, arg4, arg5, arg6), terminator: "")
}

fileprivate func printSupportedStandardSampleRates(_ inputParameters: UnsafePointer<PaStreamParameters>?,
                                                   _ outputParameters: UnsafePointer<PaStreamParameters>? ) {
    let standardSampleRates:[Double] = [
        8000.0, 9600.0, 11025.0, 12000.0, 16000.0, 22050.0, 24000.0, 32000.0,
        44100.0, 48000.0, 88200.0, 96000.0, 192000.0
    ]
    var printCount = 0
    
    for sampleRate in standardSampleRates {
        let err = Pa_IsFormatSupported( inputParameters, outputParameters, sampleRate )
        if err == paFormatIsSupported {
            if printCount == 0 {
                _printf( "\t%8.2f", sampleRate )
                printCount = 1
            }
            else if printCount == 4 {
                _printf( ",\n\t%8.2f", sampleRate )
                printCount = 1
            } else {
                _printf( ", %8.2f", sampleRate )
                printCount += 1
            }
        }
    }
    if printCount == 0 {
        _printf("None\n")
    } else {
        _printf("\n")
    }
}

public extension PaDeviceInfo {
    func print(_ idx: Int32) {
        let hostAPIPtr = Pa_GetHostApiInfo( self.hostApi )
        if let hostAPI = hostAPIPtr?.pointee {
            if idx == Pa_GetDefaultInputDevice() {
                _printf("[ Default Input ]\n")
            } else if idx == hostAPI.defaultInputDevice {
                _printf("[ Default %s Input ]\n", hostAPI.name)
            }
            
            if idx == Pa_GetDefaultOutputDevice() {
                _printf("[ Default Output ]\n")
            }
            else if idx == hostAPI.defaultOutputDevice {
                _printf("[ Default %s Output ]\n", hostAPI.name)
            }
            
            _printf("Name                        = %s\n", self.name)
            _printf("Host API                    = %s\n",  hostAPI.name)
            _printf("Max inputs = %d", self.maxInputChannels)
            _printf(", Max outputs = %d\n", self.maxOutputChannels)
            
            _printf("Default low input latency   = %8.4f\n", self.defaultLowInputLatency)
            _printf("Default low output latency  = %8.4f\n", self.defaultLowOutputLatency)
            _printf("Default high input latency  = %8.4f\n", self.defaultHighInputLatency)
            _printf("Default high output latency = %8.4f\n", self.defaultHighOutputLatency)
            
            _printf( "Default sample rate         = %8.2f\n", self.defaultSampleRate)
            
            /* poll for standard sample rates */
            var inputParameters = PaStreamParameters()
            var outputParameters = PaStreamParameters()
            
            inputParameters.device = idx
            inputParameters.channelCount = self.maxInputChannels
            inputParameters.sampleFormat = paInt16
            inputParameters.suggestedLatency = 0
            inputParameters.hostApiSpecificStreamInfo = nil
            
            outputParameters.device = idx
            outputParameters.channelCount = self.maxOutputChannels
            outputParameters.sampleFormat = paInt16
            outputParameters.suggestedLatency = 0
            outputParameters.hostApiSpecificStreamInfo = nil
            
            if( inputParameters.channelCount > 0 )
            {
                _printf("Supported standard sample rates\n for half-duplex 16 bit %d channel input = \n",
                       inputParameters.channelCount )
                printSupportedStandardSampleRates( &inputParameters, nil )
            }
            
            if( outputParameters.channelCount > 0 )
            {
                _printf("Supported standard sample rates\n for half-duplex 16 bit %d channel output = \n",
                       outputParameters.channelCount )
                printSupportedStandardSampleRates( nil, &outputParameters )
            }
            
            if( inputParameters.channelCount > 0 && outputParameters.channelCount > 0 )
            {
                _printf("Supported standard sample rates\n for full-duplex 16 bit %d channel input, %d channel output = \n",
                       inputParameters.channelCount, outputParameters.channelCount )
                printSupportedStandardSampleRates( &inputParameters, &outputParameters )
            }
        }
    }
}

public extension PortAudio {
    func print() {
        _printf("PortAudio version: 0x%08X\n", Pa_GetVersion())
        _printf("Version text: '%s'\n", Pa_GetVersionText())
        
        var idx: Int32 = -1
        for deviceInfo in devices {
            idx += 1
            
            _printf("--------------------------------------- device #%d\n", idx)
            deviceInfo.print(idx)
        }
    }
}
