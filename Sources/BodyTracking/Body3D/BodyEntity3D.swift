
import RealityKit
import ARKit

//MARK: - Body3DComponent
public struct Body3DComponent: Component {
    
    private static var isRegistered = false
    
    internal var trackedJoints = Set<TrackedBodyJoint>()
    
    ///An amount, from 0 to 1, that the joint movements are smoothed by.
    public var smoothingAmount: Float = 0
    
    internal var rootIsSmoothed: Bool
    
    internal var needsSmoothing: Bool
    
    ///This is used for smoothing. The BodyEntity3D is attached to an anchor entity which overrides the transforms we set.
    internal var lastRootTransform = simd_float4x4(diagonal: [1, 1, 1, 1])
    
    public init(smoothingAmount: Float,
                rootIsSmoothed: Bool,
                trackedJoints: Set<TrackedBodyJoint> = []){
        self.smoothingAmount = smoothingAmount
        self.needsSmoothing = smoothingAmount > 0
        self.rootIsSmoothed = rootIsSmoothed
        self.trackedJoints = trackedJoints
        register()
    }
    
    private func register(){
        if !Self.isRegistered {
            Self.registerComponent()
            BodyTrackingSystem.registerSystem()
            Self.isRegistered = true
        }
    }
}

//MARK: - BodyEntity3D
public class BodyEntity3D: Entity {
    
    public var body3D: Body3DComponent {
        get {
            component(forType: Body3DComponent.self) ?? .init(smoothingAmount: 0, rootIsSmoothed: false)
        }
        set {
            components.set(newValue)
        }
    }
    
    /// Initializes a BodyEntity3D
    /// - Parameters:
    ///   - rootIsSmoothed: If set to `true`, the root joint will interpolate towards the transform of the anchor. Set to `false` (the default) to have the root joint immediately follow the anchor's transform.
    ///   - smoothingAmount: The amount, from 0 to 1, that the body is smoothed. Values may need to approach 1.0 to appear to have much effect.
    public required init(rootIsSmoothed: Bool = false,
                         smoothingAmount: Float = 0) {
        
        super.init()
        
        self.body3D = Body3DComponent(smoothingAmount: smoothingAmount.clamped(0, 0.9999),
                                      rootIsSmoothed: rootIsSmoothed)
    }
    
    required init() {
        fatalError("init() has not been implemented")
    }
    
    /// Destroy this Entity and its references to any ARViews
    /// This helps prevent memory leaks.
    public func destroy() {
      for child in children {
        child.removeFromParent()
      }
        self.body3D.trackedJoints = []
      self.removeFromParent()
    }
    
    /// Use this function to attach an entity to a particular joint.
    ///
    /// After calling this function, an entity will follow the transform of a particular joint every frame.
    /// - Parameters:
    ///   - entity: The entity to attach.
    ///   - jointName: The joint to attach the entity to.
    ///   - preservingWorldTransform: A Boolean that you set to true to preserve the entity’s world transform, or false to preserve its relative transform. Use true when you want a model to keep its effective location and size within a scene. If you want to offset an entity from a joint transform, then set this to false.
    public func attach(thisEntity entity: Entity,
                toThisJoint jointName: ThreeDBodyJoint,
                preservingWorldTransform: Bool = false){
        var joint: TrackedBodyJoint
        
        if let jointLocal = body3D.trackedJoints.first(where: {$0.jointName == jointName}) {
            
            joint = jointLocal
            
        } else { // body3DComponent.trackedJoints does Not contain this joint yet.
            let jointLocal = TrackedBodyJoint(jointName: jointName)
            
            self.addChild(jointLocal)
            
            if let jointModelTransforms = ARSkeletonDefinition.defaultBody3D.neutralBodySkeleton3D?.jointModelTransforms {
                
                jointLocal.setTransformMatrix(jointModelTransforms[jointName.rawValue], relativeTo: self)
                
            }
            
            body3D.trackedJoints.insert(jointLocal)
            
            joint = jointLocal
        }
        
        joint.addChild(entity, preservingWorldTransform: preservingWorldTransform)
        
        if !preservingWorldTransform { entity.transform = .init() }
    }
    
    ///Removes this joint and all attached entities.
    public func removeJoint(_ joint: ThreeDBodyJoint) {
        if let jointLocal = body3D.trackedJoints.first(where: {$0.jointName == joint}) {
            jointLocal.removeFromParent()
            
            body3D.trackedJoints.remove(jointLocal)
        }
    }
}
