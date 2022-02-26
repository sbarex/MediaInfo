//
//  Metadata.swift
//  MediaInfo
//
//  Created by Sbarex on 08/02/22.
//  Copyright © 2022 sbarex. All rights reserved.
//

import Foundation
import AVFoundation

protocol MetadataInfo: Codable {
    static func getTags() -> [(code: CFString, label: String)]
    static func getLabel(for code: CFString) -> String
    static func getPos(of code: CFString) -> Int
    
    var code: CFString { get }
    var label: String { get }
    var value: String { get }
    var index: Int { get }
    var isHidden: Bool { get }
    
    init?(code: CFString, value: AnyHashable)
    func encode(to encoder: Encoder) throws
}

@objc
class MetadataBaseInfo: NSObject, MetadataInfo {
    enum CodingKeys: String, CodingKey {
        case code
        case label
        case value
    }
    
    class var supportsSecureCoding: Bool {
        return true
    }
    
    class func processCFValue(code: CFString, value: AnyHashable) -> String {
        if let value = value as? NSNumber {
            return "\(value)"
        } else if let value = value as? String {
            return value
        } else if let value = value as? Date {
            let d = DateFormatter()
            return d.string(from: value)
        } else if let value = value as? [AnyHashable] {
            let v = value.map({ processCFValue(code: code, value: $0) })
            if v.count > 1 {
                return "[" + v.joined(separator: ", ") + "]"
            } else if let v = v.first {
                return v
            } else {
                return ""
            }
        } else {
            return "\(value)"
        }
    }
    
    class func getTags() -> [(code: CFString, label: String)] {
        return []
    }
    
    class func getLabel(for code: CFString)->String {
        let tags = getTags()
        if let item = tags.first(where: {$0.code == code }) {
            return item.label
        } else {
            let t = initTag(for: code)
            return t.label
        }
    }
    
    class func getPos(of code: CFString)->Int {
        let tags = getTags()
        if let index = tags.firstIndex(where: {$0.code == code }) {
            return index
        } else {
            return tags.count + 1
        }
    }
    
    class func initTag(for code: CFString) -> (code: CFString, label: String) {
        let s = code as String
        let regex = try! NSRegularExpression(pattern: "[A-Z][a-z]", options:[])
        let range = NSMakeRange(0, s.count)
        var words: [Substring] = []
        var prev_index = s.startIndex
        for m in regex.matches(in: s, options: [], range: range) {
            let index = s.index(s.startIndex, offsetBy: m.range.location)
            guard prev_index != index else {
                continue
            }
            let word = s[prev_index ..< index]
            words.append(word)
            prev_index = index
        }
        if prev_index < s.endIndex {
            words.append(s[prev_index ..< s.endIndex])
        }
        let w = words.map({ word -> String in
            if ["on", "in", "per", "for", "a", "an", "the"].contains(word.lowercased()) {
                return word.lowercased()
            } else {
                return String(word)
            }
        })
        let label = w.joined(separator: " ")
        
        // let label = (code as String).uncamelizing()
        return (code: code, label: label)
    }
    
    let code: CFString
    let value: String
    
    var isHidden: Bool {
        return false
    }
    
    lazy fileprivate(set) var label: String = {
        return type(of: self).getLabel(for: self.code)
    }()
    
    lazy fileprivate(set) var index: Int = {
        return type(of: self).getPos(of: self.code)
    }()
    
    required init?(code: CFString, value: AnyHashable) {
        guard Int(code as String) == nil else {
            return nil
        }
        self.code = code
        self.value = type(of: self).processCFValue(code: code, value: value)
        super.init()
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.code = try container.decode(String.self, forKey: .code) as CFString
        self.value = try container.decode(String.self, forKey: .value)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.code as String, forKey: .code)
        try container.encode(self.value, forKey: .value)
        
        if let b = encoder.userInfo[.exportStoredValues] as? Bool, b {
            try container.encode(self.label, forKey: .label)
        }
    }
}

