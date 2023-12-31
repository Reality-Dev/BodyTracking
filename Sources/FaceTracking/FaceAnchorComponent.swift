//
//  File.swift
//
//
//  Created by Grant Jarvis on 12/16/23.
//

import ARKit
import Combine
import RealityKit
import BTShared
import struct RKUtilities.Registerer

/// Used for efficiency so that not all blendshape values must be copied every frame or every time any individual value is accessed.
/// Will transform blendshape values from `NSNumber` to `Float` for use in RealityKit.
public struct BlendShapeContainer {
    
    fileprivate weak var sourceAnchor: ARFaceAnchor?
    
    public subscript(key: ARFaceAnchor.BlendShapeLocation) -> Float? {
        return sourceAnchor?.blendShapes[key] as? Float
    }
}

public protocol HasFaceAnchoring: HasAnchoring {
    var face: FaceAnchorComponent { get }
    
    var leftEye: Entity { get }
    
    var rightEye: Entity { get }
}

public struct FaceAnchorComponent: Component {
    
    ///A Boolean value that indicates whether this object's transform accurately represents the trasform of the real-world face for the current frame.
    ///
    ///If this value is true, the object’s transform currently matches the position and orientation of the real-world object it represents.
    ///
    ///If this value is false, the object is not guaranteed to match the movement of its corresponding real-world feature, even if it remains in the visible scene.
    public internal(set) var faceIsTracked = CurrentValueSubject<Bool, Never>(false)
    
    ///Identifiers for specific facial features with coefficients describing the relative movements of those features.
    ///
    ///See: `ARFaceAnchor.BlendShapeLocation` for more explanation.
    ///- Note: A geometry morpher can be used with blendshapes for Memoji type effects, but these values can be used for other purposes as well.
    public var blendShapes: BlendShapeContainer {
        
        return BlendShapeContainer(sourceAnchor: arFaceAnchor)
    }
    
    public var rEyeTransform: simd_float4x4? {
        return arFaceAnchor?.rightEyeTransform
    }
    
    public var lEyeTransform: simd_float4x4? {
        return arFaceAnchor?.leftEyeTransform
    }
    
    public internal(set) weak var arFaceAnchor: ARFaceAnchor?
    
    public init(){
        Registerer.register(Self.self)
        FaceSystem.registerSystem()
    }
}
