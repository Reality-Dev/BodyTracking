//
//  File.swift
//  
//
//  Created by Grant Jarvis on 12/16/23.
//

import ARKit
import RealityKit

final class FaceSystem: System {
    
    static weak var arSession: ARSession?
    
    init(scene: Scene) {}
    
    private static var faceQuery = EntityQuery(where: .has(FaceComponent.self))
    
    // Must access the frame's anchors every frame. Storing the ARFaceAnchor does not give updates.
    func update(context: SceneUpdateContext) {
        guard
            let arSession = Self.arSession,
            let arFaceAnchor = arSession.currentFrame?.anchors.compactMap({$0 as? ARFaceAnchor}).first
        else {return}
        
        context.scene.performQuery(Self.faceQuery).compactMap({$0 as? FaceAnchor}).forEach { faceAnchor in
            
            faceAnchor.face.arFaceAnchor = arFaceAnchor
            
            faceAnchor.leftEye.transform.matrix = arFaceAnchor.leftEyeTransform
            
            faceAnchor.rightEye.transform.matrix = arFaceAnchor.rightEyeTransform
        }
    }
}