class MetadataExifInfo: MetadataBaseInfo {
    override class var supportsSecureCoding: Bool {
        return true
    }
    override class func getTags() -> [(code: CFString, label: String)] {
        var tags = [
            initTag(for: kCGImagePropertyExifVersion),
            initTag(for: kCGImagePropertyExifFlashPixVersion),
            
            initTag(for: kCGImagePropertyExifFileSource),
            
            initTag(for: kCGImagePropertyExifPixelXDimension),
            initTag(for: kCGImagePropertyExifPixelYDimension),
            
            initTag(for: kCGImagePropertyExifColorSpace),
            initTag(for: kCGImagePropertyExifComponentsConfiguration),
            initTag(for: kCGImagePropertyExifCompressedBitsPerPixel),
            
            initTag(for: kCGImagePropertyExifFNumber),
            initTag(for: kCGImagePropertyExifExposureTime),
            initTag(for: kCGImagePropertyExifExposureMode),
            initTag(for: kCGImagePropertyExifExposureIndex),
            initTag(for: kCGImagePropertyExifRecommendedExposureIndex),
            initTag(for: kCGImagePropertyExifExposureProgram),
            initTag(for: kCGImagePropertyExifExposureBiasValue),
            
            initTag(for: kCGImagePropertyExifBrightnessValue),
            initTag(for: kCGImagePropertyExifContrast),
            initTag(for: kCGImagePropertyExifSaturation),
            initTag(for: kCGImagePropertyExifSharpness),
            initTag(for: kCGImagePropertyExifGamma),
            initTag(for: kCGImagePropertyExifGainControl),
            initTag(for: kCGImagePropertyExifWhiteBalance),
            
            initTag(for: kCGImagePropertyExifSpectralSensitivity),
            initTag(for: kCGImagePropertyExifSensitivityType),
            initTag(for: kCGImagePropertyExifStandardOutputSensitivity),
            
            initTag(for: kCGImagePropertyExifApertureValue),
            initTag(for: kCGImagePropertyExifMaxApertureValue),
            
            initTag(for: kCGImagePropertyExifISOSpeedRatings),
            initTag(for: kCGImagePropertyExifISOSpeed),
            (code: kCGImagePropertyExifISOSpeedLatitudeyyy, label: "ISO Speed Latitude yyy"),
            (code: kCGImagePropertyExifISOSpeedLatitudezzz, label: "ISO Speed Latitude zzz"),
            initTag(for: kCGImagePropertyExifShutterSpeedValue),
            
            initTag(for: kCGImagePropertyExifDateTimeOriginal),
            initTag(for: kCGImagePropertyExifDateTimeDigitized),
            initTag(for: kCGImagePropertyExifSubsecTime),
            initTag(for: kCGImagePropertyExifSubsecTimeOriginal),
            initTag(for: kCGImagePropertyExifSubsecTimeDigitized),
            
            initTag(for: kCGImagePropertyExifMeteringMode),
            initTag(for: kCGImagePropertyExifLightSource),
            initTag(for: kCGImagePropertyExifFlash),
            initTag(for: kCGImagePropertyExifFlashEnergy),
            initTag(for: kCGImagePropertyExifSpatialFrequencyResponse),
            
            initTag(for: kCGImagePropertyExifFocalLength),
            (code: kCGImagePropertyExifFocalLenIn35mmFilm, label: "Focal Length in 35mm Film"),
            initTag(for: kCGImagePropertyExifFocalPlaneXResolution),
            initTag(for: kCGImagePropertyExifFocalPlaneYResolution),
            initTag(for: kCGImagePropertyExifFocalPlaneResolutionUnit),
            
            initTag(for: kCGImagePropertyExifSubjectLocation),
            initTag(for: kCGImagePropertyExifSubjectDistance),
            initTag(for: kCGImagePropertyExifSubjectDistRange),
            initTag(for: kCGImagePropertyExifSubjectArea),
            initTag(for: kCGImagePropertyExifSensingMethod),
            initTag(for: kCGImagePropertyExifSceneType),
            initTag(for: kCGImagePropertyExifSceneCaptureType),
            initTag(for: kCGImagePropertyExifCustomRendered),
            initTag(for: kCGImagePropertyExifDigitalZoomRatio),
            
            initTag(for: kCGImagePropertyExifCameraOwnerName),
            initTag(for: kCGImagePropertyExifBodySerialNumber),
            initTag(for: kCGImagePropertyExifDeviceSettingDescription),
            
            initTag(for: kCGImagePropertyExifLensSpecification),
            initTag(for: kCGImagePropertyExifLensMake),
            initTag(for: kCGImagePropertyExifLensModel),
            initTag(for: kCGImagePropertyExifLensSerialNumber),
            
            initTag(for: kCGImagePropertyExifRelatedSoundFile),
            
            initTag(for: kCGImagePropertyExifCFAPattern),
            initTag(for: kCGImagePropertyExifOECF),
            initTag(for: kCGImagePropertyExifImageUniqueID),
            
            initTag(for: kCGImagePropertyExifMakerNote),
            initTag(for: kCGImagePropertyExifUserComment),
        ]
        
        if #available(macOS 10.15.1, *) {
            tags.append(initTag(for: kCGImagePropertyExifCompositeImage))
            tags.append(initTag(for: kCGImagePropertyExifSourceImageNumberOfCompositeImage))
            tags.append(initTag(for: kCGImagePropertyExifSourceExposureTimesOfCompositeImage))
        } else if #available(macOS 10.15, *) {
            tags.append(initTag(for: kCGImagePropertyExifOffsetTime))
            tags.append(initTag(for: kCGImagePropertyExifOffsetTimeOriginal))
            tags.append(initTag(for: kCGImagePropertyExifOffsetTimeDigitized))
        }
        
        return tags
    }
    
    override class func processCFValue(code: CFString, value: AnyHashable) -> String {
        if code == kCGImagePropertyExifVersion, let value = value as? [AnyHashable] {
            let v = value.map({ processCFValue(code: code, value: $0) })
            return v.joined(separator: ".")
        }
        return super.processCFValue(code: code, value: value)
    }

    required init?(code: CFString, value: AnyHashable) {
        if code == kCGImagePropertyExifExposureTime, let value = value as? NSNumber {
            let f = value.doubleValue.rationalApproximation()
            super.init(code: code, value: "\(f.num)/\(f.den)")
        } else {
            super.init(code: code, value: value)
        }
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}

class MetadataExifAuxInfo: MetadataExifInfo {
    override class var supportsSecureCoding: Bool {
        return true
    }
    
    override class func getTags() -> [(code: CFString, label: String)] {
        let tags = [
            initTag(for: kCGImagePropertyExifAuxLensInfo),
            initTag(for: kCGImagePropertyExifAuxLensModel),
            initTag(for: kCGImagePropertyExifAuxLensID),
            initTag(for: kCGImagePropertyExifAuxLensSerialNumber),
            
            initTag(for: kCGImagePropertyExifAuxImageNumber),
            
            initTag(for: kCGImagePropertyExifAuxFlashCompensation),
            initTag(for: kCGImagePropertyExifAuxOwnerName),
            initTag(for: kCGImagePropertyExifAuxSerialNumber),
            initTag(for: kCGImagePropertyExifAuxFirmware),
        ]
        
        return tags
    }
    
    required init?(code: CFString, value: AnyHashable) {
        super.init(code: code, value: value)
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}

class MetadataTiffInfo: MetadataBaseInfo {
    override class var supportsSecureCoding: Bool {
        return true
    }
    
