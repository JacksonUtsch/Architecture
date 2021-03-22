//
//  Log.swift
//  
//
//  Created by Jackson Utsch on 3/20/21.
//

import Foundation
import SwiftyBeaver

// MARK: Log
/// entry poiint for  errors
public typealias Log = SwiftyBeaver

public extension Log {
    typealias Xcode = ConsoleDestination
    typealias Local = FileDestination
    typealias Remote = SBPlatformDestination
}

// MARK: Debug Types
public extension Store {
    enum Debug {
        case none
        case some(DebugType)
    }
    
    enum DebugType {
        case actions(DebugLevel)
        case stateChanges(DebugLevel)
        case actionsAndStateChanges(_ actions: DebugLevel, _ stateChanges: DebugLevel)
    }
    
    enum DebugLevel {
        case none
        case some(SwiftyBeaver.Level)
    }
}
