//
//  File.swift
//
//
//  Created by Grant Jarvis on 12/30/23.
//

import BTShared
import RealityKit
import struct RKUtilities.Registerer

public protocol HasBody3D {
    var body3D: Body3DComponent { get }
}

// MARK: - Body3DComponent

public struct Body3DComponent: Component {
    internal var trackedJoints = Set<TrackedBodyJoint>()

    /// An amount, from 0 to 1, that the joint movements are smoothed by.
    public var smoothingAmount: Float = 0

    internal var rootIsSmoothed: Bool

    internal var needsSmoothing: Bool

    /// This is used for smoothing. The BodyEntity3D is attached to an anchor entity which overrides the transforms we set.
    internal var lastRootTransform = simd_float4x4(diagonal: [1, 1, 1, 1])

    public init(smoothingAmount: Float,
                rootIsSmoothed: Bool,
                trackedJoints: Set<TrackedBodyJoint> = [])
    {
        self.smoothingAmount = smoothingAmount
        self.needsSmoothing = smoothingAmount > 0
        self.rootIsSmoothed = rootIsSmoothed
        self.trackedJoints = trackedJoints
        Registerer.register(Self.self)
        // If you call registerSystem() multiple times, RealityKit ignores additional calls after the first.
        BodyTracking3DSystem.registerSystem()
    }
}