    override class func getTags() -> [(code: CFString, label: String)] {
        let tags = [
            initTag(for: kCGImagePropertyTIFFDocumentName),
            initTag(for: kCGImagePropertyTIFFImageDescription),
            initTag(for: kCGImagePropertyTIFFArtist),
            initTag(for: kCGImagePropertyTIFFDateTime),
            
            initTag(for: kCGImagePropertyTIFFCopyright),
            initTag(for: kCGImagePropertyTIFFSoftware),
            initTag(for: kCGImagePropertyTIFFMake),
            initTag(for: kCGImagePropertyTIFFModel),
            
            initTag(for: kCGImagePropertyTIFFOrientation),
            initTag(for: kCGImagePropertyTIFFXResolution),
            initTag(for: kCGImagePropertyTIFFYResolution),
            initTag(for: kCGImagePropertyTIFFResolutionUnit),
            
            initTag(for: kCGImagePropertyTIFFTileWidth),
            initTag(for: kCGImagePropertyTIFFTileLength),
            
            initTag(for: kCGImagePropertyTIFFWhitePoint),
            initTag(for: kCGImagePropertyTIFFCompression),
            initTag(for: kCGImagePropertyTIFFPhotometricInterpretation),
            initTag(for: kCGImagePropertyTIFFTransferFunction),
            initTag(for: kCGImagePropertyTIFFPrimaryChromaticities),
            
            initTag(for: kCGImagePropertyTIFFHostComputer),
        ]
        
        return tags
    }
    
    required init?(code: CFString, value: AnyHashable) {
        super.init(code: code, value: value)
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}

class MetadataJfifInfo: MetadataBaseInfo {
    override class var supportsSecureCoding: Bool {
        return true
    }
    
    override class func getTags() -> [(code: CFString, label: String)] {
        let tags = [
            initTag(for: kCGImagePropertyJFIFVersion),
            initTag(for: kCGImagePropertyJFIFXDensity),
            initTag(for: kCGImagePropertyJFIFYDensity),
            initTag(for: kCGImagePropertyJFIFDensityUnit),
            initTag(for: kCGImagePropertyJFIFIsProgressive),
        ]
        
        return tags
    }
    
    override class func processCFValue(code: CFString, value: AnyHashable) -> String {
        if code == kCGImagePropertyJFIFIsProgressive, let n = value as? NSNumber {
            return n.boolValue ? "yes" : "no"
        }
        return super.processCFValue(code: code, value: value)
    }
    
    required init?(code: CFString, value: AnyHashable) {
        super.init(code: code, value: value)
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}

class MetadataGifInfo: MetadataBaseInfo {
    override class var supportsSecureCoding: Bool {
        return true
    }
    
    override class func getTags() -> [(code: CFString, label: String)] {
        var tags = [
            initTag(for: kCGImagePropertyGIFLoopCount),
            initTag(for: kCGImagePropertyGIFDelayTime),
            initTag(for: kCGImagePropertyGIFImageColorMap),
            initTag(for: kCGImagePropertyGIFHasGlobalColorMap),
            initTag(for: kCGImagePropertyGIFUnclampedDelayTime)
        ]
        if #available(macOS 10.15, *) {
            tags.append(initTag(for: kCGImagePropertyGIFCanvasPixelWidth))
            tags.append(initTag(for: kCGImagePropertyGIFCanvasPixelHeight))
            tags.append(initTag(for: kCGImagePropertyGIFFrameInfoArray))
        }
        return tags
    }
    
    override class func processCFValue(code: CFString, value: AnyHashable) -> String {
        if code == kCGImagePropertyGIFHasGlobalColorMap, let n = value as? NSNumber {
            return n.boolValue ? "yes" : "no"
        }
        return super.processCFValue(code: code, value: value)
    }
    
    required init?(code: CFString, value: AnyHashable) {
        super.init(code: code, value: value)
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}

class MetadataHeicsInfo: MetadataBaseInfo {
    override class var supportsSecureCoding: Bool {
        return true
    }
    
    override class func getTags() -> [(code: CFString, label: String)] {
        if #available(macOS 10.15, *) {
            let tags = [
                initTag(for: kCGImagePropertyHEICSLoopCount),
                initTag(for: kCGImagePropertyHEICSDelayTime),
                initTag(for: kCGImagePropertyHEICSUnclampedDelayTime),
                initTag(for: kCGImagePropertyHEICSCanvasPixelWidth),
                initTag(for: kCGImagePropertyHEICSCanvasPixelHeight),
                initTag(for: kCGImagePropertyHEICSFrameInfoArray)
            ]
            return tags
        } else {
            return []
        }
    }
    
    required init?(code: CFString, value: AnyHashable) {
        super.init(code: code, value: value)
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}

class MetadataPngInfo: MetadataBaseInfo {
    override class var supportsSecureCoding: Bool {
        return true
    }
    
    override class func getTags() -> [(code: CFString, label: String)] {
        var tags = [
            initTag(for: kCGImagePropertyPNGAuthor),
            initTag(for: kCGImagePropertyPNGTitle),
            initTag(for: kCGImagePropertyPNGDescription),
            initTag(for: kCGImagePropertyPNGComment),
            initTag(for: kCGImagePropertyPNGDisclaimer),
            initTag(for: kCGImagePropertyPNGCopyright),
            initTag(for: kCGImagePropertyPNGWarning),
            
            initTag(for: kCGImagePropertyPNGCreationTime),
            initTag(for: kCGImagePropertyPNGModificationTime),
            initTag(for: kCGImagePropertyPNGInterlaceType),
            
            initTag(for: kCGImagePropertyPNGSoftware),
            
            initTag(for: kCGImagePropertyPNGSource),
            
            initTag(for: kCGImagePropertyPNGChromaticities),
            (code: kCGImagePropertyPNGsRGBIntent, label: "sRGB Intent"),
            
            initTag(for: kCGImagePropertyPNGXPixelsPerMeter),
            initTag(for: kCGImagePropertyPNGYPixelsPerMeter),
            
            initTag(for: kCGImagePropertyAPNGLoopCount),
            initTag(for: kCGImagePropertyAPNGDelayTime),
            initTag(for: kCGImagePropertyAPNGUnclampedDelayTime)
        ]
        
        if #available(macOS 12.0, *) {
            tags.append(initTag(for: kCGImagePropertyPNGPixelsAspectRatio))
        }
        
