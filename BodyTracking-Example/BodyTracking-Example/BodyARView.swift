//
//  BodyARView.swift
//  BodyTracking-Example
//
//  Created by Grant Jarvis on 5/12/21.
//

import RealityKit

class BodyARView: ARView {
    
    /// This helps prevent memory leaks.
    func stopSession(){
           self.session.pause()
           self.scene.anchors.removeAll()
           DataModel.shared.arView = nil
       }
}
