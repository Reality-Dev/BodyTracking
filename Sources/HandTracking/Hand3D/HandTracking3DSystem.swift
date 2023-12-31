//
//  File.swift
//
//
//  Created by Grant Jarvis on 12/30/23.
//

import ARKit
import RealityKit
import RKUtilities

internal class HandTracking3DSystem: System {
    static var dependencies: [SystemDependency] {
        [.after(Hand2DSystem.self)]
    }

    internal weak static var arView: ARView?

    required init(scene _: Scene) {}

    private static var handAnchorQuery = EntityQuery(where: .has(HandAnchorComponent.self))

    func update(context: SceneUpdateContext) {
        // TODO: Support multiple hands.
        context.scene.performQuery(Self.handAnchorQuery).compactMap { $0 as? HandAnchor }.forEach { handAnchor in

            guard
                handAnchor.handTracker2D.hand2D.handWasInitiallyIdentified.value,
                let currentFrame = Self.arView?.session.currentFrame
            else { return }

            var sceneDepth: CVPixelBuffer?

            switch handAnchor.handAnchorComponent.depthBufferSelection {
            case .sceneDepth:
                sceneDepth = currentFrame.sceneDepth?.depthMap

            case .smoothedSceneDepth:
                // smoothedSceneDepth works much better than estimatedDepthData.
                sceneDepth = currentFrame.smoothedSceneDepth?.depthMap

            case .personSegmentationWithDepth:
                sceneDepth = currentFrame.estimatedDepthData
            }

            guard let sceneDepth else { return }

            let hand2D = handAnchor.handTracker2D.hand2D
            let anchorComponent = handAnchor.handAnchorComponent

            // Safer than using sink in case the components get regenerated.
            if anchorComponent.handWasInitiallyIdentified.value != hand2D.handWasInitiallyIdentified.value {
                handAnchor.handAnchorComponent.handWasInitiallyIdentified.value = hand2D.handWasInitiallyIdentified.value
            }

            if anchorComponent.handIsRecognized.value != hand2D.handIsRecognized.value {
                handAnchor.handAnchorComponent.handIsRecognized.value = hand2D.handIsRecognized.value
            }

            updateJointPositions(on: handAnchor, sceneDepth: sceneDepth)

            updateTrackedEntities(on: handAnchor)
        }
    }

    /*
     If we have the 2D screen position of the joint and we have the depth at that point, we can project from that 2D position into world space
     (using ARView.ray(through screenPoint: CGPoint))
     and get a 3D world-space coordinate for that joint.
     */
    private func updateJointPositions(on handAnchor: HandAnchor,
                                      sceneDepth: CVPixelBuffer)
    {
        let jointNames = HandTracker2D.allHandJoints

        let hand2D = handAnchor.handTracker2D.hand2D

        let jointCount = jointNames.count

        let screenPositions = jointNames.compactMap {
            hand2D.jointScreenPositions[$0]
        }

        let avPositions = jointNames.compactMap {
            hand2D.jointAVFoundationPositions[$0]
        }

        guard
            screenPositions.count == jointCount,
            avPositions.count == jointCount,
            // Gather all values at once instead of locking the buffer multiple times.
            let depthsAtPoints = sceneDepth.values(from: avPositions)
        else { return }

        let positions = zip(screenPositions, depthsAtPoints)

        // TODO: Move tips inwards.

        let worldPositions = zip(jointNames, positions).compactMap { jointName, positions in
            worldPosition(on: handAnchor,
                          jointName: jointName,
                          screenPosition: positions.0,
                          depth: positions.1)
        }

        guard worldPositions.count == jointCount else { return }

        // TODO: Set orientation as well.
        for (jointName, worldPosition) in zip(jointNames, worldPositions) {
            handAnchor.handAnchorComponent.jointTransforms[jointName]?.translation = worldPosition
        }

        if let wristPosition = handAnchor.handAnchorComponent.jointTransforms[.wrist]?.translation {
            handAnchor.worldPosition = wristPosition
        }
    }

    private func updateTrackedEntities(on handAnchor: HandAnchor) {
        let jointTransforms = handAnchor.handAnchorComponent.jointTransforms

        for handTracker3D in handAnchor.handTrackers3D {
            handTracker3D.hand3D.trackedEntities.forEach {
                if let transform = jointTransforms[$0.key] {
                    $0.value.setTransformMatrix(transform, relativeTo: nil)
                }
            }
        }
    }

    /// Get the world-space position from a UIKit screen point and a depth value
    /// - Parameters:
    ///   - screenPosition: A CGPoint representing a point on screen in UIKit coordinates.
    ///   - depth: The depth at this coordinate, in meters.
    /// - Returns: The position in world space of this coordinate at this depth.
    public func worldPosition(on handAnchor: HandAnchor,
                              jointName: HandTracker2D.HandJointName,
                              screenPosition: CGPoint,
                              depth: Float) -> simd_float3?
    {
        guard
            let arView = Self.arView,
            let rayResult = arView.ray(through: screenPosition)
        else { return nil }

        var depth = depth

        if let middleDepth = handAnchor.handAnchorComponent.depthValues[.middleMCP],
           middleDepth < 0.7,
           abs(depth - middleDepth) > 0.3
        {
            depth = middleDepth
        } else {
            handAnchor.handAnchorComponent.depthValues[jointName] = depth
        }

        // rayResult.direction is a normalized (1 meter long) vector pointing in the correct direction, and we want to go the length of depth along this vector.
        let worldOffset = rayResult.direction * depth
        let worldPosition = rayResult.origin + worldOffset
        return worldPosition
    }
}
