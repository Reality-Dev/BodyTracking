//
//  ARView.swift
//  Body Tracking
//
//  Created by Grant Jarvis on 3/25/21.
//

import ARKit
import RealityKit
//import BodyTracking

class ARSUIViewFace: BodyARView {
    
    private var faceEntity : FaceEntity!
    private var rEye: ModelEntity!
    private var rEyeRay: Entity!
    private var lEye: ModelEntity!
    private var lEyeRay: Entity!
    
    private var mouth: ModelEntity?
    
    
    required init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
        self.faceEntity = FaceEntity(arView: self)
        self.session.delegate = self
        guard let _ = try? runFaceTrackingConfig() else { return }
        makeFace()
    }

    

    override func stopSession(){
            super.stopSession()
            DataModel.shared.arView = nil
            self.faceEntity.destroy()
            self.faceEntity = nil
    }
    
    deinit {
        self.stopSession()
    }
    
    
    private func makeFace(){
        
        rEye = makeEye()
        rEyeRay = makeRay()
        rEye.addChild(rEyeRay)
    //Rotate ray by 90°
        rEyeRay.transform.rotation = simd_quatf.init(angle: .pi / 2, axis: [1,0,0])
        //Place the pupil on the surface of the eye. The eye's radius is 0.02m.
        rEyeRay.position = [0,0,0.02]
        //--//
        lEye = makeEye()
        lEyeRay = makeRay()
        lEye.addChild(lEyeRay)
    //Rotate ray by 90°
        lEyeRay.transform.rotation = simd_quatf.init(angle: .pi / 2, axis: [1,0,0])
        lEyeRay.position = [0,0,0.02]
        //--//
        faceEntity.addChild(rEye)
        faceEntity.addChild(lEye)
        rEye.position = [0.1, 0.1, 0.05]
        lEye.position = [-0.1, 0.1, 0.05]
        
    }

    private func makeRay()-> Entity{
        let rayMesh = MeshResource.generateBox(size: [0.01, 0.4, 0.01], cornerRadius: 1)
        let rayMat = UnlitMaterial(color: .green)
        let ray = ModelEntity(mesh: rayMesh, materials: [rayMat])
        let pivotEntity = Entity()
        pivotEntity.addChild(ray)
        //Put the tip of the ray at the center of the pivot point.
        //i.e. Move it by half of its own height.
        ray.position = [0,0.2,0]
        return pivotEntity
    }
    
    private func makeEye() -> ModelEntity{
        let eyeBall = Entity.makeSphere(color: .white, radius: 0.02, isMetallic: false)
        return eyeBall
    }
    
    
    //required function.
    @objc required dynamic init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension ARSUIViewFace: ARSessionDelegate {
    
    //For RealityKit 2 we should use a RealityKit System instead of this update function but that would be limited to devices running iOS 15.0+
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        rEye.transform.matrix = faceEntity.face.rEyeTransform ?? .init()
        lEye.transform.matrix = faceEntity.face.lEyeTransform ?? .init()
        
        //The more wide you open your eyes, the longer rays are that shoot out from your eyes.
        rEyeRay.scale.y = faceEntity.blendShapes[.eyeWideRight] ?? 1
        lEyeRay.scale.y = faceEntity.blendShapes[.eyeWideLeft] ?? 1
        
//        if let mouth = mouth {
//            mouth.scale.x = 1 - (faceEntity.blendShapes[.mouthClose] ?? 1)
//            mouth.scale.y = faceEntity.blendShapes[.jawOpen] ?? 1
//        }
    }
}
