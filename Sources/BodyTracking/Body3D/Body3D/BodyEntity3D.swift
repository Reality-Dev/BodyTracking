
import ARKit
import RealityKit

// MARK: - BodyEntity3D

public class BodyEntity3D: Entity, HasBody3D {
    public internal(set) var body3D: Body3DComponent {
        get {
            component(forType: Body3DComponent.self) ?? .init(smoothingAmount: 0)
        }
        set {
            components.set(newValue)
        }
    }

    /// Initializes a BodyEntity3D
    /// - Parameters:
    ///   - smoothingAmount: The amount, from 0 to 1, that the body is smoothed. Values may need to approach 1.0 to appear to have much effect.
    public required init(smoothingAmount: Float = 0)
    {
        super.init()

        body3D = Body3DComponent(smoothingAmount: smoothingAmount.clamped(0, 0.9999))
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
        body3D.trackedJoints = []
        removeFromParent()
    }

    public func setSmoothingAmount(_ newValue: Float) {
        body3D.smoothingAmount = newValue.clamped(0, 0.9999)
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
                       preservingWorldTransform: Bool = false)
    {
        var joint: TrackedBodyJoint

        if let jointLocal = body3D.trackedJoints.first(where: { $0.jointName == jointName }) {
            joint = jointLocal

        } else { // body3DComponent.trackedJoints does Not contain this joint yet.
            let jointLocal = TrackedBodyJoint(jointName: jointName)

            /*
             For efficiency: Entities are parented to the root, not parented to local parent joint. Not using local transform.
             i.e. If only a subset of joints have entities added to them, then we do not need to add internal entities to every joint.
             */
            
            addChild(jointLocal)

            if let jointModelTransforms = ARSkeletonDefinition.defaultBody3D.neutralBodySkeleton3D?.jointModelTransforms {
                jointLocal.setTransformMatrix(jointModelTransforms[jointName.rawValue], relativeTo: self)
            }

            body3D.trackedJoints.insert(jointLocal)

            joint = jointLocal
        }

        joint.addChild(entity, preservingWorldTransform: preservingWorldTransform)

        if !preservingWorldTransform { entity.transform = .init() }
    }

    /// Removes this joint and all attached entities.
    public func removeJoint(_ joint: ThreeDBodyJoint) {
        if let jointLocal = body3D.trackedJoints.first(where: { $0.jointName == joint }) {
            jointLocal.removeFromParent()

            body3D.trackedJoints.remove(jointLocal)
        }
    }
}