        if #available(macOS 10.15, *) {
            tags.append(initTag(for: kCGImagePropertyAPNGFrameInfoArray))
            tags.append(initTag(for: kCGImagePropertyAPNGCanvasPixelWidth))
            tags.append(initTag(for: kCGImagePropertyAPNGCanvasPixelHeight))
        }
        
        return tags
    }
    
    required init?(code: CFString, value: AnyHashable) {
        super.init(code: code, value: value)
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}

class MetadataIPTCInfo: MetadataBaseInfo {
    override class var supportsSecureCoding: Bool {
        return true
    }
    
    override class func getTags() -> [(code: CFString, label: String)] {
        return [
            initTag(for: kCGImagePropertyIPTCObjectTypeReference),
            initTag(for: kCGImagePropertyIPTCObjectAttributeReference),
            initTag(for: kCGImagePropertyIPTCObjectName),
            initTag(for: kCGImagePropertyIPTCEditStatus),
            initTag(for: kCGImagePropertyIPTCEditorialUpdate),
            initTag(for: kCGImagePropertyIPTCUrgency),
            initTag(for: kCGImagePropertyIPTCSubjectReference),
            initTag(for: kCGImagePropertyIPTCCategory),
            initTag(for: kCGImagePropertyIPTCSupplementalCategory),
            initTag(for: kCGImagePropertyIPTCFixtureIdentifier),
            initTag(for: kCGImagePropertyIPTCKeywords),
            initTag(for: kCGImagePropertyIPTCContentLocationCode),
            initTag(for: kCGImagePropertyIPTCContentLocationName),
            initTag(for: kCGImagePropertyIPTCReleaseDate),
            initTag(for: kCGImagePropertyIPTCReleaseTime),
            initTag(for: kCGImagePropertyIPTCExpirationDate),
            initTag(for: kCGImagePropertyIPTCExpirationTime),
            initTag(for: kCGImagePropertyIPTCSpecialInstructions),
            initTag(for: kCGImagePropertyIPTCActionAdvised),
            initTag(for: kCGImagePropertyIPTCReferenceService),
            initTag(for: kCGImagePropertyIPTCReferenceDate),
            initTag(for: kCGImagePropertyIPTCReferenceNumber),
            initTag(for: kCGImagePropertyIPTCDateCreated),
            initTag(for: kCGImagePropertyIPTCTimeCreated),
            initTag(for: kCGImagePropertyIPTCDigitalCreationDate),
            initTag(for: kCGImagePropertyIPTCDigitalCreationTime),
            initTag(for: kCGImagePropertyIPTCOriginatingProgram),
            initTag(for: kCGImagePropertyIPTCProgramVersion),
            initTag(for: kCGImagePropertyIPTCObjectCycle),
            initTag(for: kCGImagePropertyIPTCByline),
            initTag(for: kCGImagePropertyIPTCBylineTitle),
            initTag(for: kCGImagePropertyIPTCCity),
            initTag(for: kCGImagePropertyIPTCSubLocation),
            initTag(for: kCGImagePropertyIPTCProvinceState),
            initTag(for: kCGImagePropertyIPTCCountryPrimaryLocationCode),
            initTag(for: kCGImagePropertyIPTCCountryPrimaryLocationName),
            initTag(for: kCGImagePropertyIPTCOriginalTransmissionReference),
            initTag(for: kCGImagePropertyIPTCHeadline),
            initTag(for: kCGImagePropertyIPTCCredit),
            initTag(for: kCGImagePropertyIPTCSource),
            initTag(for: kCGImagePropertyIPTCCopyrightNotice),
            initTag(for: kCGImagePropertyIPTCContact),
            initTag(for: kCGImagePropertyIPTCCaptionAbstract),
            initTag(for: kCGImagePropertyIPTCWriterEditor),
            initTag(for: kCGImagePropertyIPTCImageType),
            initTag(for: kCGImagePropertyIPTCImageOrientation),
            initTag(for: kCGImagePropertyIPTCLanguageIdentifier),
            initTag(for: kCGImagePropertyIPTCStarRating),
            initTag(for: kCGImagePropertyIPTCCreatorContactInfo), // IPTC Core
            initTag(for: kCGImagePropertyIPTCRightsUsageTerms), // IPTC Core
            initTag(for: kCGImagePropertyIPTCScene), // IPTC Core
            initTag(for: kCGImagePropertyIPTCExtAboutCvTerm),
            initTag(for: kCGImagePropertyIPTCExtAboutCvTermCvId),
            initTag(for: kCGImagePropertyIPTCExtAboutCvTermId),
            initTag(for: kCGImagePropertyIPTCExtAboutCvTermName),
            initTag(for: kCGImagePropertyIPTCExtAboutCvTermRefinedAbout),
            initTag(for: kCGImagePropertyIPTCExtAddlModelInfo),
            initTag(for: kCGImagePropertyIPTCExtArtworkOrObject),
            initTag(for: kCGImagePropertyIPTCExtArtworkCircaDateCreated),
            initTag(for: kCGImagePropertyIPTCExtArtworkContentDescription),
            initTag(for: kCGImagePropertyIPTCExtArtworkContributionDescription),
            initTag(for: kCGImagePropertyIPTCExtArtworkCopyrightNotice),
            initTag(for: kCGImagePropertyIPTCExtArtworkCreator),
            initTag(for: kCGImagePropertyIPTCExtArtworkCreatorID),
            initTag(for: kCGImagePropertyIPTCExtArtworkCopyrightOwnerID),
            initTag(for: kCGImagePropertyIPTCExtArtworkCopyrightOwnerName),
            initTag(for: kCGImagePropertyIPTCExtArtworkLicensorID),
            initTag(for: kCGImagePropertyIPTCExtArtworkLicensorName),
            initTag(for: kCGImagePropertyIPTCExtArtworkDateCreated),
            initTag(for: kCGImagePropertyIPTCExtArtworkPhysicalDescription),
            initTag(for: kCGImagePropertyIPTCExtArtworkSource),
            initTag(for: kCGImagePropertyIPTCExtArtworkSourceInventoryNo),
            initTag(for: kCGImagePropertyIPTCExtArtworkSourceInvURL),
            initTag(for: kCGImagePropertyIPTCExtArtworkStylePeriod),
            initTag(for: kCGImagePropertyIPTCExtArtworkTitle),
            initTag(for: kCGImagePropertyIPTCExtAudioBitrate),
            initTag(for: kCGImagePropertyIPTCExtAudioBitrateMode),
            initTag(for: kCGImagePropertyIPTCExtAudioChannelCount),
            initTag(for: kCGImagePropertyIPTCExtCircaDateCreated),
            initTag(for: kCGImagePropertyIPTCExtContainerFormat),
            initTag(for: kCGImagePropertyIPTCExtContainerFormatIdentifier),
            initTag(for: kCGImagePropertyIPTCExtContainerFormatName),
            initTag(for: kCGImagePropertyIPTCExtContributor),
            initTag(for: kCGImagePropertyIPTCExtContributorIdentifier),
            initTag(for: kCGImagePropertyIPTCExtContributorName),
            initTag(for: kCGImagePropertyIPTCExtContributorRole),
            initTag(for: kCGImagePropertyIPTCExtCopyrightYear),
            initTag(for: kCGImagePropertyIPTCExtCreator),
            initTag(for: kCGImagePropertyIPTCExtCreatorIdentifier),
            initTag(for: kCGImagePropertyIPTCExtCreatorName),
            initTag(for: kCGImagePropertyIPTCExtCreatorRole),
            initTag(for: kCGImagePropertyIPTCExtControlledVocabularyTerm),
            initTag(for: kCGImagePropertyIPTCExtDataOnScreen),
            initTag(for: kCGImagePropertyIPTCExtDataOnScreenRegion),
            initTag(for: kCGImagePropertyIPTCExtDataOnScreenRegionD),
            initTag(for: kCGImagePropertyIPTCExtDataOnScreenRegionH),
            initTag(for: kCGImagePropertyIPTCExtDataOnScreenRegionText),
            initTag(for: kCGImagePropertyIPTCExtDataOnScreenRegionUnit),
            initTag(for: kCGImagePropertyIPTCExtDataOnScreenRegionW),
            initTag(for: kCGImagePropertyIPTCExtDataOnScreenRegionX),
            initTag(for: kCGImagePropertyIPTCExtDataOnScreenRegionY),
            initTag(for: kCGImagePropertyIPTCExtDigitalImageGUID),
            initTag(for: kCGImagePropertyIPTCExtDigitalSourceFileType),
            initTag(for: kCGImagePropertyIPTCExtDigitalSourceType),
            initTag(for: kCGImagePropertyIPTCExtDopesheet),
            initTag(for: kCGImagePropertyIPTCExtDopesheetLink),
            initTag(for: kCGImagePropertyIPTCExtDopesheetLinkLink),
            initTag(for: kCGImagePropertyIPTCExtDopesheetLinkLinkQualifier),
            initTag(for: kCGImagePropertyIPTCExtEmbdEncRightsExpr),
            initTag(for: kCGImagePropertyIPTCExtEmbeddedEncodedRightsExpr),
            initTag(for: kCGImagePropertyIPTCExtEmbeddedEncodedRightsExprType),
            initTag(for: kCGImagePropertyIPTCExtEmbeddedEncodedRightsExprLangID),
            initTag(for: kCGImagePropertyIPTCExtEpisode),
            initTag(for: kCGImagePropertyIPTCExtEpisodeIdentifier),
            initTag(for: kCGImagePropertyIPTCExtEpisodeName),
            initTag(for: kCGImagePropertyIPTCExtEpisodeNumber),
            initTag(for: kCGImagePropertyIPTCExtEvent),
            initTag(for: kCGImagePropertyIPTCExtShownEvent),
            initTag(for: kCGImagePropertyIPTCExtShownEventIdentifier),
            initTag(for: kCGImagePropertyIPTCExtShownEventName),
            initTag(for: kCGImagePropertyIPTCExtExternalMetadataLink),
            initTag(for: kCGImagePropertyIPTCExtFeedIdentifier),
            initTag(for: kCGImagePropertyIPTCExtGenre),
            initTag(for: kCGImagePropertyIPTCExtGenreCvId),
            initTag(for: kCGImagePropertyIPTCExtGenreCvTermId),
            initTag(for: kCGImagePropertyIPTCExtGenreCvTermName),
            initTag(for: kCGImagePropertyIPTCExtGenreCvTermRefinedAbout),
            initTag(for: kCGImagePropertyIPTCExtHeadline),
            initTag(for: kCGImagePropertyIPTCExtIPTCLastEdited),
            initTag(for: kCGImagePropertyIPTCExtLinkedEncRightsExpr),
            initTag(for: kCGImagePropertyIPTCExtLinkedEncodedRightsExpr),
            initTag(for: kCGImagePropertyIPTCExtLinkedEncodedRightsExprType),
            initTag(for: kCGImagePropertyIPTCExtLinkedEncodedRightsExprLangID),
            initTag(for: kCGImagePropertyIPTCExtLocationCreated),
            initTag(for: kCGImagePropertyIPTCExtLocationCity),
            initTag(for: kCGImagePropertyIPTCExtLocationCountryCode),
            initTag(for: kCGImagePropertyIPTCExtLocationCountryName),
            initTag(for: kCGImagePropertyIPTCExtLocationGPSAltitude),
            initTag(for: kCGImagePropertyIPTCExtLocationGPSLatitude),
            initTag(for: kCGImagePropertyIPTCExtLocationGPSLongitude),
            initTag(for: kCGImagePropertyIPTCExtLocationIdentifier),
            initTag(for: kCGImagePropertyIPTCExtLocationLocationId),
            initTag(for: kCGImagePropertyIPTCExtLocationLocationName),
            initTag(for: kCGImagePropertyIPTCExtLocationProvinceState),
            initTag(for: kCGImagePropertyIPTCExtLocationSublocation),
            initTag(for: kCGImagePropertyIPTCExtLocationWorldRegion),
            initTag(for: kCGImagePropertyIPTCExtLocationShown),
            initTag(for: kCGImagePropertyIPTCExtMaxAvailHeight),
            initTag(for: kCGImagePropertyIPTCExtMaxAvailWidth),
            initTag(for: kCGImagePropertyIPTCExtModelAge),
            initTag(for: kCGImagePropertyIPTCExtOrganisationInImageCode),
            initTag(for: kCGImagePropertyIPTCExtOrganisationInImageName),
            initTag(for: kCGImagePropertyIPTCExtPersonHeard),
            initTag(for: kCGImagePropertyIPTCExtPersonHeardIdentifier),
            initTag(for: kCGImagePropertyIPTCExtPersonHeardName),
            initTag(for: kCGImagePropertyIPTCExtPersonInImage),
            initTag(for: kCGImagePropertyIPTCExtPersonInImageWDetails),
            initTag(for: kCGImagePropertyIPTCExtPersonInImageCharacteristic),
            initTag(for: kCGImagePropertyIPTCExtPersonInImageCvTermCvId),
            initTag(for: kCGImagePropertyIPTCExtPersonInImageCvTermId),
            initTag(for: kCGImagePropertyIPTCExtPersonInImageCvTermName),
            initTag(for: kCGImagePropertyIPTCExtPersonInImageCvTermRefinedAbout),
            initTag(for: kCGImagePropertyIPTCExtPersonInImageDescription),
            initTag(for: kCGImagePropertyIPTCExtPersonInImageId),
            initTag(for: kCGImagePropertyIPTCExtPersonInImageName),
            initTag(for: kCGImagePropertyIPTCExtProductInImage),
            initTag(for: kCGImagePropertyIPTCExtProductInImageDescription),
            initTag(for: kCGImagePropertyIPTCExtProductInImageGTIN),
            initTag(for: kCGImagePropertyIPTCExtProductInImageName),
            initTag(for: kCGImagePropertyIPTCExtPublicationEvent),
            initTag(for: kCGImagePropertyIPTCExtPublicationEventDate),
            initTag(for: kCGImagePropertyIPTCExtPublicationEventIdentifier),
            initTag(for: kCGImagePropertyIPTCExtPublicationEventName),
            initTag(for: kCGImagePropertyIPTCExtRating),
            initTag(for: kCGImagePropertyIPTCExtRatingRatingRegion),
            initTag(for: kCGImagePropertyIPTCExtRatingRegionCity),
            initTag(for: kCGImagePropertyIPTCExtRatingRegionCountryCode),
            initTag(for: kCGImagePropertyIPTCExtRatingRegionCountryName),
            initTag(for: kCGImagePropertyIPTCExtRatingRegionGPSAltitude),
            initTag(for: kCGImagePropertyIPTCExtRatingRegionGPSLatitude),
            initTag(for: kCGImagePropertyIPTCExtRatingRegionGPSLongitude),
            initTag(for: kCGImagePropertyIPTCExtRatingRegionIdentifier),
            initTag(for: kCGImagePropertyIPTCExtRatingRegionLocationId),
            initTag(for: kCGImagePropertyIPTCExtRatingRegionLocationName),
            initTag(for: kCGImagePropertyIPTCExtRatingRegionProvinceState),
            initTag(for: kCGImagePropertyIPTCExtRatingRegionSublocation),
            initTag(for: kCGImagePropertyIPTCExtRatingRegionWorldRegion),
            initTag(for: kCGImagePropertyIPTCExtRatingScaleMaxValue),
            initTag(for: kCGImagePropertyIPTCExtRatingScaleMinValue),
            initTag(for: kCGImagePropertyIPTCExtRatingSourceLink),
            initTag(for: kCGImagePropertyIPTCExtRatingValue),
            initTag(for: kCGImagePropertyIPTCExtRatingValueLogoLink),
            initTag(for: kCGImagePropertyIPTCExtRegistryID),
            initTag(for: kCGImagePropertyIPTCExtRegistryEntryRole),
            initTag(for: kCGImagePropertyIPTCExtRegistryItemID),
            initTag(for: kCGImagePropertyIPTCExtRegistryOrganisationID),
            initTag(for: kCGImagePropertyIPTCExtReleaseReady),
            initTag(for: kCGImagePropertyIPTCExtSeason),
            initTag(for: kCGImagePropertyIPTCExtSeasonIdentifier),
            initTag(for: kCGImagePropertyIPTCExtSeasonName),
            initTag(for: kCGImagePropertyIPTCExtSeasonNumber),
            initTag(for: kCGImagePropertyIPTCExtSeries),
            initTag(for: kCGImagePropertyIPTCExtSeriesIdentifier),
            initTag(for: kCGImagePropertyIPTCExtSeriesName),
            initTag(for: kCGImagePropertyIPTCExtStorylineIdentifier),
            initTag(for: kCGImagePropertyIPTCExtStreamReady),
            initTag(for: kCGImagePropertyIPTCExtStylePeriod),
            initTag(for: kCGImagePropertyIPTCExtSupplyChainSource),
            initTag(for: kCGImagePropertyIPTCExtSupplyChainSourceIdentifier),
            initTag(for: kCGImagePropertyIPTCExtSupplyChainSourceName),
            initTag(for: kCGImagePropertyIPTCExtTemporalCoverage),
            initTag(for: kCGImagePropertyIPTCExtTemporalCoverageFrom),
            initTag(for: kCGImagePropertyIPTCExtTemporalCoverageTo),
            initTag(for: kCGImagePropertyIPTCExtTranscript),
            initTag(for: kCGImagePropertyIPTCExtTranscriptLink),
            initTag(for: kCGImagePropertyIPTCExtTranscriptLinkLink),
            initTag(for: kCGImagePropertyIPTCExtTranscriptLinkLinkQualifier),
            initTag(for: kCGImagePropertyIPTCExtVideoBitrate),
            initTag(for: kCGImagePropertyIPTCExtVideoBitrateMode),
            initTag(for: kCGImagePropertyIPTCExtVideoDisplayAspectRatio),
            initTag(for: kCGImagePropertyIPTCExtVideoEncodingProfile),
            initTag(for: kCGImagePropertyIPTCExtVideoShotType),
            initTag(for: kCGImagePropertyIPTCExtVideoShotTypeIdentifier),
            initTag(for: kCGImagePropertyIPTCExtVideoShotTypeName),
            initTag(for: kCGImagePropertyIPTCExtVideoStreamsCount),
            initTag(for: kCGImagePropertyIPTCExtVisualColor),
            initTag(for: kCGImagePropertyIPTCExtWorkflowTag),
            initTag(for: kCGImagePropertyIPTCExtWorkflowTagCvId),
            initTag(for: kCGImagePropertyIPTCExtWorkflowTagCvTermId),
            initTag(for: kCGImagePropertyIPTCExtWorkflowTagCvTermName),
            initTag(for: kCGImagePropertyIPTCExtWorkflowTagCvTermRefinedAbout),
        ]
    }
    
