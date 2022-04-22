//
//  String+ext.swift
//  MediaInfo Finder Extension
//
//  Created by Sbarex on 09/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Foundation

/** Convert 3-char terminological language codes (ISO-IEC 639-2) to the 2-char code format (ISO/IEC 639-1) if available.
 */
func ISO649_2_to_1(code: String) -> String? {
    switch code.uppercased() {
    case "AAR": return "AA"
    case "ABK": return "AB"
    case "AFR": return "AF"
    case "AKA": return "AK"
    case "ALB (B)": return "SQ"
    case "AMH": return "AM"
    case "ARA": return "AR"
    case "ARG": return "AN"
    case "ARM (B)": return "HY"
    case "ASM": return "AS"
    case "AVA": return "AV"
    case "AVE": return "AE"
    case "AYM": return "AY"
    case "AZE": return "AZ"
    case "BAK": return "BA"
    case "BAM": return "BM"
    case "BAQ (B)": return "EU"
    case "BEL": return "BE"
    case "BEN": return "BN"
    case "BIH": return "BH"
    case "BIS": return "BI"
    case "BOD (T)": return "BO"
    case "BOS": return "BS"
    case "BRE": return "BR"
    case "BUL": return "BG"
    case "BUR (B)": return "MY"
    case "CAT": return "CA"
    case "CES (T)": return "CS"
    case "CHA": return "CH"
    case "CHE": return "CE"
    case "CHI (B)": return "ZH"
    case "CHU": return "CU"
    case "CHV": return "CV"
    case "COR": return "KW"
    case "COS": return "CO"
    case "CRE": return "CR"
    case "CYM (T)": return "CY"
    case "CZE (B)": return "CS"
    case "DAN": return "DA"
    case "DEU (T)": return "DE"
    case "DIV": return "DV"
    case "DUT (B)": return "NL"
    case "DZO": return "DZ"
    case "ELL (T)": return "EL"
    case "ENG": return "EN"
    case "EPO": return "EO"
    case "EST": return "ET"
    case "EUS (T)": return "EU"
    case "EWE": return "EE"
    case "FAO": return "FO"
    case "FAS (T)": return "FA"
    case "FIJ": return "FJ"
    case "FIN": return "FI"
    case "FRA (T)": return "FR"
    case "FRE (B)": return "FR"
    case "FRY": return "FY"
    case "FUL": return "FF"
    case "GEO (B)": return "KA"
    case "GER (B)": return "DE"
    case "GLA": return "GD"
    case "GLE": return "GA"
    case "GLG": return "GL"
    case "GLV": return "GV"
    case "GRE (B)": return "EL"
    case "GRN": return "GN"
    case "GUJ": return "GU"
    case "HAT": return "HT"
    case "HAU": return "HA"
    case "HEB": return "HE"
    case "HER": return "HZ"
    case "HIN": return "HI"
    case "HMO": return "HO"
    case "HRV": return "HR"
    case "HUN": return "HU"
    case "HYE (T)": return "HY"
    case "IBO": return "IG"
    case "ICE (B)": return "IS"
    case "IDO": return "IO"
    case "III": return "II"
    case "IKU": return "IU"
    case "ILE": return "IE"
    case "INA": return "IA"
    case "IND": return "ID"
    case "IPK": return "IK"
    case "ISL (T)": return "IS"
    case "ITA": return "IT"
    case "JAV": return "JV"
    case "JPN": return "JA"
    case "KAL": return "KL"
    case "KAN": return "KN"
    case "KAS": return "KS"
    case "KAT (T)": return "KA"
    case "KAU": return "KR"
    case "KAZ": return "KK"
    case "KHM": return "KM"
    case "KIK": return "KI"
    case "KIN": return "RW"
    case "KIR": return "KY"
    case "KOM": return "KV"
    case "KON": return "KG"
    case "KOR": return "KO"
    case "KUA": return "KJ"
    case "KUR": return "KU"
    case "LAO": return "LO"
    case "LAT": return "LA"
    case "LAV": return "LV"
    case "LIM": return "LI"
    case "LIN": return "LN"
    case "LIT": return "LT"
    case "LTZ": return "LB"
    case "LUB": return "LU"
    case "LUG": return "LG"
    case "MAC (B)": return "MK"
    case "MAH": return "MH"
    case "MAL": return "ML"
    case "MAO (B)": return "MI"
    case "MAR": return "MR"
    case "MAY (B)": return "MS"
    case "MKD (T)": return "MK"
    case "MLG": return "MG"
    case "MLT": return "MT"
    case "MON": return "MN"
    case "MRI (T)": return "MI"
    case "MSA (T)": return "MS"
    case "MYA (T)": return "MY"
    case "NAU": return "NA"
    case "NAV": return "NV"
    case "NBL": return "NR"
    case "NDE": return "ND"
    case "NDO": return "NG"
    case "NEP": return "NE"
    case "NLD (T)": return "NL"
    case "NNO": return "NN"
    case "NOB": return "NB"
    case "NOR": return "NO"
    case "NYA": return "NY"
    case "OCI": return "OC"
    case "OJI": return "OJ"
    case "ORI": return "OR"
    case "ORM": return "OM"
    case "OSS": return "OS"
    case "PAN": return "PA"
    case "PER (B)": return "FA"
    case "PLI": return "PI"
    case "POL": return "PL"
    case "POR": return "PT"
    case "PUS": return "PS"
    case "QUE": return "QU"
    case "ROH": return "RM"
    case "RON (T)": return "RO"
    case "RUM (B)": return "RO"
    case "RUN": return "RN"
    case "RUS": return "RU"
    case "SAG": return "SG"
    case "SAN": return "SA"
    case "SIN": return "SI"
    case "SLK (T)": return "SK"
    case "SLO (B)": return "SK"
    case "SLV": return "SL"
    case "SME": return "SE"
    case "SMO": return "SM"
    case "SNA": return "SN"
    case "SND": return "SD"
    case "SOM": return "SO"
    case "SOT": return "ST"
    case "SPA": return "ES"
    case "SQI (T)": return "SQ"
    case "SRD": return "SC"
    case "SRP": return "SR"
    case "SSW": return "SS"
    case "SUN": return "SU"
    case "SWA": return "SW"
    case "SWE": return "SV"
    case "TAH": return "TY"
    case "TAM": return "TA"
    case "TAT": return "TT"
    case "TEL": return "TE"
    case "TGK": return "TG"
    case "TGL": return "TL"
    case "THA": return "TH"
    case "TIB (B)": return "BO"
    case "TIR": return "TI"
    case "TON": return "TO"
    case "TSN": return "TN"
    case "TSO": return "TS"
    case "TUK": return "TK"
    case "TUR": return "TR"
    case "TWI": return "TW"
    case "UIG": return "UG"
    case "UKR": return "UK"
    case "URD": return "UR"
    case "UZB": return "UZ"
    case "VEN": return "VE"
    case "VIE": return "VI"
    case "VOL": return "VO"
    case "WEL (B)": return "CY"
    case "WLN": return "WA"
    case "WOL": return "WO"
    case "XHO": return "XH"
    case "YID": return "YI"
    case "YOR": return "YO"
    case "ZHA": return "ZA"
    case "ZHO (T)": return "ZH"
    case "ZUL": return "ZU"
    default: return nil
    }
}

