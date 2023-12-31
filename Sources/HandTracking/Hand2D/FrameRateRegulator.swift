//
//  File.swift
//  
//
//  Created by Grant Jarvis on 12/30/23.
//

import Foundation

public class FrameRateRegulator {
    public enum RequestRate: Int {
        case everyFrame = 1
        case half = 2
        case quarter = 4
    }
    
    ///The frequency that the Vision request for detecting hands will be performed.
    ///
    ///Running the request every frame may decrease performance.
    ///Can be reduced to increase performance at the cost of choppy tracking.
    ///Set to half to run every other frame. Set to quarter to run every 1 out of 4 frames.
    public var requestRate: RequestRate = .everyFrame
    
    private var frameInt = 1
    
    internal func canContinue() -> Bool {
        
        if frameInt == self.requestRate.rawValue {
            frameInt = 1
            return true
            
        } else {
            frameInt += 1
            return false
        }
    }
}
