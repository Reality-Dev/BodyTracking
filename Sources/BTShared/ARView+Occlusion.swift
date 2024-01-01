//
//  ARView+Occlusion.swift
//  BodyEntity-Example
//
//  Created by Grant Jarvis on 5/2/21.
//

import ARKit
import RealityKit

// This enables or disables person segmentation occlusion.
// Person segmentation is different from the 3D occlusion shapes inside of ARSUIView3D.
public extension ARView {
    /// Use this function to enable person segmentation occlusion
    /// - Parameter withDepth: If withDepth is false, then a person always shows up in front of virtual content, no matter how far away the person or the content is. If withDepth is true, then the person shows up in front only where it is judged to be *closer* to the camera than the virtual content.
    func enableOcclusion(withDepth: Bool = true) throws {
        var config: ARConfiguration
        guard ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentation) else {
            let errorMessage = "This device does Not support person segmentation."
            print(errorMessage)
            throw BodyTrackingError.unsupportedFrameSemantics("personSegmentation frame semantic is unavailable.")
        }
        if let configuration = session.configuration {
            config = configuration
        } else {
            config = ARWorldTrackingConfiguration()
        }
        if withDepth {
            config.frameSemantics.insert(.personSegmentationWithDepth)
        } else {
            config.frameSemantics.insert(.personSegmentation)
        }
        session.run(config)
    }

    /// Use this function to disable person segmentation occlusion
    func disableOcclusion() {
        var config: ARConfiguration
        if let configuration = session.configuration {
            config = configuration
        } else {
            config = ARWorldTrackingConfiguration()
        }
        config.frameSemantics.remove([.personSegmentationWithDepth, .personSegmentation])
        session.run(config)
    }
}
