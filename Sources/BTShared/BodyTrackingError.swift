//
//  File.swift
//  
//
//  Created by Grant Jarvis on 1/1/24.
//

import Foundation

public enum BodyTrackingError: Error, LocalizedError {
    case unsupportedFrameSemantics(String)
    
    case unsupportedConfiguration(String)
    
    public var errorDescription: String? {
        switch self {
        case .unsupportedFrameSemantics(let comment):
            return NSLocalizedString(
                "The provided frame semantics are not available",
                comment: comment
            )
        case .unsupportedConfiguration(let comment):
            return NSLocalizedString(
                "The provided configuration is not available",
                comment: comment
            )
        }
    }
}