extension NSMutableAttributedString {
    public func trimCharacters(in charSet: CharacterSet) {
        var range = (string as NSString).rangeOfCharacter(from: charSet as CharacterSet)

        // Trim leading characters from character set.
        while range.length != 0 && range.location == 0 {
            replaceCharacters(in: range, with: "")
            range = (string as NSString).rangeOfCharacter(from: charSet)
        }

        // Trim trailing characters from character set.
        range = (string as NSString).rangeOfCharacter(from: charSet, options: .backwards)
        while range.length != 0 && NSMaxRange(range) == length {
            replaceCharacters(in: range, with: "")
            range = (string as NSString).rangeOfCharacter(from: charSet, options: .backwards)
        }
    }

    func capitalizingFirstLetter() -> NSMutableAttributedString {
        let result = NSMutableAttributedString(attributedString: self)
        guard result.length > 0 else {
            return result
        }

        let s = result.attributedSubstring(from: NSRange(location: 0, length: 1)).string
        result.replaceCharacters(in: NSRange(location: 0, length: 1), with: s.uppercased())

        return result
    }
}

extension String {
    func matches(_ regex: String) -> Bool {
        return self.range(of: regex, options: .regularExpression, range: nil, locale: nil) != nil
    }
    
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }

    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
    
    func uncamelizing() -> String {
        let regex = try! NSRegularExpression(pattern: "[A-Z]", options:[])
        let range = NSMakeRange(0, self.count)
        var words: [Substring] = []
        var prev_index = self.startIndex
        for m in regex.matches(in: self, options: [], range: range) {
            let index = self.index(self.startIndex, offsetBy: m.range.location)
            guard prev_index != index else {
                continue
            }
            let word = self[prev_index ..< index]
            words.append(word)
            prev_index = index
        }
        if prev_index < self.endIndex {
            words.append(self[prev_index ..< self.endIndex])
        }
        return words.joined(separator: " ")
    }
    
    init?(cString: UnsafePointer<CChar>?) {
        guard let cString = cString else {
            return nil
        }
        self.init(cString: cString)
    }
    
    /// Convert `CamelCase` to `Camel Case`, `FSItem` to `FS Item`.
    func camelCaseToWords() -> String {
        let s = self
                    .replacingOccurrences(of: "([A-Z])",
                                          with: " $1",
                                          options: .regularExpression,
                                          range: range(of: self))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .capitalized // If input is in llamaCase
        /*
        let s = unicodeScalars.reduce("") {
            if CharacterSet.uppercaseLetters.contains($1) {
                if $0.count > 0 {
                    return ($0 + " " + String($1))
                }
            }
            return $0 + String($1)
        }*/
        var s2 = ""
        var isCapitalLetter = true
        for w in s.split(separator: " ") {
            if w == w.uppercased() {
                if !isCapitalLetter {
                    s2 += " "
                }
                isCapitalLetter = true
                s2 += w
            } else {
                if let last = s2.last, last != " " && last != "_" && last != "-" {
                    s2 += " "
                }
                s2 += w
                isCapitalLetter = false
            }
        }
        return s2
    }
}

// https://stackoverflow.com/questions/32305891/index-of-a-substring-in-a-string-with-swift
extension StringProtocol {
    func index<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.lowerBound
    }
    func endIndex<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.upperBound
    }
    func indices<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Index] {
        ranges(of: string, options: options).map(\.lowerBound)
    }
    func ranges<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Range<Index>] {
        var result: [Range<Index>] = []
        var startIndex = self.startIndex
        while startIndex < endIndex,
            let range = self[startIndex...]
                .range(of: string, options: options) {
                result.append(range)
                startIndex = range.lowerBound < range.upperBound ? range.upperBound :
                    index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return result
    }
}

// https://stackoverflow.com/questions/29365145/how-can-i-encode-a-string-to-base64-in-swift
extension String {

    func fromBase64() -> String? {
        guard let data = Data(base64Encoded: self) else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    func toBase64() -> String {
        return Data(self.utf8).base64EncodedString()
    }

}
