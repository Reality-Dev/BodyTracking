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
        targetLocations = Array(targetMapping.keys)

        let targets = targetLocations.compactMap { targetMapping[$0] }

        super.init()

        model = baseModel

        do {
            // This will handle throwing an error if an unsupported number of targets was passed.
            morphComponent = try MorphComponent(entity: self,
                                                targets: targets)
        } catch {
            assertionFailure("Failed to create MorphComponent for FaceMorphedEntity \(error)")
        }
    }

    @MainActor required init() {
        fatalError("init() has not been implemented")
    }
    
    /// Use this to perform your own morphing; If you attach this FaceMorphedEntity to a FaceAnchor then there is no need to call this method yourself.
    public func update(with blendShapeContainer: BlendShapeContainer) {
        var weights = [ARFaceAnchor.BlendShapeLocation: Float]()
        
        targetLocations.forEach {
            weights[$0] = blendShapeContainer[$0]
        }

        setTargetWeights(weights: weights)
    }
    
    /// Use this to perform your own morphing; If you attach this FaceMorphedEntity to a FaceAnchor then there is no need to call this method yourself.
    public func setTargetWeights(weights: [ARFaceAnchor.BlendShapeLocation: Float]) {
        
        let values = targetLocations.compactMap { weights[$0] }
        
        guard values.count == targetLocations.count else {
            assertionFailure("Weights must at least include the same members as the corresponding targets.")
            return
        }
        
        morphComponent.setTargetWeights(.init(values))
    }
}
