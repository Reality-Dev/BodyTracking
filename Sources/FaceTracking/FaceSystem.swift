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

            faceAnchor.leftEye.transform.matrix = arFaceAnchor.leftEyeTransform

            faceAnchor.rightEye.transform.matrix = arFaceAnchor.rightEyeTransform

            updateMorphedEntities(faceAnchor: faceAnchor)
        }
    }

    private func updateMorphedEntities(faceAnchor: FaceAnchor) {
        for morphedEntity in faceAnchor.morphedEntities {
            let values = morphedEntity.targetLocations.compactMap { faceAnchor.face.blendShapes[$0] }

            // Values must be in the same order and have the same total count as the corresponding targets.
            guard values.count == morphedEntity.targetLocations.count else { return }

            morphedEntity.morphComponent.setTargetWeights(.init(values))
        }
    }
}
