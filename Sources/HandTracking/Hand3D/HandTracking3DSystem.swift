//
//  File.swift
//
//
//  Created by Grant Jarvis on 12/30/23.
//

import ARKit
import RealityKit
import RKUtilities
import BTShared

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

            updateTransforms(on: handAnchor, sceneDepth: sceneDepth)

            updateTrackedEntities(on: handAnchor)
        }
    }
    
    private let jointMapping: [HandJoint.JointName: Int] = {
        let jointNames = HandJoint.allHandJoints
        
        var jointMapping = [HandJoint.JointName: Int]()
        
        jointNames.enumerated().forEach {
            jointMapping[$0.1] = $0.0
        }
        return jointMapping
    }()

    /*
     If we have the 2D screen position of the joint and we have the depth at that point, we can project from that 2D position into world space
     (using ARView.ray(through screenPoint: CGPoint))
     and get a 3D world-space coordinate for that joint.
     */
    private func updateTransforms(on handAnchor: HandAnchor,
                                      sceneDepth: CVPixelBuffer)
    {
        
        guard
            let positions2D = get2DPositions(on: handAnchor),
            
            // Gather all values at once instead of locking the buffer multiple times.
            // Tip depths are not used.
            let depthsAtPoints = sceneDepth.values(from: positions2D.avPositions)
        else { return }
        
        updateAnchorTransform(of: handAnchor,
                              screenPositions: positions2D.screenPositions,
                              depthsAtPoints: depthsAtPoints)

        guard
            let modelPositions = getModelPositions(on: handAnchor,
                                                   depthsAtPoints: depthsAtPoints,
                                                   screenPositions: positions2D.screenPositions)
        else {return}
        
        setJointTransforms(on: handAnchor,
                           modelPositions: modelPositions)
    }
    
    private func get2DPositions(on handAnchor: HandAnchor) -> (screenPositions: [CGPoint],
                                                               avPositions: [CGPoint])? {
        let jointNames = HandJoint.allHandJoints

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
            avPositions.count == jointCount
        else { return nil }
        
        return (screenPositions, avPositions)
    }
    
    private func getModelPositions(on handAnchor: HandAnchor,
                                   depthsAtPoints: [Float],
                                   screenPositions: [CGPoint]
    ) -> [simd_float3]? {
        let jointNames = HandJoint.allHandJoints

        let projectionData = zip(screenPositions, depthsAtPoints)
        let modelPositions = zip(jointNames, projectionData).compactMap { jointName, projectionDataPoint in

            // Wrist and tip depths are not used.
            return modelPosition(on: handAnchor,
                          jointName: jointName,
                          screenPosition: projectionDataPoint.0,
                          depth: projectionDataPoint.1)
        }

        guard modelPositions.count == HandJoint.allHandJoints.count else { return nil }
        
        return modelPositions
    }
    
    private func updateAnchorTransform(of handAnchor: HandAnchor,
                                       screenPositions: [CGPoint],
                                       depthsAtPoints: [Float]) {

        guard let worldWristPosition = worldPosition(of: .wrist,
                                                  on: handAnchor,
                                                  screenPositions: screenPositions,
                                                     depthsAtPoints: depthsAtPoints) else {return}
        
        handAnchor.worldPosition = worldWristPosition
        
        if let worldMiddlePosition = worldPosition(of: .middleMCP,
                                                  on: handAnchor,
                                                  screenPositions: screenPositions,
                                                     depthsAtPoints: depthsAtPoints),
           let worldIndexPosition = worldPosition(of: .indexMCP,
                                                     on: handAnchor,
                                                     screenPositions: screenPositions,
                                                  depthsAtPoints: depthsAtPoints) {
            let upDirection = triangleNormal(vertex1: worldMiddlePosition,
                                    vertex2: worldWristPosition,
                                    vertex3: worldIndexPosition)
            
            let newOrientation = orientationFromVects(rootPoint: worldWristPosition,
                                                            forwardPoint: worldMiddlePosition,
                                                            upDirection: upDirection)
            
            handAnchor.worldRotation = simd_slerp(handAnchor.worldRotation, newOrientation, 0.6)
        }
    }

    private func updateTrackedEntities(on handAnchor: HandAnchor) {
        let jointModelTransforms = handAnchor.handAnchorComponent.jointModelTransforms

        for handTracker3D in handAnchor.handTrackers3D {
            handTracker3D.hand3D.trackedEntities.forEach {
                if let transform = jointModelTransforms[$0.key] {
                    $0.value.setTransformMatrix(transform, relativeTo: handTracker3D)
                }
            }
        }
    }
    
    private func setJointTransforms(on handAnchor: HandAnchor,
                                    modelPositions: [simd_float3]) {

        
        var jointModelTransforms = handAnchor.handAnchorComponent.jointModelTransforms
        
        for (jointName, index) in jointMapping {
            
            if jointName == .wrist { continue }
            
            // -- POSITION --
            let modelPosition = modelPositions[index]
            
            jointModelTransforms[jointName]?.translation = modelPosition
            
            // -- ORIENTATION --
            let currentOrientation = jointModelTransforms[jointName]?.orientation ?? .init()
            
            let orientationTarget = HandJoint.orientationTarget[jointName]!
            
            let targetPosition = modelPositions[jointMapping[orientationTarget]!]
            
            let newOrientation = getOrientation(for: jointName,
                                                currentPosition: modelPosition,
                                                currentOrientation: currentOrientation,
                                                targetPosition: targetPosition)
            
            
            jointModelTransforms[jointName]?.orientation = newOrientation
            
        }
        
        handAnchor.handAnchorComponent.jointModelTransforms = jointModelTransforms
    }
    
    private func getOrientation(for jointName: HandJoint.JointName,
                                currentPosition: simd_float3,
                                currentOrientation: simd_quatf,
                                targetPosition: simd_float3,
                                t: Float = 0.5,
                                offset: simd_quatf? = nil) -> simd_quatf {
        var targetPosition = targetPosition
        if HandJoint.tipJoints.contains(jointName) {
            targetPosition = currentPosition + (currentPosition - targetPosition)
        }
        
        var targetOrientation = simd_quatf(from: .forward, to: normalize(targetPosition - currentPosition))
        
        if let offset {
            targetOrientation *= offset
        }
        
        return simd_slerp(currentOrientation, targetOrientation, t)
    }
    
    private func triangleNormal(vertex1: SIMD3<Float>,
                                vertex2: SIMD3<Float>,
                                vertex3: SIMD3<Float>) -> SIMD3<Float> {
        let vector1 = vertex1 - vertex2
        let vector2 = vertex3 - vertex2

        // Calculate the cross product to get the normal vector
        let normalVector = cross(vector1, vector2)

        // Normalize the result to get a unit normal vector
        return normalize(normalVector)
    }
    
    private func orientationFromVects(rootPoint: SIMD3<Float>,
                                  forwardPoint: SIMD3<Float>,
                                          upDirection: SIMD3<Float>) -> simd_quatf {
        
        let forwardDirection = normalize(forwardPoint - rootPoint)

        let quaternionForward = simd_quatf(from: .forward, to: forwardDirection)

        let rotatedUp = quaternionForward.act(simd_float3(0, 1, 0))
        
        let adjustedQuaternion = simd_quatf(from: rotatedUp, to: upDirection) * quaternionForward

        return adjustedQuaternion
    }

    /// Get the model-space position from a UIKit screen point and a depth value
    /// - Parameters:
    ///   - screenPosition: A `CGPoint` representing a point on screen in UIKit coordinates.
    ///   - depth: The depth at this coordinate, in meters.
    /// - Returns: The position in model space (relative to the` HandAnchor`) of this coordinate at this depth.
    public func modelPosition(on handAnchor: HandAnchor,
                              jointName: HandJoint.JointName,
                              screenPosition: CGPoint,
                              depth: Float) -> simd_float3?
    {
       if let worldSpacePosition = worldPosition(on: handAnchor,
                                              jointName: jointName,
                                              screenPosition: screenPosition,
                                                 depth: depth) {
           return handAnchor.convert(position: worldSpacePosition, from: nil)
       }
        return nil
    }
    
    private func worldPosition(of joint: HandJoint.JointName,
     on handAnchor: HandAnchor,
     screenPositions: [CGPoint],
     depthsAtPoints: [Float]) -> simd_float3? {
        
        let jointIndex = jointMapping[joint]!
        
        let jointScreenPosition = screenPositions[jointIndex]
        
        let jointDepth = depthsAtPoints[jointIndex]
        
        return worldPosition(on: handAnchor,
                                                  jointName: joint,
                                                  screenPosition: jointScreenPosition,
                                                  depth: jointDepth)
    }
    
    /// Get the world-space position from a UIKit screen point and a depth value
    /// - Parameters:
    ///   - screenPosition: A `CGPoint` representing a point on screen in UIKit coordinates.
    ///   - depth: The depth at this coordinate, in meters.
    /// - Returns: The position in world space of this coordinate at this depth.
    public func worldPosition(on handAnchor: HandAnchor,
                              jointName: HandJoint.JointName,
                              screenPosition: CGPoint,
                              depth: Float) -> simd_float3?
    {
        guard
            let arView = Self.arView,
            let rayResult = arView.ray(through: screenPosition)
        else { return nil }
        
        var depth = depth
        
        smoothDepthValue(on: jointName,
                         handAnchor: handAnchor,
                         depth: &depth)

        // rayResult.direction is a normalized (1 meter long) vector pointing in the correct direction, and we want to go the length of depth along this vector.
        let worldOffset = rayResult.direction * depth
        let worldPosition = rayResult.origin + worldOffset
        
        return worldPosition
    }
    
    private func smoothDepthValue(on jointName: HandJoint.JointName,
                                  handAnchor: HandAnchor,
                                  depth: inout Float){
        
        let depthValues = handAnchor.handAnchorComponent.depthValues
        
        // Tip joints have unreliable depth.
        if HandJoint.tipJoints.contains(jointName),
           let depthTarget = HandJoint.orientationTarget[jointName],
           let targetDepth = depthValues[depthTarget] {
            depth = targetDepth
        }
        
        let previousDepth = depthValues[jointName]
        
        // Middle depth is more stable.
        if let middleDepth = depthValues[.middleMCP],
           abs(depth - middleDepth) > 0.1
        {
            if let previousDepth,
               // As the hand moves rapidly closer to or away from the camera, more distal values become less reliable.
               abs(previousDepth - middleDepth) < 0.11
            {
                depth = previousDepth
                
            } else {
                
                depth = middleDepth
            }
            
        } else {
            // 2D screen positions are pretty good, but depth values are jittery, so they need smoothing.
            if let previousDepth {
                depth = Float.lerp(previousDepth, depth, t: 0.2)
            }
            
            handAnchor.handAnchorComponent.depthValues[jointName] = depth
        }
    }
}
