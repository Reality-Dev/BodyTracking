//
//  HandTracker3D.swift
//  BodyTracking-Example
//
//  Created by Grant Jarvis on 4/29/22.
//

import Foundation
import RealityKit
import CoreVideo

@available(iOS 14.0, *)
public class HandTracker3D: Entity {
    
    public fileprivate(set) var twoDHandTracker: HandTracker2D
    
    internal let uuid = UUID()
    
    internal weak var arView : ARView?
    
    public private(set) var trackedEntities = [HandTracker2D.HandJointName : Entity]()
    
    public private(set) var depthValues = [HandTracker2D.HandJointName : Float]()
    
    ///The frequency that the Vision request for detecting hands will be performed.
    ///
    ///Running the request every frame may decrease performance.
    ///Can be reduced to increase performance at the cost of choppy tracking.
    ///Set to half to run every other frame. Set to quarter to run every 1 out of 4 frames.
    public var requestRate: FrameRateRegulator.RequestRate {
        get {
            return twoDHandTracker.frameRateRegulator.requestRate
        }
        set {
            twoDHandTracker.frameRateRegulator.requestRate = newValue
        }
    }
    
    public init(arView: ARView){
        
        self.arView = arView
        self.twoDHandTracker = .init(arView: arView)
        super.init()
        
        self.twoDHandTracker.frameRateRegulator.requestRate = .everyFrame
        HandTrackingSystem.registerSystem(arView: arView)
        HandTrackingSystem.trackedObjects.append(.threeD(self))
    }
    
    
    //Runs every frame.
    internal func update(){
        guard
            let arView = arView,
            let currentFrame = arView.session.currentFrame,
            let sceneDepth = currentFrame.estimatedDepthData
        else {return}
        
        for trackedEnt in trackedEntities {
            guard
                let screenPosition = self.twoDHandTracker.jointScreenPositions[trackedEnt.key],
                let avPosition = self.twoDHandTracker.jointAVFoundationPositions[trackedEnt.key],
                let depthAtPoint = sceneDepth.value(from: avPosition),
                let worldPosition = worldPosition(jointName: trackedEnt.key, screenPosition: screenPosition, depth: depthAtPoint)
            else {continue}
            
            trackedEnt.value.setPosition(worldPosition, relativeTo: nil)
        }
    }
    
    /// Get the world-space position from a UIKit screen point and a depth value
    /// - Parameters:
    ///   - screenPosition: A CGPoint representing a point on screen in UIKit coordinates.
    ///   - depth: The depth at this coordinate, in meters.
    /// - Returns: The position in world space of this coordinate at this depth.
    public func worldPosition(jointName: HandTracker2D.HandJointName,
                              screenPosition: CGPoint,
                              depth: Float) -> simd_float3? {
        guard
            let arView = arView,
            let rayResult = arView.ray(through: screenPosition)
        else {return nil}
        
        var depth = depth
        if depth == 0.0 {
            depth = depthValues[jointName] ?? depth
        } else {
            depthValues[jointName] = depth
        }

        //rayResult.direction is a normalized (1 meter long) vector pointing in the correct direction, and we want to go the length of depth along this vector.
         let worldOffset = rayResult.direction * depth
         let worldPosition = rayResult.origin + worldOffset
         return worldPosition
    }
    
    ///Allows only one view per joint.
    ///- This will add `thisView` to ARView automatically.
    ///- If you would like to attach more than one view per joint, then try attaching additional views to the view that is already attached to this joint.
    public func attach(thisEnt: Entity, toThisJoint thisJoint: HandTracker2D.HandJointName){
        
        self.trackedEntities[thisJoint] = thisEnt
        
        self.addChild(thisEnt)
    }
    
    public func removeEnt(_ joint: HandTracker2D.HandJointName){
        self.trackedEntities[joint]?.removeFromParent()
        self.trackedEntities.removeValue(forKey: joint)
    }

    
    /// Destroy this Entity and its references to any ARViews
    /// This helps prevent memory leaks.
    public func destroy() {
        self.arView = nil
        self.trackedEntities.forEach { ent in
            ent.value.removeFromParent()
        }
        self.removeFromParent()
        self.trackedEntities.removeAll()
        
        if let trackedIndex = HandTrackingSystem.trackedObjects.firstIndex(where: {$0.id == self.uuid}){
            HandTrackingSystem.trackedObjects.remove(at: trackedIndex)
        }
        HandTrackingSystem.unRegisterSystem()
    }
    
    required init() {
        fatalError("init() has not been implemented")
    }
}

public extension CVPixelBuffer {
    
    ///The input point must be in normalized AVFoundation coordinates. i.e. (0,0) is in the Top-Left, (1,1,) in the Bottom-Right.
    func value(from point: CGPoint) -> Float? {
        
        let width = CVPixelBufferGetWidth(self)
        let height = CVPixelBufferGetHeight(self)
        
        let colPosition = Int(point.x * CGFloat(width))
        
        let rowPosition = Int(point.y * CGFloat(height))
        
        return value(column: colPosition, row: rowPosition)
    }
    
    func value(column: Int, row: Int) -> Float? {
        guard CVPixelBufferGetPixelFormatType(self) == kCVPixelFormatType_DepthFloat32 else { return nil }
        CVPixelBufferLockBaseAddress(self, .readOnly)
        if let baseAddress = CVPixelBufferGetBaseAddress(self) {
            let width = CVPixelBufferGetWidth(self)
            let index = column + (row * width)
            let offset = index * MemoryLayout<Float>.stride
            let value = baseAddress.load(fromByteOffset: offset, as: Float.self)
                CVPixelBufferUnlockBaseAddress(self, .readOnly)
            return value
        }
        CVPixelBufferUnlockBaseAddress(self, .readOnly)
        return nil
    }
}
