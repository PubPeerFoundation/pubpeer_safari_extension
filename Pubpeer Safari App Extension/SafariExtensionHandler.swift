//
//  SafariExtensionHandler.swift
//  Pubpeer Safari App Extension
//
//  Created by Rogier Muijen on 10/17/19.
//  Copyright © 2019 Pubpeer Foundation. All rights reserved.
//

import SafariServices

class SafariExtensionHandler: SFSafariExtensionHandler {
    
    private var _page:SFSafariPage?
    
    static let shared: SafariExtensionHandler = {
        let shared = SafariExtensionHandler()
        return shared
    }()
    
    override func messageReceived(withName messageName: String, from page: SFSafariPage, userInfo: [String : Any]?) {
        // This method will be called when a content script provided by your extension calls safari.extension.dispatchMessage("message").
        page.getPropertiesWithCompletionHandler { properties in
            NSLog("The extension received a message (\(messageName)) from a script injected into (\(String(describing: properties?.url))) with userInfo (\(userInfo ?? [:]))")
            if (messageName == "pageLoaded") {
                SafariExtensionHandler.shared._page = page
                if (DisabledHostsManager.shared.isDisabledHost(String(describing: properties?.url)) == false) {
                    self.sendMessage(withName: "addPubPeerMarks", userInfo: [:])
                }
            }
        }
    }
    
    override func toolbarItemClicked(in window: SFSafariWindow) {
        // This method will be called when your toolbar item is clicked.
        NSLog("The extension's toolbar item was clicked")
    }
    
    override func validateToolbarItem(in window: SFSafariWindow, validationHandler: @escaping ((Bool, String) -> Void)) {
        // This is called when Safari's state changed in some way that would require the extension's toolbar item to be validated again.
        validationHandler(true, "")

        window.getActiveTab { (activeTab) in
            activeTab?.getActivePage(completionHandler: { (activePage) in
                activePage?.getPropertiesWithCompletionHandler( { (properties) in
                    SafariExtensionViewController.shared.setActivatedURL(with: properties?.url?.absoluteString)
                })
            })
        }
    }
    
    override func popoverViewController() -> SFSafariExtensionViewController {
        return SafariExtensionViewController.shared
    }
    
    override func popoverWillShow(in window: SFSafariWindow) {
        SafariExtensionViewController.shared.initUIElements()
    }
    
    func sendMessage(withName: String, userInfo: [String : Any]?) {
        SafariExtensionHandler.shared._page?.dispatchMessageToScript(withName: withName, userInfo: userInfo)
    }

}
