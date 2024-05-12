
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
            components.set(newValue)
        }
    }

    public private(set) var leftEye = Entity()

    public private(set) var rightEye = Entity()

    @WeakCollection internal var morphedEntities = [FaceMorphedEntity]()
    
    internal var eyeAttachments = [EyeAttachment]()

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
    
    /// Attaches an    `Entity`'s transform to one of the eyes on this `FaceAnchor`.
    /// 
    /// - Parameters:
    ///   - entity: The entity to attach.
    ///   - chirality: The eye to select. i.e. left or right.
    ///   - trackedTransforms: The set of transforms to track. Options include `position` and `rotation`.
    public func attach(entity: Entity,
                       toEye chirality: Chirality,
                       tracking trackedTransforms: TransformationOptions = .rotation)
    {
        guard eyeAttachments.contains(where: { $0.entity == entity }) == false else {
            print("Already added Entity \(entity.name) to this FaceAnchor")
            return
        }

        eyeAttachments.append(.init(entity: entity,
                                        chirality: chirality,
                                        trackedTransforms: trackedTransforms))

        
    }

    /// Destroy this Entity and its references to any ARViews
    /// This helps prevent memory leaks.
    public func destroy() {
        for child in children {
            child.removeFromParent()
        }

        morphedEntities.removeAll()
        
        eyeAttachments.removeAll()

        removeFromParent()
    }
}

// MARK: - Eye Tracking Data
public extension FaceAnchor {
    struct TransformationOptions: OptionSet {
        public let rawValue: Int

        public static let position = TransformationOptions(rawValue: 1 << 0)
        
        public static let rotation = TransformationOptions(rawValue: 1 << 1)
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }
    
    enum Chirality {
        case left, right
    }
    
    internal struct EyeAttachment {
        weak var entity: Entity?
        
        var chirality: Chirality
        
        var trackedTransforms: TransformationOptions
    }
}
