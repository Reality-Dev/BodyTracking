//
//  File.swift
//
//
//  Created by Grant Jarvis on 12/16/23.
//

import ARKit
import RealityKit
import RealityMorpher
import RKUtilities

public final class FaceMorphedEntity: Entity, HasModel, HasMorph {
    // These must be in corresponding order to the targets passed to the morph component.
    internal private(set) var targetLocations: [ARFaceAnchor.BlendShapeLocation]

    public var morphComponent: MorphComponent {
        get {
            component(forType: MorphComponent.self)!
        }
        set {
            components.set(newValue)
        }
    }

    public init(baseModel: ModelComponent,
                targetMapping: [ARFaceAnchor.BlendShapeLocation: ModelComponent])
    {
        let locations = Array(targetMapping.keys)

        let targets = locations.compactMap { targetMapping[$0] }

        targetLocations = locations

        super.init()

        model = baseModel

        // This will handle throwing an error if an unsupported number of targets was passed.
        if let morphComponent = try? MorphComponent(entity: self,
                                                    targets: targets)
        {
            components.set(morphComponent)
        } else {
            assertionFailure("Failed to create MorphComponent for FaceMorphedEntity")
        }
    }

    @MainActor required init() {
        fatalError("init() has not been implemented")
    }
}
