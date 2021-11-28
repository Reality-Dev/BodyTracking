//
//  ARSUIViewBodyTrackedEntity.swift
//  BodyTracking-Example
//
//  Created by Grant Jarvis on 5/2/21.
//

import ARKit
import RealityKit
//import BodyTracking



class ARSUIViewBodyTrackedEntity: BodyARView {
    
    
    ///This is an anchor entity that will be used to attatch the character to the person.
    ///
    ///This is an Anchor Entity (from RealityKit) targeting a body,
    ///which is Not the same thing as an ARBodyAnchor (from ARKit).
    private let bodyAnchor = AnchorEntity(.body)
    
    private var robot: BodyTrackedEntity!
    
    
    required init(frame frameRect: CGRect) {
        super.init(frame: frameRect)

        //This is an alternative to a do-try-catch block.
        guard let _ = try? runBodyTrackingConfig3D() else {
            print("This device does Not support body tracking.")
            return
        }
        
        //Always remember to add the Anchors to the scene.
        self.scene.addAnchor(bodyAnchor)
        
        //Load and show the robot.
        BodyTrackedEntity.loadCharacterAsync(named: "robotWhite"){ robot in
            print("Loaded \"robotWhite\"")
            print(robot)
            if let modelComp = robot.components[ModelComponent.self] as? ModelComponent {
                print(modelComp.materials)
            }
            self.robot = robot
            self.bodyAnchor.addChild(robot)
        }
        
    }
    
    
    
    

    
    
    
    @objc required dynamic init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func stopSession(){
        super.stopSession()
            self.robot.removeFromParent()
            self.robot = nil
       }
    
}


public extension Entity {
    
    ///Recursively searches through all descendants (depth first) for an Entity that satisfies the given predicate, Not just through the direct children.
    func findEntity(where predicate: (Entity) -> Bool) -> Entity? {
        for child in self.children {
            if predicate(child) { return child }
            else if let satisfier = child.findEntity(where: predicate) {return satisfier}
        }
        return nil
    }
    
    ///Recursively searches through all descendants (depth first) for a ModelEntity, Not just through the direct children.
    ///Reutrns the first model entity it finds.
    ///Returns the input entity if it is a model entity.
    func findModelEntity() -> ModelEntity? {
        if self is ModelEntity { return self as? ModelEntity }
        return self.findEntity(where: {$0 is ModelEntity}) as? ModelEntity
    }
}
