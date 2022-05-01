//
//  HandTrackingSystem.swift
//  BodyTracking-Example
//
//  Created by Grant Jarvis on 4/29/22.
//

import Foundation
import Combine
import RealityKit

@available(iOS 14.0, *)
internal class HandTrackingSystem {
    private static var cancellableForUpdate : Cancellable?
    
    
    internal enum HandTrackerType {
        case twoD(HandTracker2D)
        case threeD(HandTracker3D)
        
        ///Used to remove specific items from `trackedObjects`
        var id: UUID {
            switch self {
            case .twoD(let handTracker2D):
                return handTracker2D.id
            case .threeD(let handTracker3D):
                return handTracker3D.uuid
            }
        }
    }
    
    internal static var trackedObjects = [HandTrackerType]()
    
    //Subscribe to scene updates so we can run code every frame without a delegate.
    //For RealityKit 2 we should use a RealityKit System instead of this update function but that would be limited to devices running iOS 15.0+
    internal static func registerSystem(arView: ARView){
        guard self.cancellableForUpdate == nil else {return}
        Self.cancellableForUpdate = arView.scene.subscribe(to: SceneEvents.Update.self, update)
    }
    
    internal static func unRegisterSystem(){
        Self.cancellableForUpdate?.cancel()
        Self.cancellableForUpdate = nil
        
        Self.trackedObjects.removeAll()
    }
    
    private static func update(event: SceneEvents.Update? = nil){
        
        for trackedObject in trackedObjects {
            switch trackedObject {
            case .twoD(let handTracker2D):
                handTracker2D.update()
            case .threeD(let handTracker3D):
                handTracker3D.update()
            }
        }
    }
}

