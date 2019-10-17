//
//  SafariExtensionViewController.swift
//  Pubpeer Safari App Extension
//
//  Created by Rogier Muijen on 10/17/19.
//  Copyright © 2019 Pubpeer Foundation. All rights reserved.
//

import SafariServices

class SafariExtensionViewController: SFSafariExtensionViewController {
    @IBOutlet weak var btnCloseWindow: NSButton!
    @IBOutlet weak var btnDisableOnce: NSButton!
    @IBOutlet weak var btnDisableForever: NSButton!
    @IBOutlet weak var btnEnable: NSButton!
    @IBOutlet weak var txtLogo: NSTextField!
    @IBOutlet weak var txtDescription_1: NSTextField!
    @IBOutlet weak var txtDescription_2: NSTextField!
    
    private var url: String?
    
    static let shared: SafariExtensionViewController = {
        let shared = SafariExtensionViewController()
        shared.preferredContentSize = NSSize(width:385, height:285)
        return shared
    }()
    
    func initUIElements(_ _url:String) {
        self.btnDisableOnce.layer?.backgroundColor = NSColor.init(calibratedRed: 106/255, green: 194/255, blue: 188/255, alpha: 1).cgColor
        self.btnDisableForever.layer?.backgroundColor = NSColor.init(calibratedRed: 106/255, green: 194/255, blue: 188/255, alpha: 1).cgColor
        self.txtDescription_2.stringValue = "on \(DisabledHostsManager.shared.normalizeUrl(self.url ?? _url ))?"
    }
    
    func onPopoverVisible(with url: String?) {
        self.url = url
    }
    
    func closePopover() {
        SafariExtensionViewController.shared.dismissPopover()
    }
    
    @IBAction func closeWindow(_ sender: NSButton) {
        self.closePopover()
    }
    
    @IBAction func disableOnce(_ sender: NSButton) {
        DisabledHostsManager.shared.add(self.url ?? "", once: true)
        SafariExtensionHandler.shared.sendMessage(withName: "removePubPeerMarks", userInfo: [:])
        self.closePopover()
    }
    
    @IBAction func disableForever(_ sender: NSButton) {
        DisabledHostsManager.shared.add(self.url ?? "", once: false)
        SafariExtensionHandler.shared.sendMessage(withName: "removePubPeerMarks", userInfo: [:])
        self.closePopover()
    }
    
    @IBAction func enableHost(_ sender: NSButton) {
        DisabledHostsManager.shared.remove(self.url ?? "")
        SafariExtensionHandler.shared.sendMessage(withName: "addPubPeerMarks", userInfo: [:])
        self.closePopover()
    }
}
