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
    func enableOcclusion(withDepth: Bool = true) throws {
        var config: ARConfiguration
        guard ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentation) else {
            let errorMessage = "This device does Not support person segmentation."
            print(errorMessage)
            throw BodyTrackingError.runtimeError(errorMessage)
        }
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
}



extension UIView {
    public func showAlert(title: String, message: String){
        guard UIApplication.shared.windows.count == 1 else { return}
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
        //arView.window is nil the way we have set up this example project.
        UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true, completion: nil)
    }
}


import simd
public extension float4x4 {
  var translation: SIMD3<Float> {
    get {
      let translation = columns.3
      return SIMD3<Float>(translation.x, translation.y, translation.z)
    }
  }
}
