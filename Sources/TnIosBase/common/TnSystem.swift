//
//  TnLocalizable.swift
//  test-swiftui
//
//  Created by Thinh Nguyen on 15/08/2021.
//

import Foundation
import SwiftUI

extension String {
    func lz(_ lz: Bool = true) -> String {
        TnSystem.instance.localize(self, lz)
    }
}

class TnSystem: NSObject, ObservableObject {
    /// Singleton
    static let instance = TnSystem()
    override init() {
        // init the language index and set the code here
        activeLanguageIndex = 0
        activeColorSchemeType = .auto
        super.init()
    }
    
    let languageIndexes: [Int32] = [0, 1, 2]
    
    let languageCodes: [String] =
    if #available(iOS 16.0, *) {
        [Locale.current.language.languageCode!.identifier, "en", "vi"]
    } else {
        [Locale.current.languageCode!, "en", "vi"]
    }
    
    let languageNames: [String] = ["Auto", "English", "Vietnamese"]
    @Published private(set) var activeLanguageCode: String =
    if #available(iOS 16.0, *) {
        Locale.current.language.languageCode!.identifier
    } else {
        Locale.current.languageCode!
    }
    @Published var activeLanguageIndex: Int = 0 {
        didSet {
            activeLanguageCode = languageCodes[activeLanguageIndex]
            TnLogger.debug("System", "setActiveLanguage", activeLanguageIndex, activeLanguageCode)
        }
    }

    /// Bundles
    private var languageBundles: Dictionary<String, Bundle> = [:]
    private func getLanguageBundle(_ lang: String) -> Bundle {
        var ret: Bundle!
        if let b = languageBundles[lang] {
            ret = b
        } else {
            let path = Bundle.main.path(forResource: lang, ofType: "lproj")
            let bundle = Bundle(path: path!)
            languageBundles[lang] = bundle
            ret = bundle
        }
        return ret
    }
    
    /// main localization
    func localize(_ s: String, _ lz: Bool = true) -> String {
        if !lz {
            return s
        }
        let bundle = getLanguageBundle(activeLanguageCode)
        return NSLocalizedString(s, tableName: nil, bundle: bundle, value: "", comment: "")
    }
    
    let colorSchemeTypes: [TnColorSchemeType] = [.auto, .light, .dark]
    let colorSchemeNames: [String] = ["Auto", "Light", "Dark"]
    @Published private(set) var activeColorScheme: ColorScheme = .light
    @Published var activeColorSchemeType: TnColorSchemeType = TnColorSchemeType.auto {
        didSet {
            switch activeColorSchemeType {
            case .auto:
                activeColorScheme = UITraitCollection.current.userInterfaceStyle == .dark ? .dark : .light
            case .dark:
                activeColorScheme = .dark
            case .light:
                activeColorScheme = .light
            }

            TnLogger.debug("System", "setActiveColorScheme", activeColorSchemeType, activeColorScheme)
        }
    }
}

// color scheme
enum TnColorSchemeType: Int, Codable, Comparable {
    static func < (lhs: TnColorSchemeType, rhs: TnColorSchemeType) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    case auto
    case light
    case dark
}

extension TnColorSchemeType {
    static let allCases: [TnColorSchemeType] = [
      .auto,
      .light,
      .dark,
    ]
    static let names: [String] = ["Auto", "Light", "Dark"]
}
