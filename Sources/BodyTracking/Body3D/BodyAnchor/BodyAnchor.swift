//
//  File.swift
//
//
//  Created by Grant Jarvis on 12/29/23.
//

import ARKit
import BTShared
import RealityKit

public class BodyAnchor: Entity, HasBodyAnchoring {
    @WeakCollection internal var body3DEntities = [BodyEntity3D]()

    public internal(set) var bodyAnchorComponent: BodyAnchorComponent {
        get {
            component(forType: BodyAnchorComponent.self) ?? .init()
        }
        set {
            components.set(newValue)
        }
    }

    /// Initializes a BodyAnchor
    /// - Parameter session: The ARSession that the `BodyTracking3DSystem` will use to extract tracking data.
    public init(session: ARSession) {
        BodyTracking3DSystem.arSession = session

        super.init()

        bodyAnchorComponent = .init()

        // This will automatically attach this entity to the body.
        anchoring = AnchoringComponent(.body)
    }

    @MainActor required init() {
        fatalError("init() has not been implemented")
    }

    /// Attaches a `BodyEntity3D` to this `BodyAnchor` so that the `BodyEntity3D`'s joint transforms will be updated based on the tracking data associated with this `BodyAnchor`.
    /// - Parameters:
    ///   - bodyEntity: The entity that will be added for tracking.
    ///   - automaticallyAddChild: Set to true to add this entity as a child to the `BodyAnchor`. If set to false, you can still add the `BodyEntity3D` to the scene in some other way (such as to another anchor or anchor's descendant), and its joint transforms will be updated based on the tracking data associated with this `BodyAnchor`.
    public func attach(bodyEntity: BodyEntity3D,
                       automaticallyAddChild: Bool = true)
    {
        guard body3DEntities.contains(where: { $0 == bodyEntity }) == false else {
            print("Already added BodyEntity3D \(bodyEntity.name) to this BodyAnchor")
            return
        }

        body3DEntities.append(bodyEntity)

        if automaticallyAddChild { addChild(bodyEntity) }
    }

    /// Destroy this Entity and its references to any ARViews
    /// This helps prevent memory leaks.
    public func destroy() {
        for child in children {
            child.removeFromParent()
        }

        body3DEntities.removeAll()

        removeFromParent()
    }
}
