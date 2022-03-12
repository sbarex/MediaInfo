//
//  Settings+ext.swift
//  MediaInfoEx
//
//  Created by Sbarex on 12/02/22.
//  Copyright © 2022 sbarex. All rights reserved.
//

import Foundation

extension Settings.SupportedFile {
    var infoClass: BaseInfo.Type {
        switch self {
        case .none:
            return BaseInfo.self
        case .image:
            return ImageInfo.self
        case .video:
            return VideoInfo.self
        case .audio:
            return AudioInfo.self
        case .office:
            return BaseOfficeInfo.self
        case .pdf:
            return PDFInfo.self
        case .archive:
            return ArchiveInfo.self
        case .model:
            return ModelInfo.self
        case .folder:
            return FolderInfo.self
        case .videoTrakcs:
            return VideoTrackInfo.self
        case .audioTraks:
            return AudioTrackInfo.self
        }
    }
}
