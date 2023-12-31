//
//  File.swift
//
//
//  Created by Grant Jarvis on 12/30/23.
//

import ARKit
import BTShared
import Combine
import RealityKit
import struct RKUtilities.Registerer

public protocol HasBodyAnchoring: HasAnchoring {
    var bodyAnchorComponent: BodyAnchorComponent { get }
}

public struct BodyAnchorComponent: Component {
    public internal(set) var didInitiallyDetectBody = false

    public internal(set) weak var arBodyAnchor: ARBodyAnchor?

    /// A Boolean value that indicates whether this object's transform accurately represents the trasform of the real-world body for the current frame.
    ///
    /// If this value is true, the object’s transform currently matches the position and orientation of the real-world object it represents.
    ///
    /// If this value is false, the object is not guaranteed to match the movement of its corresponding real-world feature, even if it remains in the visible scene.
    public internal(set) var bodyIsTracked = CurrentValueSubject<Bool, Never>(false)

    init() {
        Registerer.register(Self.self)
        BodyTracking3DSystem.registerSystem()
    }

    public func jointModelTransform(for joint: ThreeDBodyJoint) -> simd_float4x4? {
        arBodyAnchor?.skeleton.jointModelTransforms[joint.rawValue]
    }

    public func jointLocalTransform(for joint: ThreeDBodyJoint) -> simd_float4x4? {
        arBodyAnchor?.skeleton.jointLocalTransforms[joint.rawValue]
    }
}
