//
//  Log.swift
//  Architecture
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
  
  static func setup() {
    let xcodeLog = Log.Console()
    xcodeLog.minLevel = .verbose
    xcodeLog.format = "$C$L - $M"
    xcodeLog.levelColor.verbose = "⚫️ "
    xcodeLog.levelColor.debug = "🟣 "
    xcodeLog.levelColor.info = "🔵 "
    xcodeLog.levelColor.warning = "🟡 "
    xcodeLog.levelColor.error = "🔴 "
    Log.addDestination(xcodeLog)
  }
}
