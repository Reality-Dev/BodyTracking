//
//  File.swift
//
//
//  Created by Grant Jarvis on 12/30/23.
//

import RealityKit
import UIKit

public protocol HasBody2D {
    var body2D: BodyTracking2DComponent { get }
}

// Does not get registered since it is not added to an Entity.
public struct BodyTracking2DComponent {
    /// The positions of the joints on screen.
    ///
    /// - (0,0) is in the top-left.
    public internal(set) var jointScreenPositions = [TwoDBodyJoint: CGPoint]()

    public internal(set) var trackedViews = [TwoDBodyJoint: UIView]()

    /// True if a body is detected in the current frame.
    public internal(set) var bodyIsDetected = false
}
