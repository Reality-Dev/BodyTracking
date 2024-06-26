//
//  File.swift
//
//
//  Created by Grant Jarvis on 12/16/23.
//

import ARKit
import RealityKit
import RealityMorpher

final class FaceSystem: System {
    weak static var arSession: ARSession?

    // MorphSystem is private, so it cannot be referenced.
    // static var dependencies = [.before(MorphSystem.self)]

    init(scene _: Scene) {}

    private static var faceQuery = EntityQuery(where: .has(FaceAnchorComponent.self))

    // TODO: Add support for multiple faces.
    // Must access the frame's anchors every frame. Storing the ARFaceAnchor does not give updates.
    func update(context: SceneUpdateContext) {
        guard
            let arSession = Self.arSession,
            let arFaceAnchor = arSession.currentFrame?.anchors.compactMap({ $0 as? ARFaceAnchor }).first
        else { return }

        context.scene.performQuery(Self.faceQuery).compactMap { $0 as? FaceAnchor }.forEach { faceAnchor in

            faceAnchor.face.arFaceAnchor = arFaceAnchor

            if faceAnchor.face.faceIsTracked.value != arFaceAnchor.isTracked {
                faceAnchor.face.faceIsTracked.value = arFaceAnchor.isTracked
            }

            updateEyes(arFaceAnchor: arFaceAnchor,
                       faceAnchor: faceAnchor)
            
            updateEyeTrackedEntities(faceAnchor: faceAnchor)
            
            updateMorphedEntities(faceAnchor: faceAnchor)
        }
    }
    
    private func updateEyes(arFaceAnchor: ARFaceAnchor,
                            faceAnchor: FaceAnchor) {
        faceAnchor.leftEye.transform.matrix = arFaceAnchor.leftEyeTransform

        faceAnchor.rightEye.transform.matrix = arFaceAnchor.rightEyeTransform
    }

    private func updateMorphedEntities(faceAnchor: FaceAnchor) {
        for morphedEntity in faceAnchor.morphedEntities {

            morphedEntity.update(with: faceAnchor.face.blendShapes)
        }
    }
    
    private func updateEyeTrackedEntities(faceAnchor: FaceAnchor) {
        for eyeAttachment in faceAnchor.eyeAttachments {
            guard let eyeTrackedEntity = eyeAttachment.entity else {continue}
            let trackedTransforms = eyeAttachment.trackedTransforms
            
            var eyeTarget: Entity?
            
            switch eyeAttachment.chirality {
            case .left:
                eyeTarget = faceAnchor.leftEye
            case .right:
                eyeTarget = faceAnchor.rightEye
            }
            guard let eyeTarget else {continue}
            
            if trackedTransforms.contains(.rotation) {
                eyeTrackedEntity.orientation = eyeTarget.orientation
            }
            if trackedTransforms.contains(.position) {
                eyeTrackedEntity.position = eyeTarget.position
            }
        }
    }
}
