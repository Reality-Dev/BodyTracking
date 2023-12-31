
import ARKit
import BTShared
import Combine
import RealityKit
import RKUtilities
import UIKit

public enum Eye {
    case left, right
}

public class FaceAnchor: Entity, HasFaceAnchoring {
    public internal(set) var face: FaceAnchorComponent {
        get {
            component(forType: FaceAnchorComponent.self) ?? .init()
        } set {
            // Do not use this: `components[FaceAnchorComponent.self] = newValue` in case newValue is nil, because `face` should never be nil on `FaceAnchor`.
            components.set(newValue)
        }
    }

    public private(set) var leftEye = Entity()

    public private(set) var rightEye = Entity()

    @WeakCollection internal var morphedEntities = [FaceMorphedEntity]()

    public required init(session: ARSession) {
        super.init()

        FaceSystem.arSession = session

        face = .init()

        // This will automatically attach this entity to the face.
        anchoring = AnchoringComponent(.face)

        addChild(leftEye)

        addChild(rightEye)
    }

    required init() {
        fatalError("init() has not been implemented")
    }

    /// Attaches a FaceMorphedEntity to this FaceAnchor so that the FaceMorphedEntity's mesh will be deformed based on the BlendShapes associated with this particular FaceAnchor
    /// - Parameters:
    ///   - morphedEntity: The entity that will be added for morphing.
    ///   - automaticallyAddChild: Set to true to add this entity as a child to the face anchor. If set to false, you can still add the FaceMorphedEntity to the scene in some other way (such as to another anchor or anchor's descendant), and its geometry will still morph based on the BlendShapes associated with this particular FaceAnchor.
    public func attach(morphedEntity: FaceMorphedEntity,
                       automaticallyAddChild: Bool = true)
    {
        guard morphedEntities.contains(where: { $0 == morphedEntity }) == false else {
            print("Already added FaceMorphedEntity \(morphedEntity.name) to this FaceAnchor")
            return
        }

        morphedEntities.append(morphedEntity)

        if automaticallyAddChild { addChild(morphedEntity) }
    }

    /// Destroy this Entity and its references to any ARViews
    /// This helps prevent memory leaks.
    public func destroy() {
        for child in children {
            child.removeFromParent()
        }

        morphedEntities.removeAll()

        removeFromParent()
    }
}
