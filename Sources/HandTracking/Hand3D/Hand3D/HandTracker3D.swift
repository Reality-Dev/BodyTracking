//
//  HandTracker3D.swift
//  BodyTracking-Example
//
//  Created by Grant Jarvis on 4/29/22.
//

import Foundation
import Combine
import RealityKit
import CoreVideo
import BTShared

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
        
        self.hand3D = .init()
    }
    
    ///Allows only one view per joint.
    ///- This will add `thisView` to ARView automatically.
    ///- If you would like to attach more than one view per joint, then try attaching additional views to the view that is already attached to this joint.
    public func attach(thisEnt: Entity, toThisJoint thisJoint: HandTracker2D.HandJointName, preservingWorldTransform: Bool = false) {
        let jointEnt: Entity
        
        if let existingEnt = hand3D.trackedEntities[thisJoint] {
            jointEnt = existingEnt
        } else {
            jointEnt = Entity()
            hand3D.trackedEntities[thisJoint] = jointEnt
        }
        
        jointEnt.addChild(thisEnt, preservingWorldTransform: preservingWorldTransform)
        
        self.addChild(jointEnt)
        
        if !preservingWorldTransform { thisEnt.transform = .init() }
    }
    
    public func removeEnt(_ joint: HandTracker2D.HandJointName){
        hand3D.trackedEntities[joint]?.removeFromParent()
        hand3D.trackedEntities.removeValue(forKey: joint)
    }
    
    public func destroy() {
        
        hand3D.trackedEntities.forEach { pair in
            pair.value.removeFromParent()
        }
        
        self.removeFromParent()
    }
}
