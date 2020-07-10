import libportaudio
import Foundation

func printf(_ format:String,
            _ arg0:CVarArg = 0,
            _ arg1:CVarArg = 0,
            _ arg2:CVarArg = 0,
            _ arg3:CVarArg = 0,
            _ arg4:CVarArg = 0,
            _ arg5:CVarArg = 0,
            _ arg6:CVarArg = 0) {
    print(String(format:format, arg0, arg1, arg2, arg3, arg4, arg5, arg6), terminator: "")
}

class PortAudio {
    
    var ready:Bool = false
    
    init() {
        // http://portaudio.com/docs/v19-doxydocs/pa__devs_8c_source.html
        var err: PaError
        
        err = Pa_Initialize()
        if err != paNoError.rawValue {
            printf("ERROR:  Pa_Initialize returned error 0x%x\n", err)
            return
        }
        
        ready = true
    }
    
    var devices:[PaDeviceInfo] {
        let numDevices = Pa_GetDeviceCount()
        if numDevices < 0 {
            printf("ERROR:  Pa_GetDeviceCount returned error 0x%x\n", numDevices)
            return []
        }
        
        var devices:[PaDeviceInfo] = []
        for idx in 0..<numDevices {
            let deviceInfoPtr = Pa_GetDeviceInfo(idx)
            if let deviceInfo = deviceInfoPtr?.pointee {
                devices.append(deviceInfo)
            }
        }
        
        return devices
    }
    
    func print() {
        var defaultDisplayed: Int

        printf("PortAudio version: 0x%08X\n", Pa_GetVersion())
        printf("Version text: '%s'\n", Pa_GetVersionText())
        
        let printSupportedStandardSampleRates = { (_ inputParameters: UnsafePointer<PaStreamParameters>?, _ outputParameters: UnsafePointer<PaStreamParameters>? ) in
            let standardSampleRates:[Double] = [
                8000.0, 9600.0, 11025.0, 12000.0, 16000.0, 22050.0, 24000.0, 32000.0,
                44100.0, 48000.0, 88200.0, 96000.0, 192000.0
            ]
            var printCount = 0
        
            for sampleRate in standardSampleRates {
                let err = Pa_IsFormatSupported( inputParameters, outputParameters, sampleRate )
                if err == paFormatIsSupported {
                    if printCount == 0 {
                        printf( "\t%8.2f", sampleRate )
                        printCount = 1
                    }
                    else if printCount == 4 {
                        printf( ",\n\t%8.2f", sampleRate )
                        printCount = 1
                    } else {
                        printf( ", %8.2f", sampleRate )
                        printCount += 1
                    }
                }
            }
            if printCount == 0 {
                printf("None\n")
            } else {
                printf("\n")
            }
        }
        
        var idx: Int32 = -1
        for deviceInfo in devices {
            idx += 1
            
            let hostAPIPtr = Pa_GetHostApiInfo( deviceInfo.hostApi )
            if let hostAPI = hostAPIPtr?.pointee {
                printf("--------------------------------------- device #%d\n", idx)
                
                /* Mark global and API specific default devices */
                defaultDisplayed = 0
                if idx == Pa_GetDefaultInputDevice() {
                    printf("[ Default Input")
                    defaultDisplayed = 1
                } else if idx == hostAPI.defaultInputDevice {
                    printf("[ Default %s Input", hostAPI.name)
                    defaultDisplayed = 1
                }
                
                if idx == Pa_GetDefaultOutputDevice() {
                    printf(defaultDisplayed > 0 ? "," : "[")
                    printf(" Default Output")
                    defaultDisplayed = 1
                }
                else if idx == hostAPI.defaultOutputDevice {
                    printf(defaultDisplayed > 0 ? "," : "[")
                    printf(" Default %s Output", hostAPI.name)
                    defaultDisplayed = 1
                }
                
                if defaultDisplayed > 0 {
                    printf(" ]\n")
                }
                
                printf("Name                        = %s\n", deviceInfo.name)
                printf("Host API                    = %s\n",  hostAPI.name)
                printf("Max inputs = %d", deviceInfo.maxInputChannels)
                printf(", Max outputs = %d\n", deviceInfo.maxOutputChannels)
                
                printf("Default low input latency   = %8.4f\n", deviceInfo.defaultLowInputLatency)
                printf("Default low output latency  = %8.4f\n", deviceInfo.defaultLowOutputLatency)
                printf("Default high input latency  = %8.4f\n", deviceInfo.defaultHighInputLatency)
                printf("Default high output latency = %8.4f\n", deviceInfo.defaultHighOutputLatency)
                
                printf( "Default sample rate         = %8.2f\n", deviceInfo.defaultSampleRate)
                
                /* poll for standard sample rates */
                var inputParameters = PaStreamParameters()
                var outputParameters = PaStreamParameters()
                
                inputParameters.device = idx
                inputParameters.channelCount = deviceInfo.maxInputChannels
                inputParameters.sampleFormat = paInt16
                inputParameters.suggestedLatency = 0
                inputParameters.hostApiSpecificStreamInfo = nil
                
                outputParameters.device = idx
                outputParameters.channelCount = deviceInfo.maxOutputChannels
                outputParameters.sampleFormat = paInt16
                outputParameters.suggestedLatency = 0
                outputParameters.hostApiSpecificStreamInfo = nil
                
                if( inputParameters.channelCount > 0 )
                {
                    printf("Supported standard sample rates\n for half-duplex 16 bit %d channel input = \n",
                           inputParameters.channelCount )
                    printSupportedStandardSampleRates( &inputParameters, nil )
                }
                
                if( outputParameters.channelCount > 0 )
                {
                    printf("Supported standard sample rates\n for half-duplex 16 bit %d channel output = \n",
                           outputParameters.channelCount )
                    printSupportedStandardSampleRates( nil, &outputParameters )
                }
                
                if( inputParameters.channelCount > 0 && outputParameters.channelCount > 0 )
                {
                    printf("Supported standard sample rates\n for full-duplex 16 bit %d channel input, %d channel output = \n",
                           inputParameters.channelCount, outputParameters.channelCount )
                    printSupportedStandardSampleRates( &inputParameters, &outputParameters )
                }
            }
        }
    }
}
