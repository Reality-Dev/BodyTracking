
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

public struct FaceComponent: Component {
    
    static var isRegistered = false
    
    ///Identifiers for specific facial features with coefficients describing the relative movements of those features.
    ///
    ///See: `ARFaceAnchor.BlendShapeLocation` for more explanation.
    ///- Note: SCNMorpher can be used with blendshapes for Memoji type effects.
    public internal(set) var blendShapes = [ARFaceAnchor.BlendShapeLocation : Float]()
    
    public internal(set) var rEyeTransform: simd_float4x4?
    public internal(set) var lEyeTransform: simd_float4x4?
    
    public init(){
        register()
    }
    
    private func register(){
        if !Self.isRegistered {
            Self.registerComponent()
            Self.isRegistered = true
        }
    }
}


public class FaceEntity: Entity, HasAnchoring {
    
    internal weak var arView : ARView?
    
    private var viewBounds: CGRect = .zero

    private var cancellableForUpdate : Cancellable?
    
    public var face = FaceComponent()
    
    ///A Boolean value that indicates whether this object's transform accurately represents the trasform of the real-world face for the current frame.
    ///
    ///If this value is true, the object’s transform currently matches the position and orientation of the real-world object it represents.
    ///
    ///If this value is false, the object is not guaranteed to match the movement of its corresponding real-world feature, even if it remains in the visible scene.
    var faceIsTracked: Bool {
        return arFaceAnchor?.isTracked ?? false
    }
    
    public private(set) var arFaceAnchor: ARFaceAnchor?

    ///Identifiers for specific facial features with coefficients describing the relative movements of those features.
    ///
    ///See: `ARFaceAnchor.BlendShapeLocation` for more explanation.
    ///- Note: SCNMorpher can be used with blendshapes for Memoji type effects.
    public private(set) var blendShapes: [ARFaceAnchor.BlendShapeLocation : Float] {
        get {
            return self.face.blendShapes
        }
        set {
            self.face.blendShapes = newValue
        }
    }

    
    public required init(arView: ARView) {
        self.arView = arView
        super.init()
        //This will automatically attach this entity to the face.
        self.anchoring = AnchoringComponent(.face)
        
        DispatchQueue.main.async {
            self.viewBounds = arView.bounds
        }
        
        self.arView?.scene.addAnchor(self)
        self.subscribeToUpdates()
    }


    
    required init() {
        fatalError("init() has not been implemented")
    }
    
    /// Destroy this Entity and its references to any ARViews
    /// This helps prevent memory leaks.
    public func destroy() {
      self.arView = nil
      for child in children {
        child.removeFromParent()
      }
        self.cancellableForUpdate?.cancel()
        self.cancellableForUpdate = nil
        self.blendShapes = [:]
      self.removeFromParent()
    }
    
    
    
    
    //Subscribe to scene updates so we can run code every frame without a delegate.
    //For RealityKit 2 we should use a RealityKit System instead of this update function but that would be limited to devices running iOS 15.0+
    private func subscribeToUpdates(){
        guard let arView else {return}
        self.cancellableForUpdate = arView.scene.subscribe(to: SceneEvents.Update.self, updateFace)
    }
    
    
    
    
    //Run this code every frame to get the joints.
    public func updateFace(event: SceneEvents.Update? = nil) {

        guard
            let arView,
            let faceAnchor = arView.session.currentFrame?.anchors.first(where: {$0 is ARFaceAnchor}) as? ARFaceAnchor else {return}
        
        self.arFaceAnchor = faceAnchor

        face.rEyeTransform = faceAnchor.rightEyeTransform
        face.lEyeTransform = faceAnchor.leftEyeTransform
        var blendShapes = [ARFaceAnchor.BlendShapeLocation : Float]()
        for blendShape in faceAnchor.blendShapes {
            blendShapes[blendShape.key] = blendShape.value as? Float
        }
        self.blendShapes = blendShapes
    }
}


