//
//  File.swift
//
//
//  Created by Grant Jarvis on 12/30/23.
//

import BTShared
import RealityKit
import struct RKUtilities.Registerer

public protocol HasHand3D {
    var hand3D: Hand3DComponent { get }
}

public struct Hand3DComponent: Component {
    public internal(set) var trackedEntities = [HandJoint.JointName: Entity]()

    init() {
        Registerer.register(Self.self)
        HandTracking3DSystem.registerSystem()
    }
}
