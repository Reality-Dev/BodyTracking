//
//  File.swift
//
//
//  Created by Grant Jarvis on 12/29/23.
//

import ARKit
import RealityKit

// MARK: - Configuration

public extension ARView {
    func runBodyTrackingConfig2D() throws {
        // This is more efficient if you are just using 2D and Not 3D tracking.
        guard ARWorldTrackingConfiguration.supportsFrameSemantics(.bodyDetection) else {
            let errorMessage = "This device does Not support body detection."
            print(errorMessage)
            throw BodyTrackingError.runtimeError(errorMessage)
        }
        let config2D = ARWorldTrackingConfiguration()
        config2D.frameSemantics = .bodyDetection
        session.run(config2D)
    }

    /// If ARBodyTrackingConfiguration is supported on this device, run this type of configuration on this ARView's session.
    ///
    /// If ARBodyTrackingConfiguration is not supported on this device, this function will print an error message, throw an error, and present an alert to the user.
    func runBodyTrackingConfig3D(autoAlert: Bool = false) throws {
        // If the iOS device doesn't support body tracking, raise an error.
        guard ARBodyTrackingConfiguration.isSupported else {
            if autoAlert {
                showAlert(title: "Uh oh...", message: "This device does Not support body tracking.")
            }

            let errorMessage = """
            This device does Not support body tracking. This feature is only supported on devices with an A12 chip.
            """

            print(errorMessage)

            throw BodyTrackingError.runtimeError(errorMessage)
        }

        // This automatically adds the .bodyDetection frame semantic to the session configuration for 2D tracking as well.
        let config3D = ARBodyTrackingConfiguration()

        session.run(config3D)
    }
}
