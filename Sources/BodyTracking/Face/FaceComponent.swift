//
//  File.swift
//
//
//  Created by Grant Jarvis on 12/16/23.
//

import ARKit
import RealityKit

/// Used for efficiency so that not all blendshape values must be copied every frame or every time any individual value is accessed.
/// Will transform blendshape values from `NSNumber` to `Float` for use in RealityKit.
public struct BlendShapeContainer {
    
    weak var sourceAnchor: ARFaceAnchor?
    
    public subscript(key: ARFaceAnchor.BlendShapeLocation) -> Float? {
        return sourceAnchor?.blendShapes[key] as? Float
    }
}

public struct FaceComponent: Component {
    
    private static var isRegistered = false
    
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
        register()
    }
    
    private func register(){
        if !Self.isRegistered {
            Self.registerComponent()
            FaceSystem.registerSystem()
            Self.isRegistered = true
        }
    }
}
