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
    internal var trackedJoints = Set<JointEntity>()

    /// An amount, from 0 to 1, that the joint movements are smoothed by.
    public var smoothingAmount: Float = 0

    internal var needsSmoothing: Bool

    public init(smoothingAmount: Float,
                trackedJoints: Set<JointEntity> = [])
    {
        self.smoothingAmount = smoothingAmount
        self.needsSmoothing = smoothingAmount > 0
        self.trackedJoints = trackedJoints
        Registerer.register(Self.self)
        // If you call registerSystem() multiple times, RealityKit ignores additional calls after the first.
        BodyTracking3DSystem.registerSystem()
    }
}
