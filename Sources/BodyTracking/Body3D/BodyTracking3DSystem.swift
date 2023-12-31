//
//  File.swift
//
//
//  Created by Grant Jarvis on 12/29/23.
//

import ARKit
import BTShared
import RealityKit
import RKUtilities

// MARK: - BodyTracking3DSystem

final class BodyTracking3DSystem: System {
    weak static var arSession: ARSession?

    init(scene _: Scene) {}

    private static var bodyAnchorQuery = EntityQuery(where: .has(BodyAnchorComponent.self))

    func update(context: SceneUpdateContext) {
        // Must access the frame's anchors every frame. Storing the ARBodyAnchor does not give updates.
        guard
            let arSession = Self.arSession,
            let arBodyAnchor = arSession.currentFrame?.anchors.compactMap({ $0 as? ARBodyAnchor }).first
        else { return }

        context.scene.performQuery(Self.bodyAnchorQuery).compactMap { $0 as? BodyAnchor }.forEach { bodyAnchor in

            bodyAnchor.bodyAnchorComponent.arBodyAnchor = arBodyAnchor

            if bodyAnchor.bodyAnchorComponent.bodyIsTracked.value != arBodyAnchor.isTracked {
                bodyAnchor.bodyAnchorComponent.bodyIsTracked.value = arBodyAnchor.isTracked
            }

            let didInitiallyDetectBody = bodyAnchor.bodyAnchorComponent.didInitiallyDetectBody

            if !didInitiallyDetectBody, arBodyAnchor.isTracked {
                bodyAnchor.bodyAnchorComponent.didInitiallyDetectBody = true
            }

            bodyAnchor.body3DEntities.forEach {
                updateJoints(of: $0, with: arBodyAnchor)
            }
        }
    }

    private func updateJoints(of bodyEntity: BodyEntity3D,
                              with arBodyAnchor: ARBodyAnchor)
    {
        /*
         For efficiency: Entities are parented to the root, not parented to local parent joint. Not using local transform.
         i.e. If only a subset of joints have entities added to them, then we do not need to add internal entities to every joint.
         */
        for trackedJoint in bodyEntity.body3D.trackedJoints {
            let jointIndex = trackedJoint.jointName.rawValue
            let newTransform = arBodyAnchor.skeleton.jointModelTransforms[jointIndex]
            if bodyEntity.body3D.needsSmoothing {
                smoothJointMotion(trackedJoint,
                                  bodyEntity: bodyEntity,
                                  newTransform: newTransform)

            } else {
                trackedJoint.setTransformMatrix(newTransform, relativeTo: bodyEntity)
            }
        }
    }

    // MARK: - Smoothing

    // TODO: Use SmoothDamp instead of Lerp.

    private func smoothJointMotion(_ joint: TrackedBodyJoint,
                                   bodyEntity: BodyEntity3D,
                                   newTransform: simd_float4x4)
    {
        // Scale isn't changing for body joints, so don't smooth that.

        let t = (1 - bodyEntity.body3D.smoothingAmount)

        let newTransform = simd_float4x4.mixOrientationTranslation(joint.transform.matrix, newTransform, t: t)

        joint.setTransformMatrix(newTransform, relativeTo: bodyEntity)
    }
}

// MARK: - simd_float4x4 extension

extension simd_float4x4 {
    static func mixOrientationTranslation(_ x: simd_float4x4, _ y: simd_float4x4, t: Float) -> simd_float4x4 {
        let newTranslation = simd.mix(x.translation,
                                  y.translation,
                                  t: t)

        var mixedMatrix = simd_float4x4(translation: newTranslation)

        let newOrientation = simd_slerp(x.orientation,
                                        y.orientation,
                                        t)

        mixedMatrix.orientation = newOrientation

        return mixedMatrix
    }
}
