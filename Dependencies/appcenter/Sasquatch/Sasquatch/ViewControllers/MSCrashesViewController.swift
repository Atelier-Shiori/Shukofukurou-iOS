// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import Photos
import UIKit

enum AppCenterError: Error {
  case runtimeError(String)
}

class MSCrashesViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIDocumentPickerDelegate, AppCenterProtocol {
  
  var hasTrackErrorProperies = false
  var categories = [String: [MSCrash]]()
  var appCenter: AppCenterDelegate!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    pokeAllCrashes()
    
    var crashes = MSCrash.allCrashes() as! [MSCrash]
    crashes = crashes.sorted { (crash1, crash2) -> Bool in
      if crash1.category == crash2.category {
        return crash1.title > crash2.title
      } else {
        return crash1.category > crash2.category
      }
    }
    
    for crash in crashes {
      if categories[crash.category] == nil {
        categories[crash.category] = [MSCrash]()
      }
      categories[crash.category]!.append(crash)
    }
    
    // Make sure the UITabBarController does not cut off the last cell.
    self.edgesForExtendedLayout = []
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.tableView.reloadData()
  }
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return categories.count + 2
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    switch section {
      case 0: return 1
      case 1: return 5
      case 2: return 3
      default: return categories[categoryForSection(section - 3)]!.count
    }
  }
  
  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    let isFirst = section == 0
    let isSecond = section == 1
    let isThird = section == 2
    if isFirst {
      return "Breadcrumbs"
    } else if isSecond {
      return "Crashes Settings"
    } else if isThird {
      return "Track Error Settings"
    } else {
      return categoryForSection(section - 2)
    }
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let isFirst = indexPath.section == 0
    let isSecond = indexPath.section == 1
    let isThird = indexPath.section == 2
    var cellIdentifier = "crash"
    if isFirst {
      cellIdentifier = "breadcrumbs"
    } else if isSecond {
      if indexPath.row == 0 {
        cellIdentifier = "enable"
      } else {
        cellIdentifier = "attachment"
      }
    } else if isThird && indexPath.row == 0 {
        cellIdentifier = "trackerror"
    }
    let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)!
    if isFirst {
      cell.textLabel?.text = "Breadcrumbs"
    } else if isSecond {
      
      // Enable.
      if (indexPath.row == 0) {
        
        // Find switch in subviews.
        for view in cell.contentView.subviews {
          if let switchView = view as? UISwitch {
            switchView.isOn = appCenter.isCrashesEnabled()
          }
        }
        
        // Text attachment.
      } else if (indexPath.row == 1) {
        cell.textLabel?.text = "Text Attachment"
        let text = UserDefaults.standard.string(forKey: "textAttachment") ?? ""
        cell.detailTextLabel?.text = !text.isEmpty ? text : "Empty"
        
        // Binary attachment.
      } else if (indexPath.row == 2) {
        cell.textLabel?.text = "Binary Attachment"
        let referenceUrl = UserDefaults.standard.url(forKey: "fileAttachment")
        cell.detailTextLabel?.text = referenceUrl != nil ? referenceUrl!.absoluteString : "Empty"
        
        // Read async to display size instead of url.
        if referenceUrl != nil {
#if !targetEnvironment(macCatalyst)
        let asset = PHAsset.fetchAssets(withALAssetURLs: [referenceUrl!], options: nil).lastObject
        if asset != nil {
          PHImageManager.default().requestImageData(for: asset!, options: nil, resultHandler: {(imageData, dataUTI, orientation, info) -> Void in
          cell.detailTextLabel?.text = ByteCountFormatter.string(fromByteCount: Int64(imageData?.count ?? 0), countStyle: .binary)
          })
        }
#else
        cell.detailTextLabel?.text = self.fileAttachmentDescription(url: referenceUrl)
#endif
        }
      } else if (indexPath.row == 3) {
        cell.textLabel?.text = "Clear crash user confirmation"
        cell.detailTextLabel?.text = ""
      } else if (indexPath.row == 4) {
        cell.textLabel?.text = "Memory warning status (last session)"
        cell.detailTextLabel?.text = appCenter.hasReceivedMemoryWarningInLastSession() ? "YES" : "NO"
      }
    } else if isThird {
       if (indexPath.row == 0) {
        for view in cell.contentView.subviews {
          if let switchView = view as? UISwitch {
            switchView.isOn = false
          }
        }
       }
       else if (indexPath.row == 1) {
         cell.textLabel?.text = "Track error"
         cell.detailTextLabel?.text = ""
       } else if (indexPath.row == 2) {
         cell.textLabel?.text = "Track error with custom exception"
         cell.detailTextLabel?.text = ""
       }
    } else {
      let crash = crashByIndexPath(indexPath)
      cell.textLabel?.text = crash.title;
    }
    return cell;
  }
  
  private func fileAttachmentDescription(url: URL?) -> String {
    if url != nil {
      var desc = "File: \(url!.lastPathComponent)"
      do {
        let attr = try FileManager.default.attributesOfItem(atPath: url!.path)
        let fileSize = ByteCountFormatter.string(fromByteCount: Int64(attr[FileAttributeKey.size] as! UInt64), countStyle: .binary)
        desc += " Size: \(fileSize)"
      } catch {
        print(error)
      }
      return desc
    } else {
      return "Empty"
    }
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) -> Void {
    let isFirst = indexPath.section == 0
    let isSecond = indexPath.section == 1
    let isThird = indexPath.section == 2
    if isFirst {
      for index in 0...29 {
        let eventName = "Breadcrumb_\(index)"
        appCenter.trackEvent(eventName)
      }
      appCenter.generateTestCrash()
    } else if isSecond {
      
      // Text attachment.
      if indexPath.row == 1 {
        let alert = UIAlertController(title: "Text Attachment", message: nil, preferredStyle: .alert)
        let crashAction = UIAlertAction(title: "OK", style: .default, handler: {(_ action: UIAlertAction) -> Void in
          let result = alert.textFields?[0].text ?? ""
          if !result.isEmpty {
            UserDefaults.standard.set(result, forKey: "textAttachment")
          } else {
            UserDefaults.standard.removeObject(forKey: "textAttachment")
          }
          tableView.reloadData()
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(crashAction)
        alert.addAction(cancelAction)
        alert.addTextField(configurationHandler: {(_ textField: UITextField) -> Void in
          textField.text = UserDefaults.standard.string(forKey: "textAttachment")
        })
        present(alert, animated: true)
        
        // Binary attachment.
      } else if indexPath.row == 2 {
#if !targetEnvironment(macCatalyst)
        PHPhotoLibrary.requestAuthorization({ (status: PHAuthorizationStatus) -> Void in ()
          if PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.authorized {
            DispatchQueue.main.async {
                let picker = UIImagePickerController()
                picker.delegate = self
                self.present(picker, animated: true)
              }
          }
        })
#else
        let documentPicker = UIDocumentPickerViewController(documentTypes: ["public.image"], in: .import)
        documentPicker.delegate = self
        self.present(documentPicker, animated: true, completion: nil)
#endif
      } else if indexPath.row == 3 {
        let alertController = UIAlertController(title: "Clear crash user confirmation?",
                                                message: nil,
                                                preferredStyle:.alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let clearAction = UIAlertAction(title: "OK", style: .default, handler: {
            (_ action : UIAlertAction) -> Void in
            UserDefaults.standard.removeObject(forKey: kMSUserConfirmationKey)
        })
        alertController.addAction(cancelAction)
        alertController.addAction(clearAction)
        self.present(alertController, animated: true, completion: nil)
      }
    } else if isThird {
      let properties:Dictionary<String, String>? = hasTrackErrorProperies ? ["key" :  "value"] : nil
      let attachments: [ErrorAttachmentLog]? = PrepareErrorAttachments.prepareAttachments()
      if indexPath.row == 1 {
        appCenter.trackError(AppCenterError.runtimeError("Track error"), withProperties: properties, attachments: attachments)
      } else if indexPath.row == 2 {
        let exceptionModel = ExceptionModel(withType: "Custom exception model", exceptionMessage: "Track error with custom exception model.", stackTrace: Thread.callStackSymbols)
        appCenter.trackException(exceptionModel!, withProperties: properties, attachments: attachments)
      }
    } else {
      
      // Crash cell.
      let crash = crashByIndexPath(indexPath)
      let alert = UIAlertController(title: crash.title, message: crash.desc, preferredStyle: .actionSheet)
      let crashAction = UIAlertAction(title: "Crash", style: .destructive, handler: {(_ action: UIAlertAction) -> Void in
        crash.crash()
      })
      let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {(_ action: UIAlertAction) -> Void in
        alert.dismiss(animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
      })
      alert.addAction(crashAction)
      alert.addAction(cancelAction)
      
      // Support display in iPad.
      alert.popoverPresentationController?.sourceView = tableView
      alert.popoverPresentationController?.sourceRect = tableView.rectForRow(at: indexPath)
      
      present(alert, animated: true)
    }
  }
  
  func documentPicker(_ controller: UIDocumentPickerViewController,
                      didPickDocumentsAt urls: [URL]) {
    if (urls.count > 0) {
      let firstUrl = urls[0]
      UserDefaults.standard.set(firstUrl, forKey: "fileAttachment")
      tableView.reloadData()
    }
    controller.dismiss(animated: true, completion: nil)
  }
  
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    let referenceUrl = info[UIImagePickerController.InfoKey.referenceURL] as? URL
    
    if referenceUrl != nil {
      UserDefaults.standard.set(referenceUrl, forKey: "fileAttachment")
      tableView.reloadData()
    }
    picker.dismiss(animated: true, completion: nil)
  }
  
  @objc func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    UserDefaults.standard.removeObject(forKey: "fileAttachment")
    tableView.reloadData()
    picker.dismiss(animated: true, completion: nil)
  }
  
  @IBAction func enabledSwitchUpdated(_ sender: UISwitch) {
    appCenter.setCrashesEnabled(sender.isOn)
    sender.isOn = appCenter.isCrashesEnabled()
  }
  
  @IBAction func trackWithPropertiesUpdated(_ sender: UISwitch) {
    hasTrackErrorProperies = sender.isOn
  }
    
  private func pokeAllCrashes() {
    var count = UInt32(0)
    let classList = objc_copyClassList(&count)
    let classes = UnsafeBufferPointer(start: classList, count: Int(count))
    MSCrash.removeAllCrashes()
    for i in 0..<Int(count){
      let className: AnyClass = classes[i]
      if class_getSuperclass(className) == MSCrash.self && className != MSCrash.self {
        MSCrash.register((className as! MSCrash.Type).init())
      }
    }
  }
  
  private func categoryForSection(_ section: Int) -> String {
    return categories.keys.sorted()[section]
  }
  
  private func crashByIndexPath(_ indexPath: IndexPath) -> MSCrash {
    return categories[categoryForSection(indexPath.section - 3)]![indexPath.row]
  }
}
