//
//  Model.swift
//  Drawing Test
//
//  Created by Grant Jarvis on 1/30/21.
//

import Combine
import RealityKit
import SwiftUI


public enum ARChoice: Int {
    case handTracking
    case face
    case twoD
    case threeD
    case bodyTrackedEntity
    case peopleOcclusion
}



final class DataModel: ObservableObject {
    static var shared = DataModel()
    
    ///This is the ARView corresponding to the visualization that was selected.
    @Published var arView : ARView!
    
    @Published var selection: Int? {
        willSet {
            if let nv = newValue {
                print("selected:", nv)
                self.arChoice = ARChoice(rawValue: nv)!
            }
        }
    }

    
    var arChoice : ARChoice = .twoD {
        didSet {
            print("arChoice is:", arChoice.rawValue)
            switch arChoice {
            case .handTracking:
                self.arView = ARSUIViewHandTracking(frame: .zero)
            case .face:
                self.arView = ARSUIViewFace(frame: .zero)
            case .twoD:
                self.arView = ARSUIView2D(frame: .zero)
            case .threeD:
                self.arView = ARSUIView3D(frame: .zero)
            case .bodyTrackedEntity:
                self.arView = ARSUIViewBodyTrackedEntity(frame: .zero)
            case .peopleOcclusion:
                self.arView = ARSUIViewPersonSegmentation(frame: .zero)
            }
        }
    }
    
}
