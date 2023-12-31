//
//  File.swift
//  
//
//  Created by Grant Jarvis on 12/30/23.
//

import Combine
import RealityKit
import ARKit

public protocol HasHand2D {
    var hand2D: Hand2DComponent { get set }
}

// Does not get registered since it is not added to an Entity.
public struct Hand2DComponent {
    
    public typealias HandJointName = VNHumanHandPoseObservation.JointName
    
    public var confidenceThreshold: Float!
    
    public internal(set) var handWasInitiallyIdentified = CurrentValueSubject<Bool, Never>(false)
    
    public internal(set) var handIsRecognized = CurrentValueSubject<Bool, Never>(false)
    
    ///Screen-space coordinates. These can be used with a UIKit view or ARView covering the entire screen.
    public internal(set) var jointScreenPositions : [HandJointName : CGPoint]!
    
    ///Normalized pixel coordinates (0,0 top-left, 1,1 bottom-right)
    public internal(set) var jointAVFoundationPositions : [HandJointName : CGPoint]!

    public internal(set) var trackedViews = [HandJointName : UIView]()
}