    required init?(code: CFString, value: AnyHashable) {
        super.init(code: code, value: value)
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}

class MetadataGPSInfo: MetadataBaseInfo {
    override class var supportsSecureCoding: Bool {
        return true
    }
    
    override class func getTags() -> [(code: CFString, label: String)] {
        return [
            initTag(for: kCGImagePropertyGPSVersion),
            initTag(for: kCGImagePropertyGPSLatitudeRef),
            initTag(for: kCGImagePropertyGPSLatitude),
            initTag(for: kCGImagePropertyGPSLongitudeRef),
            initTag(for: kCGImagePropertyGPSLongitude),
            initTag(for: kCGImagePropertyGPSAltitudeRef),
            initTag(for: kCGImagePropertyGPSAltitude),
            initTag(for: kCGImagePropertyGPSTimeStamp),
            initTag(for: kCGImagePropertyGPSSatellites),
            initTag(for: kCGImagePropertyGPSStatus),
            initTag(for: kCGImagePropertyGPSMeasureMode),
            initTag(for: kCGImagePropertyGPSDOP),
            initTag(for: kCGImagePropertyGPSSpeedRef),
            initTag(for: kCGImagePropertyGPSSpeed),
            initTag(for: kCGImagePropertyGPSTrackRef),
            initTag(for: kCGImagePropertyGPSTrack),
            initTag(for: kCGImagePropertyGPSImgDirectionRef),
            initTag(for: kCGImagePropertyGPSImgDirection),
            initTag(for: kCGImagePropertyGPSMapDatum),
            initTag(for: kCGImagePropertyGPSDestLatitudeRef),
            initTag(for: kCGImagePropertyGPSDestLatitude),
            initTag(for: kCGImagePropertyGPSDestLongitudeRef),
            initTag(for: kCGImagePropertyGPSDestLongitude),
            initTag(for: kCGImagePropertyGPSDestBearingRef),
            initTag(for: kCGImagePropertyGPSDestBearing),
            initTag(for: kCGImagePropertyGPSDestDistanceRef),
            initTag(for: kCGImagePropertyGPSDestDistance),
            initTag(for: kCGImagePropertyGPSProcessingMethod),
            initTag(for: kCGImagePropertyGPSAreaInformation),
            initTag(for: kCGImagePropertyGPSDateStamp),
            initTag(for: kCGImagePropertyGPSDifferental),
            initTag(for: kCGImagePropertyGPSHPositioningError)
        ]
    }
    
