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

            for bodyEntity in bodyAnchor.body3DEntities {
                if bodyEntity.body3D.rootIsSmoothed {
                    smoothRootMotion(didInitiallyDetectBody: didInitiallyDetectBody,
                                     bodyEntity: bodyEntity,
                                     newTransform: arBodyAnchor.transform)
                }

                updateJoints(of: bodyEntity, with: arBodyAnchor)
            }
        }
    }

    private func updateJoints(of bodyEntity: BodyEntity3D,
                              with arBodyAnchor: ARBodyAnchor)
    {
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
    private func smoothRootMotion(didInitiallyDetectBody: Bool,
                                  bodyEntity: BodyEntity3D,
                                  newTransform: simd_float4x4)
    {
        // Prevent the object from flying onto the body from 0,0,0 in world space initially.
        guard didInitiallyDetectBody else {
            bodyEntity.setTransformMatrix(newTransform, relativeTo: nil)
            bodyEntity.body3D.lastRootTransform = newTransform
            return
        }

        let t = (1 - bodyEntity.body3D.smoothingAmount)

        let lastTransform = bodyEntity.body3D.lastRootTransform

        let newTransform = simd_float4x4.mixOrientationTranslation(lastTransform, newTransform, t: t)

        bodyEntity.setTransformMatrix(newTransform, relativeTo: nil)

        bodyEntity.body3D.lastRootTransform = newTransform
    }

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
        let newTranslation = lerp(from: x.translation,
                                  to: y.translation,
                                  t: t)

        var mixedMatrix = simd_float4x4(translation: newTranslation)

        let newOrientation = simd_slerp(x.orientation,
                                        y.orientation,
                                        t)

        mixedMatrix.orientation = newOrientation

        return mixedMatrix
    }
}
