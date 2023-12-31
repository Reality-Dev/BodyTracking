//
//  File.swift
//  
//
//  Created by Grant Jarvis on 12/30/23.
//

import Combine
import RealityKit
import BTShared
import struct RKUtilities.Registerer

public protocol HasHandAnchoring: HasAnchoring {
    var handAnchorComponent: HandAnchorComponent { get }
}

public struct HandAnchorComponent: Component {
    public internal(set) var handWasInitiallyIdentified = CurrentValueSubject<Bool, Never>(false)
    
    public internal(set) var handIsRecognized = CurrentValueSubject<Bool, Never>(false)
    
    public var depthBufferSelection: DepthBufferSelection = .smoothedSceneDepth
    
    public internal(set) var depthValues = [HandTracker2D.HandJointName : Float]()
    
    public internal(set) var jointTransforms = [Hand2DComponent.HandJointName: simd_float4x4]()
    
    init(depthBufferSelection: DepthBufferSelection) {
        self.depthBufferSelection = depthBufferSelection
        
        populateJointTransforms()
        
        Registerer.register(Self.self)
        HandTracking3DSystem.registerSystem()
    }
    
    private mutating func populateJointTransforms() {
        let identity = simd_float4x4.init(diagonal: .one)
        for joint in HandTracker2D.allHandJoints {
            jointTransforms[joint] = identity
        }
    }
}
