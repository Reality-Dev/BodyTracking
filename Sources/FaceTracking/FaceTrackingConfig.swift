//
//  File.swift
//  
//
//  Created by Grant Jarvis on 12/30/23.
//

import ARKit
import RealityKit
import BTShared

public extension ARView {
    
    //To learn more about face tracking:
    //https://developer.apple.com/documentation/arkit/arfacetrackingconfiguration
    /*
    "Because face tracking provides your app with personal facial information, your app must include a privacy policy describing to users how you intend to use face tracking and face data. For details, see the Apple Developer Program License Agreement."
    */
    
    
    func runFaceTrackingConfig() throws {
        
        // If the iOS device doesn't support face tracking, raise an error.
        guard ARFaceTrackingConfiguration.isSupported
        else {
            showAlert(title: "Uh oh...", message: "This device does Not support face tracking.")
            let errorMessage = "This device does Not support face tracking. This feature is only supported on devices with an A12 chip."
            print(errorMessage)
            throw BodyTrackingError.runtimeError(errorMessage)
        }
        
        let config3D = ARFaceTrackingConfiguration()
        self.session.run(config3D)
    }
}
