//
//  NSNotification_Name+Ext.swift
//  MediaInfo Finder Extension
//
//  Created by Sbarex on 04/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Foundation

extension NSNotification.Name {
    static let MediaInfoMonitoredFolderChanged = NSNotification.Name(rawValue: "MediaInfoMonitoredFolderChanged")
    static let MediaInfoSettingsChanged = NSNotification.Name(rawValue: "MediaInfoSettingsChanged")
}