    required init?(code: CFString, value: AnyHashable) {
        super.init(code: code, value: value)
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}


class MetadataDNGInfo: MetadataBaseInfo {
    override class var supportsSecureCoding: Bool {
        return true
    }
    override class func processCFValue(code: CFString, value: AnyHashable) -> String {
        switch code {
        case kCGImagePropertyDNGVersion, kCGImagePropertyDNGBackwardVersion:
            if let value = value as? [AnyHashable] {
                let v = value.map({ processCFValue(code: code, value: $0) })
                return v.joined(separator: ".")
            }
        default:
            break
        }
        
        return super.processCFValue(code: code, value: value)
    }
    
    override class func getTags() -> [(code: CFString, label: String)] {
        return [
            initTag(for: kCGImagePropertyDNGVersion),
            initTag(for: kCGImagePropertyDNGBackwardVersion),
            
            initTag(for: kCGImagePropertyDNGUniqueCameraModel),
            initTag(for: kCGImagePropertyDNGLocalizedCameraModel),
            initTag(for: kCGImagePropertyDNGCameraSerialNumber),
            
            initTag(for: kCGImagePropertyDNGLensInfo),
            
            initTag(for: kCGImagePropertyDNGBlackLevel),
            initTag(for: kCGImagePropertyDNGWhiteLevel),
            initTag(for: kCGImagePropertyDNGAsShotWhiteXY),
            
            initTag(for: kCGImagePropertyDNGCalibrationIlluminant1),
            initTag(for: kCGImagePropertyDNGCalibrationIlluminant2),
            initTag(for: kCGImagePropertyDNGColorMatrix1),
            initTag(for: kCGImagePropertyDNGColorMatrix2),
            initTag(for: kCGImagePropertyDNGCameraCalibration1),
            initTag(for: kCGImagePropertyDNGCameraCalibration2),
            
            initTag(for: kCGImagePropertyDNGBaselineExposure),
            initTag(for: kCGImagePropertyDNGBaselineNoise),
            initTag(for: kCGImagePropertyDNGBaselineSharpness),
            
            initTag(for: kCGImagePropertyDNGPrivateData),
            
            initTag(for: kCGImagePropertyDNGCameraCalibrationSignature),
            initTag(for: kCGImagePropertyDNGProfileCalibrationSignature),
            
            initTag(for: kCGImagePropertyDNGNoiseProfile),
            initTag(for: kCGImagePropertyDNGWarpRectilinear),
            initTag(for: kCGImagePropertyDNGWarpFisheye),
            initTag(for: kCGImagePropertyDNGFixVignetteRadial),

            initTag(for: kCGImagePropertyDNGActiveArea),
            initTag(for: kCGImagePropertyDNGAnalogBalance),
            initTag(for: kCGImagePropertyDNGAntiAliasStrength),
            
            initTag(for: kCGImagePropertyDNGAsShotNeutral),
            initTag(for: kCGImagePropertyDNGAsShotICCProfile),
            initTag(for: kCGImagePropertyDNGAsShotPreProfileMatrix),
            initTag(for: kCGImagePropertyDNGAsShotProfileName),
            
            initTag(for: kCGImagePropertyDNGBaselineExposureOffset),
            
            initTag(for: kCGImagePropertyDNGBayerGreenSplit),
            initTag(for: kCGImagePropertyDNGBestQualityScale),
            
            initTag(for: kCGImagePropertyDNGBlackLevelDeltaH),
            initTag(for: kCGImagePropertyDNGBlackLevelDeltaV),
            initTag(for: kCGImagePropertyDNGBlackLevelRepeatDim),
            
            initTag(for: kCGImagePropertyDNGCFALayout),
            initTag(for: kCGImagePropertyDNGCFAPlaneColor),
            initTag(for: kCGImagePropertyDNGChromaBlurRadius),
            initTag(for: kCGImagePropertyDNGColorimetricReference),
            initTag(for: kCGImagePropertyDNGCurrentICCProfile),
            initTag(for: kCGImagePropertyDNGCurrentPreProfileMatrix),
            initTag(for: kCGImagePropertyDNGDefaultBlackRender),
            
            initTag(for: kCGImagePropertyDNGDefaultCropOrigin),
            initTag(for: kCGImagePropertyDNGDefaultCropSize),
            initTag(for: kCGImagePropertyDNGDefaultScale),
            initTag(for: kCGImagePropertyDNGDefaultUserCrop),
            initTag(for: kCGImagePropertyDNGExtraCameraProfiles),
            initTag(for: kCGImagePropertyDNGForwardMatrix1),
            initTag(for: kCGImagePropertyDNGForwardMatrix2),
            initTag(for: kCGImagePropertyDNGLinearizationTable),
            initTag(for: kCGImagePropertyDNGLinearResponseLimit),
            initTag(for: kCGImagePropertyDNGMakerNoteSafety),
            initTag(for: kCGImagePropertyDNGMaskedAreas),
            initTag(for: kCGImagePropertyDNGNewRawImageDigest),
            initTag(for: kCGImagePropertyDNGNoiseReductionApplied),
            initTag(for: kCGImagePropertyDNGOpcodeList1),
            initTag(for: kCGImagePropertyDNGOpcodeList2),
            initTag(for: kCGImagePropertyDNGOpcodeList3),
            initTag(for: kCGImagePropertyDNGOriginalBestQualityFinalSize),
            initTag(for: kCGImagePropertyDNGOriginalDefaultCropSize),
            initTag(for: kCGImagePropertyDNGOriginalDefaultFinalSize),
            initTag(for: kCGImagePropertyDNGOriginalRawFileData),
            initTag(for: kCGImagePropertyDNGOriginalRawFileDigest),
            initTag(for: kCGImagePropertyDNGOriginalRawFileName),
            initTag(for: kCGImagePropertyDNGPreviewApplicationName),
            initTag(for: kCGImagePropertyDNGPreviewApplicationVersion),
            initTag(for: kCGImagePropertyDNGPreviewColorSpace),
            initTag(for: kCGImagePropertyDNGPreviewDateTime),
            initTag(for: kCGImagePropertyDNGPreviewSettingsDigest),
            initTag(for: kCGImagePropertyDNGPreviewSettingsName),
            initTag(for: kCGImagePropertyDNGProfileCopyright),
            initTag(for: kCGImagePropertyDNGProfileEmbedPolicy),
            initTag(for: kCGImagePropertyDNGProfileHueSatMapData1),
            initTag(for: kCGImagePropertyDNGProfileHueSatMapData2),
            initTag(for: kCGImagePropertyDNGProfileHueSatMapDims),
            initTag(for: kCGImagePropertyDNGProfileHueSatMapEncoding),
            initTag(for: kCGImagePropertyDNGProfileLookTableData),
            initTag(for: kCGImagePropertyDNGProfileLookTableDims),
            initTag(for: kCGImagePropertyDNGProfileLookTableEncoding),
            initTag(for: kCGImagePropertyDNGProfileName),
            initTag(for: kCGImagePropertyDNGProfileToneCurve),
            initTag(for: kCGImagePropertyDNGRawDataUniqueID),
            initTag(for: kCGImagePropertyDNGRawImageDigest),
            initTag(for: kCGImagePropertyDNGRawToPreviewGain),
            
            initTag(for: kCGImagePropertyDNGReductionMatrix1),
            initTag(for: kCGImagePropertyDNGReductionMatrix2),
            initTag(for: kCGImagePropertyDNGRowInterleaveFactor),
            
            initTag(for: kCGImagePropertyDNGShadowScale),
            initTag(for: kCGImagePropertyDNGSubTileBlockSize),
        ]
    }
    
    override var isHidden: Bool {
        switch code {
        case
            kCGImagePropertyDNGColorMatrix1, kCGImagePropertyDNGColorMatrix2,
            kCGImagePropertyDNGForwardMatrix1, kCGImagePropertyDNGForwardMatrix2,
            kCGImagePropertyDNGNewRawImageDigest, kCGImagePropertyDNGOriginalRawFileDigest, kCGImagePropertyDNGPreviewSettingsDigest, kCGImagePropertyDNGRawImageDigest,
            kCGImagePropertyDNGRawDataUniqueID:
            return true
        default:
            return false
        }
    }
    required init?(code: CFString, value: AnyHashable) {
        super.init(code: code, value: value)
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}
