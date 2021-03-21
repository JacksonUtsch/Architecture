//
//  Log.swift
//  
//
//  Created by Jackson Utsch on 3/20/21.
//

import SwiftyBeaver

/// entry poiint for  errors
public typealias Log = SwiftyBeaver

public extension Log {
    typealias Xcode = ConsoleDestination
    typealias Local = FileDestination
    typealias Remote = SBPlatformDestination
}
