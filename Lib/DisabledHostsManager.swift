//
//  DisabledHostsManager.swift
//  Pubpeer Safari App Extension
//
//  Created by Rogier Muijen on 10/17/19.
//  Copyright © 2019 Pubpeer Foundation. All rights reserved.
//

import Foundation
import Cocoa

class DisabledHostsManager: NSObject {
    private var tempDisabledHosts: [String]? = []
    static let shared: DisabledHostsManager = DisabledHostsManager()

    
    func isValid(url: String) -> Bool {
        let host = removeUrlComponentsAfterHost(url: url)
        let urlRegEx = "((?:http|https)://)?(((?:www)?|(?:[a-zA-z0-9]{1,})?)\\.)?[\\w\\d\\-_]+\\.(\\w{2,}?|(xn--\\w{2,})?)(\\.\\w{2})?(/(?<=/)(?:[\\w\\d\\-./_]+)?)?"
        let urlTest = NSPredicate(format:"SELF MATCHES %@", urlRegEx)
        let result = urlTest.evaluate(with: host)
        return result
    }
    
    func removeUrlComponentsAfterHost(url: String) -> String {
        var host = ""
        var firstSlashRange: Range<String.Index>?
        if let protocolRange = url.range(of: "://") {
            let searchRange = Range<String.Index>(uncheckedBounds: (lower: protocolRange.upperBound, upper: url.endIndex))
            firstSlashRange = url.range(of: "/", options: .literal, range: searchRange, locale: Locale.current)
        } else {
            firstSlashRange = url.range(of: "/", options: .literal, range: nil, locale: Locale.current)
        }
        host = String(url[..<(firstSlashRange?.lowerBound ?? url.endIndex)])
        return host
    }
    
    func _unique(_ array: [String]?) -> [String]? {
        return Array(Set(array ?? []))
    }
    
    func add(_ url: String, once: Bool) {
        let normalizedUrl = normalizeUrl(url)
        let disabledHost:String = normalizedUrl
        
        var disabledHosts: [String]? = getAllItems() ?? []
        var tempDisabledHosts: [String]? = DisabledHostsManager.shared.tempDisabledHosts ?? [];
        if (once) {
            tempDisabledHosts?.append(disabledHost)
            disabledHosts = DisabledHostsManager.shared._remove(disabledHost, list: disabledHosts)
        } else {
            disabledHosts?.append(disabledHost)
            tempDisabledHosts = DisabledHostsManager.shared._remove(disabledHost, list: tempDisabledHosts)
        }
        tempDisabledHosts = self._unique(tempDisabledHosts)
        DisabledHostsManager.shared.tempDisabledHosts = tempDisabledHosts
        disabledHosts = self._unique(disabledHosts)
        saveAsync(disabledHosts) {}
    }
    
    func _remove(_ value: String, list: [String]?) -> [String]? {
        let newDisabledHosts = list?.filter({ (disabledHost) -> Bool in
             return disabledHost.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() != value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        })
        return newDisabledHosts
    }
    
    func remove(_ url: String) {
        let normalizedUrl = normalizeUrl(url)
        DisabledHostsManager.shared.tempDisabledHosts = DisabledHostsManager.shared._remove(normalizedUrl, list: DisabledHostsManager.shared.tempDisabledHosts)
        let disabledHosts: [String]? = getAllItems() ?? []
        let newDisabledHosts = DisabledHostsManager.shared._remove(normalizedUrl, list: disabledHosts)
        saveAsync(newDisabledHosts) {}
    }
    
    func getAllItems() -> [String]? {
        guard let disabledHosts = getAll() else { return [] }
        var disabledHostItems: [String]? = []
        for disabledHost in disabledHosts {
            let name = disabledHost
            disabledHostItems?.append(name)
        }
        
        return disabledHostItems
    }
    
    func isDisabledHost(_ url: String) -> Bool {
        let normalizedUrl = normalizeUrl(url)
        let disabledHosts: [String]? = getAllItems() ?? []
        let allDisabledHosts: [String]? = disabledHosts ?? [] + (DisabledHostsManager.shared.tempDisabledHosts ?? [])
        return allDisabledHosts?.contains(normalizedUrl) ?? false
    }
    
    private func getAll() -> [String]? {
        let disabledHostsString: String? = UserDefaults.standard.string(forKey: Constants.UserDefaultsKey)
        let disabledHosts: [String]? = disabledHostsString?.components(separatedBy: Constants.KeySeparator)
        return disabledHosts
    }
    
    private func save(_ rules: [String]?) {
        let disabledHostsString: String? = rules?.joined(separator: Constants.KeySeparator)
        UserDefaults.standard.set(disabledHostsString, forKey: Constants.UserDefaultsKey)
    }
    
    private func saveAsync(_ rules: [String]?, completion: @escaping () -> Void) {
        DispatchQueue.global(qos: .background).async {
            self.save(rules)
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    func normalizeUrl(_ url: String) -> String {
        let host = removeUrlComponentsAfterHost(url: url)
        var normalizedUrl = removeProtocol(from: host)
        if normalizedUrl.starts(with: "www.") {
            normalizedUrl = normalizedUrl.replacingOccurrences(of: "www.", with: "")
        }
        return normalizedUrl
    }
    
    private func removeProtocol(from url: String) -> String {
        let dividerRange = url.range(of: "://")
        guard let divide = dividerRange?.upperBound else { return url }
        let path = String(url[divide...])
        return path
    }
}
