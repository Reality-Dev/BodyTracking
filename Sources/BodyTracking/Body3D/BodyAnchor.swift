//
//  File.swift
//  
//
//  Created by Grant Jarvis on 12/29/23.
//

import ARKit
import RealityKit

public struct BodyAnchorComponent: Component {
    public internal(set) var didInitiallyDetectBody = false
    
    public internal(set) weak var arBodyAnchor: ARBodyAnchor?
    
    ///A Boolean value that indicates whether this object's transform accurately represents the trasform of the real-world body for the current frame.
    ///
    ///If this value is true, the object’s transform currently matches the position and orientation of the real-world object it represents.
    ///
    ///If this value is false, the object is not guaranteed to match the movement of its corresponding real-world feature, even if it remains in the visible scene.
    public var bodyIsTracked: Bool {
        arBodyAnchor?.isTracked ?? false
    }
    
    public func jointModelTransform(for joint: ThreeDBodyJoint) -> simd_float4x4? {
        arBodyAnchor?.skeleton.jointModelTransforms[joint.rawValue]
    }
    
    public func jointLocalTransform(for joint: ThreeDBodyJoint) -> simd_float4x4? {
        arBodyAnchor?.skeleton.jointLocalTransforms[joint.rawValue]
    }
}

public class BodyAnchor: Entity, HasAnchoring {
    public private(set) var arBodyAnchor: ARBodyAnchor?
    
    internal var body3DEntities = [Weak<BodyEntity3D>]()
    
    public var bodyAnchorComponent: BodyAnchorComponent {
        get {
            component(forType: BodyAnchorComponent.self) ?? .init()
        }
        set {
            components.set(newValue)
        }
    }
    
    /// Initializes a BodyAnchor
    /// - Parameter session: The ARSession that the `BodyTrackingSystem` will use to extract tracking data.
    public init(session: ARSession) {
        
        BodyTrackingSystem.arSession = session
        
        super.init()
        
        bodyAnchorComponent = .init()
        
        // This will automatically attach this entity to the body.
        self.anchoring = AnchoringComponent(.body)
    }
    
    @MainActor required init() {
        fatalError("init() has not been implemented")
    }
    
    /// Attaches a `BodyEntity3D` to this `BodyAnchor` so that the `BodyEntity3D`'s joint transforms will be updated based on the tracking data associated with this `BodyAnchor`.
    /// - Parameters:
    ///   - bodyEntity: The entity that will be added for morphing.
    ///   - automaticallyAddChild: Set to true to add this entity as a child to the `BodyAnchor`. If set to false, you can still add the `BodyEntity3D` to the scene in some other way (such as to another anchor or anchor's descendant), and its joint transforms will be updated based on the tracking data associated with this `BodyAnchor`.
    public func attach(bodyEntity: BodyEntity3D,
                       automaticallyAddChild: Bool = true) {
        guard self.body3DEntities.contains(where: {$0.wrappedValue == bodyEntity}) == false else {
            print("Already added BodyEntity3D \(bodyEntity.name) to this BodyAnchor")
            return
        }
        self.body3DEntities.append(Weak(bodyEntity))
        
        if automaticallyAddChild { addChild(bodyEntity) }
    }
    
    /// Destroy this Entity and its references to any ARViews
    /// This helps prevent memory leaks.
    public func destroy() {
      
      for child in children {
        child.removeFromParent()
      }
        
      self.body3DEntities.removeAll()

      self.removeFromParent()
    }
}
