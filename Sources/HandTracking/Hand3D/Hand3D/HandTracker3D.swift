//
//  HandTracker3D.swift
//  BodyTracking-Example
//
//  Created by Grant Jarvis on 4/29/22.
//

import BTShared
import Combine
import CoreVideo
import Foundation
import RealityKit

public enum DepthBufferSelection {
    case sceneDepth
    case smoothedSceneDepth
    case personSegmentationWithDepth
}

public class HandTracker3D: Entity, HasHand3D {
    public internal(set) var hand3D: Hand3DComponent {
        get {
            component(forType: Hand3DComponent.self) ?? .init()
        }
        set {
            components.set(newValue)
        }
    }

    public required init() {
        super.init()

        hand3D = .init()
    }
    
    // TODO: Use ML model for 3D hand tracking.

    /// Allows only one view per joint.
    /// - This will add `thisView` to ARView automatically.
    /// - If you would like to attach more than one view per joint, then try attaching additional views to the view that is already attached to this joint.
    public func attach(entity: Entity, to joint: HandJoint.JointName, preservingWorldTransform: Bool = false) {
        let jointEnt: Entity

        if let existingEnt = hand3D.trackedEntities[joint] {
            jointEnt = existingEnt
        } else {
            jointEnt = Entity()
            hand3D.trackedEntities[joint] = jointEnt
        }

        jointEnt.addChild(entity, preservingWorldTransform: preservingWorldTransform)

        addChild(jointEnt)

        if !preservingWorldTransform { entity.transform = .init() }
    }

    public func removeEnt(_ joint: HandJoint.JointName) {
        hand3D.trackedEntities[joint]?.removeFromParent()
        hand3D.trackedEntities.removeValue(forKey: joint)
    }

    public func destroy() {
        hand3D.trackedEntities.forEach { pair in
            pair.value.removeFromParent()
        }

        removeFromParent()
    }
}
