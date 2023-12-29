
import RealityKit
import Combine
import ARKit
import UIKit
import RKUtilities

public extension ARView {
    
    //To learn more about face tracking:
    //https://developer.apple.com/documentation/arkit/arfacetrackingconfiguration
    /*
    "Because face tracking provides your app with personal facial information, your app must include a privacy policy describing to users how you intend to use face tracking and face data. For details, see the Apple Developer Program License Agreement."
    */
    
    
    func runFaceTrackingConfig() throws {
        
        // If the iOS device doesn't support face tracking, raise an error.
        guard ARFaceTrackingConfiguration.isSupported
        else {
            showAlert(title: "Uh oh...", message: "This device does Not support face tracking.")
            let errorMessage = "This device does Not support face tracking. This feature is only supported on devices with an A12 chip."
            print(errorMessage)
            throw BodyTrackingError.runtimeError(errorMessage)
        }
        
        let config3D = ARFaceTrackingConfiguration()
        self.session.run(config3D)
    }
}

public enum Eye {
    case left, right
}

public class FaceAnchor: Entity, HasAnchoring {
    
    public var face: FaceComponent {
        get {
            self.component(forType: FaceComponent.self) ?? .init()
        } set {
            components[FaceComponent.self] = newValue
        }
    }
    
    public private(set) var leftEye = Entity()
    
    public private(set) var rightEye = Entity()
    
    ///A Boolean value that indicates whether this object's transform accurately represents the trasform of the real-world face for the current frame.
    ///
    ///If this value is true, the object’s transform currently matches the position and orientation of the real-world object it represents.
    ///
    ///If this value is false, the object is not guaranteed to match the movement of its corresponding real-world feature, even if it remains in the visible scene.
    public var faceIsTracked: Bool {
        return face.arFaceAnchor?.isTracked ?? false
    }

    public required init(session: ARSession) {
        super.init()
        
        FaceSystem.arSession = session
        
        self.face = .init()
        
        //This will automatically attach this entity to the face.
        self.anchoring = AnchoringComponent(.face)
        
        addChild(leftEye)
        
        addChild(rightEye)
    }

    required init() {
        fatalError("init() has not been implemented")
    }
    
    /// Destroy this Entity and its references to any ARViews
    /// This helps prevent memory leaks.
    public func destroy() {
      
      for child in children {
        child.removeFromParent()
      }

      self.removeFromParent()
    }
}
