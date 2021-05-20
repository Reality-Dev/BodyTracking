//
//  ARSUIViewBodyTrackedEntity.swift
//  BodyTracking-Example
//
//  Created by Grant Jarvis on 5/2/21.
//

import ARKit
import RealityKit
//import BodyTracking

class ARSUIViewPersonSegmentation: BodyARView {
    

    
    
    required init(frame frameRect: CGRect) {
        super.init(frame: frameRect)

        //Use this function to enable person segmentation occlusion.
        self.enableOcclusion()
        
        //Create a background so we can see the person segmentation working.
        createBackground()
        
        //Disable unnecessary rendering option.
        self.renderOptions.insert(.disableMotionBlur)
    }
    
    ///Creates a virtual background to show people in front of. It is green by default.
    func createBackground(color: UIColor = .green){
        let bgMesh = MeshResource.generatePlane(width: 5, height: 5)
        let bgMaterial = UnlitMaterial.init(color: color)
        let background = ModelEntity(mesh: bgMesh, materials: [bgMaterial])
        
        //Place the background always 5 meters in front of the camera.
        let cameraAnchor = AnchorEntity(.camera)
        self.scene.addAnchor(cameraAnchor)
        cameraAnchor.addChild(background)
        background.position = [0,0,-5]
    }
    
    
    @objc required dynamic init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
