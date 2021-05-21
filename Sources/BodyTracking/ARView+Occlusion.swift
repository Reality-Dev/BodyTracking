//
//  ARView+Occlusion.swift
//  BodyEntity-Example
//
//  Created by Grant Jarvis on 5/2/21.
//

import RealityKit
import ARKit

//This enables or disables person segmentation occlusion.
//Person segmentation is different from the 3D occlusion shapes inside of ARSUIView3D.
extension ARView {
    
    /// Use this function to enable person segmentation occlusion
    /// - Parameter withDepth: If withDepth is false, then a person always shows up in front of virtual content, no matter how far away the person or the content is. If withDepth is true, then the person shows up in front only where it is judged to be *closer* to the camera than the virtual content.
    func enableOcclusion(withDepth: Bool = true) {
        var config: ARConfiguration
        if let configuration = self.session.configuration {
            config = configuration
        } else {
            config = ARWorldTrackingConfiguration()
        }
        if withDepth {
            config.frameSemantics.insert(.personSegmentationWithDepth)
        } else {
            config.frameSemantics.insert(.personSegmentation)
        }
        self.session.run(config)
    }
    
    /// Use this function to disable person segmentation occlusion
    func disableOcclusion() {
        var config: ARConfiguration
        if let configuration = self.session.configuration {
            config = configuration
        } else {
            config = ARWorldTrackingConfiguration()
        }
            config.frameSemantics.remove(.personSegmentationWithDepth)
            config.frameSemantics.remove(.personSegmentation)
        self.session.run(config)
    }
    
    public enum BodyTrackingError: Error {
        case runtimeError(String)
    }
    public func runBodyTrackingConfig3D() throws {
        
        // If the iOS device doesn't support body tracking, raise a developer error for
        // this unhandled case.
        guard ARBodyTrackingConfiguration.isSupported else {
            throw BodyTrackingError.runtimeError("This device does Not support body tracking. This feature is only supported on devices with an A12 chip.")
        }
        
        let config3D = ARBodyTrackingConfiguration()
        self.session.run(config3D)
    }
    
    public func runBodyTrackingConfig2D(){
        //This is more efficient if you are just using 2D and Not 3D tracking.
        let config2D = ARWorldTrackingConfiguration()
        config2D.frameSemantics = .bodyDetection
        self.session.run(config2D)
    }
    
    
    
}
