
import BTShared
import CoreGraphics
import RealityKit
import RKUtilities
import UIKit

public class BodyTracker2D: NSObject, HasBody2D {
    public internal(set) var body2D = BodyTracking2DComponent()

    public required init(arView: ARView) {
        super.init()

        BodyTracking2DSystem.shared.registerSystem(with: arView)

        BodyTracking2DSystem.shared.participatingTrackers.append(self)

        populateJointPositions()
    }

    override required init() {
        fatalError("init() has not been implemented")
    }

    /// Destroy this Entity and its references to any ARViews
    /// This helps prevent memory leaks.
    public func destroy() {
        body2D.jointScreenPositions = [:]

        body2D.trackedViews.forEach { view in
            view.value.removeFromSuperview()
        }

        body2D.trackedViews.removeAll()
    }

    private func populateJointPositions() {
        TwoDBodyJoint.allCases.forEach {
            body2D.jointScreenPositions[$0] = CGPoint()
        }
    }

    /// Allows only one view per joint.
    /// - This will add `thisView` to ARView automatically.
    /// - If you would like to attach more than one view per joint, then try attaching additional views to the view that is already attached to this joint.
    public func attach(thisView: UIView, toThisJoint thisJoint: TwoDBodyJoint) {
        body2D.trackedViews[thisJoint] = thisView
        if thisView.superview == nil {
            BodyTracking2DSystem.shared.arView?.addSubview(thisView)
        }
    }

    public func removeJoint(_ joint: TwoDBodyJoint) {
        body2D.trackedViews[joint]?.removeFromSuperview()
        body2D.trackedViews.removeValue(forKey: joint)
    }
}

// MARK: - Angle Calculations

public extension BodyTracker2D {
    /// Returns the angle (in degrees) between 3 given joints, treating joint2 as the center point.
    /// - The maximum angle is 180.0°
    /// - See "ARView2D.swift" for an example usage.
    func angleBetween3Joints(_ joint1: TwoDBodyJoint,
                             _ joint2: TwoDBodyJoint,
                             _ joint3: TwoDBodyJoint) -> CGFloat?
    {
        let jointScreenPositions = body2D.jointScreenPositions

        // Make sure the joints we are looking for are included in jointScreenPositions.
        guard
            let joint1ScreenPosition = jointScreenPositions[joint1],
            let joint2ScreenPosition = jointScreenPositions[joint2],
            let joint3ScreenPosition = jointScreenPositions[joint3]
        else { return nil }

        let vect1 = (joint1ScreenPosition - joint2ScreenPosition).simdVect()
        let vect2 = (joint3ScreenPosition - joint2ScreenPosition).simdVect()

        let top = dot(vect1, vect2)
        let bottom = length(vect1) * length(vect2)
        let angleInRadians = CGFloat(acos(top / bottom))
        let angleInDegrees = (angleInRadians * 180) / .pi
        return angleInDegrees
    }

    /// Returns the angle (in degrees) between down and the vector formed by the two given points.
    /// - In the UIKit coordinate system, (0,0) is in the top-left corner.
    /// - See "ARView2D.swift" for an example usage.
    /// - Returns: A vector pointing straight down returns 0.0.
    /// A vector pointing to the right returns 270.0.
    /// A vector pointing up returns 180.0.
    /// A vector pointing to the left returns 90.0.
    func angleFrom2Joints(_ joint1: TwoDBodyJoint,
                          _ joint2: TwoDBodyJoint) -> CGFloat?
    {
        let jointScreenPositions = body2D.jointScreenPositions

        // Make sure the joints we are looking for are included in jointScreenPositions.
        guard
            let joint1ScreenPosition = jointScreenPositions[joint1],
            let joint2ScreenPosition = jointScreenPositions[joint2]
        else { return nil }

        return angleBetween2Points(point1: joint1ScreenPosition,
                                   point2: joint2ScreenPosition)
    }

    private func angleBetween2Points(point1: CGPoint, point2: CGPoint) -> CGFloat {
        let difference = point1 - point2
        let angleInRadians = atan2(difference.y, difference.x)

        var angleInDegrees = Float.radiansToDegrees(Float(angleInRadians))
        angleInDegrees -= 90
        if angleInDegrees < 0 { angleInDegrees += 360.0 }
        return CGFloat(angleInDegrees)
    }
}
