//
//  ARView.swift
//  Body Tracking
//
//  Created by Grant Jarvis on 3/25/21.
//

import ARKit
import RealityKit
import BodyTracking

class ARSUIViewHandTracking2D: BodyARView {
    

    private var handTracker1: HandTracker2D!
    
    private var handTracker2: HandTracker2D!
    

    // Track the screen dimensions:
    lazy var windowWidth: CGFloat = {
        return UIScreen.main.bounds.size.width
    }()
    
    lazy var windowHeight: CGFloat = {
        return UIScreen.main.bounds.size.height
    }()
    
    
    required init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
        guard #available(iOS 14, *) else {
            let title = "Uh oh..."
            let errorMessage = "Hand tracking requires iOS 14.0 or later"
            print(errorMessage)
            showAlert(title: title, message: errorMessage)
            return
        }
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        
        self.handTracker1 = HandTracker2D(arView: self)
        self.handTracker2 = HandTracker2D(arView: self)
        
        makeHandJointsVisible(handTracker: handTracker1)
        makeHandJointsVisible(handTracker: handTracker2)
    }
    
    
    ///This is an example for how to show multiple joints, iteratively.
    private func makeHandJointsVisible(handTracker: HandTracker2D){
        
        //Another way to attach views to the skeletion, but iteratively this time:
        HandTracker2D.allHandJoints.forEach { joint in
            let circle = makeCircle(circleRadius: 20, color: #colorLiteral(red: 0, green: 0.9768045545, blue: 0, alpha: 1))
            handTracker.attach(thisView: circle, toThisJoint: joint)
        }
    }

    
    override func stopSession(){
        super.stopSession()
        self.handTracker1.destroy()
        self.handTracker1 = nil
        self.handTracker2.destroy()
        self.handTracker2 = nil
       }
    
    deinit {
        stopSession()
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



