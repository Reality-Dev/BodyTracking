//
//  ARView.swift
//  Body Tracking
//
//  Created by Grant Jarvis on 3/25/21.
//

import ARKit
import RealityKit
//import BodyTracking

class ARSUIViewHandTracking: BodyARView {
    

    private var handTrackedEntity: HandTrackedEntity!
    

    // Track the screen dimensions:
    lazy var windowWidth: CGFloat = {
        return UIScreen.main.bounds.size.width
    }()
    
    lazy var windowHeight: CGFloat = {
        return UIScreen.main.bounds.size.height
    }()
    
    
    required init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
        self.handTrackedEntity = HandTrackedEntity(arView: self)
        
        makeHandJointsVisible()
    }
    
    
    ///This is an example for how to show multiple joints, iteratively.
    private func makeHandJointsVisible(){
        
        //Another way to attach views to the skeletion, but iteratively this time:
        handTrackedEntity.allHandJoints.forEach { joint in
            let circle = makeCircle(circleRadius: 20, color: #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1))
            self.handTrackedEntity.attach(thisView: circle, toThisJoint: joint)
            self.addSubview(circle)
        }
    }

    
    override func stopSession(){
        super.stopSession()
           self.handTrackedEntity.destroy()
            self.handTrackedEntity = nil
       }
    
    
    private func makeCircle(circleRadius: CGFloat = 72,
                            color: CGColor = #colorLiteral(red: 0.3175252703, green: 0.7384468404, blue: 0.9564777644, alpha: 1)) -> UIView {
        
        // Place circle at the center of the screen to start.
        let xStart = floor((windowWidth - circleRadius) / 2)
        let yStart = floor((windowHeight - circleRadius) / 2)
        let frame = CGRect(x: xStart, y: yStart, width: circleRadius, height: circleRadius)
        
        let circleView = UIView(frame: frame)
        circleView.layer.cornerRadius = circleRadius / 2
        circleView.layer.backgroundColor = color
        return circleView
    }
    
    
    
    
    //required function.
    @objc required dynamic init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}



