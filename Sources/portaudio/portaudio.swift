import libportaudio
import Foundation

public class PortAudio {
    
    var ready:Bool = false
    
    public init() {
        // http://portaudio.com/docs/v19-doxydocs/pa__devs_8c_source.html
        var err: PaError
        
        err = Pa_Initialize()
        if err != paNoError.rawValue {
            printf("ERROR:  Pa_Initialize returned error %@\n", PaErrorAsString(err))
            return
        }
        
        ready = true
    }
    
    public var devices:[PaDeviceInfo] {
        let numDevices = Pa_GetDeviceCount()
        if numDevices < 0 {
            printf("ERROR:  Pa_GetDeviceCount returned error %d\n", numDevices)
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
    
    public var defaultInputDevice:(PaDeviceInfo, Int32)? {
        let idx = Pa_GetDefaultInputDevice()
        let deviceInfoPtr = Pa_GetDeviceInfo(idx)
        if let deviceInfo = deviceInfoPtr?.pointee {
            return (deviceInfo, idx)
        }
        return nil
    }
    
    public var defaultOutputDevice:(PaDeviceInfo, Int32)? {
        let idx = Pa_GetDefaultOutputDevice()
        let deviceInfoPtr = Pa_GetDeviceInfo(idx)
        if let deviceInfo = deviceInfoPtr?.pointee {
            return (deviceInfo, idx)
        }
        return nil
    }
}
