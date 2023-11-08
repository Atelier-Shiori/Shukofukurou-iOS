// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import AppCenter
import AppCenterCrashes
import Cocoa
import NotificationCenter

class TodayViewController: NSViewController, NCWidgetProviding, CrashesDelegate {
  
    @IBOutlet weak var addAttachments: NSButton!
    @IBOutlet weak var popupButton: NSPopUpButton!
    @IBOutlet weak var extensionLabel: NSTextField!
    var crashes = [MSCrash]()
    
    override var nibName: NSNib.Name? {
        return NSNib.Name("TodayViewController")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let dateString = DateFormatter.localizedString(from: Date.init(), dateStyle: DateFormatter.Style.medium, timeStyle: DateFormatter.Style.medium)
        extensionLabel.stringValue = "Run #\(dateString)"
        AppCenter.logLevel = .verbose
        Crashes.delegate = self
        let appSecret = ProcessInfo.processInfo.environment["MAC_SWIFT_EXTENTION"];
        AppCenter.start(withAppSecret:appSecret, services: [Crashes.self])
        crashes = CrashLoader.loadAllCrashes(withCategories: false) as! [MSCrash]
        popupButton.menu?.removeAllItems()
        for (index, crash) in crashes.enumerated() {
            popupButton.menu?.addItem(NSMenuItem(title: crash.title, action: nil, keyEquivalent: "\(index)"))
        }
    }
    
    @IBAction func crashMe(_ sender: Any) {
        let selectedCrashIndex = popupButton.indexOfSelectedItem
        crashes[selectedCrashIndex].crash()
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        completionHandler(.noData)
    }
    
    func attachments(with crashes: Crashes, for errorReport: ErrorReport) -> [ErrorAttachmentLog] {
        if (addAttachments.state == .on) {
            let attachment1 = ErrorAttachmentLog.attachment(withText: "Hello world!", filename: "hello.txt")
            let attachment2 = ErrorAttachmentLog.attachment(withBinary: "Fake image".data(using: String.Encoding.utf8), filename: nil, contentType: "image/jpeg")
            return [attachment1!, attachment2!]
        }
        return [];
    }
}
