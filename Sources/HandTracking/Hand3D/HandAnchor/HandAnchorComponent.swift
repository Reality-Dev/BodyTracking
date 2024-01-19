//
//  File.swift
//
//
//  Created by Grant Jarvis on 12/30/23.
//

import BTShared
import Combine
import RealityKit
import struct RKUtilities.Registerer

public protocol HasHandAnchoring: HasAnchoring {
    var handAnchorComponent: HandAnchorComponent { get }
}

public struct HandAnchorComponent: Component {
    
    // TODO: Make orientation of descedant joints optional - for efficiency.
    // When orientation is false, track only the used joints.
    // TODO: Add optional smoothing amount - position and orientation affected.
    public internal(set) var handWasInitiallyIdentified = CurrentValueSubject<Bool, Never>(false)

    public internal(set) var handIsRecognized = CurrentValueSubject<Bool, Never>(false)

    public var depthBufferSelection: DepthBufferSelection = .smoothedSceneDepth

    public internal(set) var depthValues = [HandJoint.JointName: Float]()

    public internal(set) var jointModelTransforms = [HandJoint.JointName: simd_float4x4]()

    init(depthBufferSelection: DepthBufferSelection) {
        self.depthBufferSelection = depthBufferSelection

        populateJointTransforms()

        Registerer.register(Self.self)
        HandTracking3DSystem.registerSystem()
    }

    private mutating func populateJointTransforms() {
        let identity = simd_float4x4.init(diagonal: .one)
        for joint in HandJoint.allHandJoints {
            jointModelTransforms[joint] = identity
        }
    }
}
