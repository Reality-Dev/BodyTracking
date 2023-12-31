//
//  File.swift
//  
//
//  Created by Grant Jarvis on 12/30/23.
//

import RealityKit
import BTShared
import struct RKUtilities.Registerer

public protocol HasHand3D {
    var hand3D: Hand3DComponent { get }
}

public struct Hand3DComponent: Component {
    
    public internal(set) var trackedEntities = [HandTracker2D.HandJointName : Entity]()
    
    init() {
        Registerer.register(Self.self)
        HandTracking3DSystem.registerSystem()
    }
}
