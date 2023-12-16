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
    
    func update(context: SceneUpdateContext) {
        guard
            let arSession = Self.arSession,
            let faceAnchor = arSession.currentFrame?.anchors.compactMap({$0 as? ARFaceAnchor}).first
        else {return}
        
        context.scene.performQuery(Self.faceQuery).compactMap({$0 as? FaceEntity}).forEach { faceEntity in
            
            faceEntity.face.arFaceAnchor = faceAnchor
            
            faceEntity.leftEye.transform.matrix = faceAnchor.leftEyeTransform
            
            faceEntity.rightEye.transform.matrix = faceAnchor.rightEyeTransform
        }
    }
}
