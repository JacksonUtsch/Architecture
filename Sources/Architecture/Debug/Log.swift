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
    typealias Console = ConsoleDestination
    typealias Local = FileDestination
    typealias Remote = SBPlatformDestination
}
