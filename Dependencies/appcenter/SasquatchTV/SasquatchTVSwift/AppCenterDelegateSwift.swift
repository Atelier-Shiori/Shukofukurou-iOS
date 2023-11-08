// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import AppCenter;
import AppCenterAnalytics;
import AppCenterCrashes;

/**
 * AppCenterDelegate implementation in Swift.
 */
class AppCenterDelegateSwift : AppCenterDelegate {

  // MARK: AppCenter section.
  func isAppCenterEnabled()->Bool { return AppCenter.enabled; }
  func setAppCenterEnabled(_ isEnabled : Bool) { AppCenter.enabled = isEnabled; }
  func installId()->String { return AppCenter.installId.uuidString; }
  #warning("TODO: Uncomment when appSecret is moved from internal to public.")
  func appSecret()->String {
    // return AppCenter.sharedInstance().appSecret()
    return "Internal";
  }
  #warning("TODO: Uncomment when appSecret is moved from internal to public.")
  func logUrl()->String {
    // return AppCenter.sharedInstance().logUrl()
    return "Internal";
  }
  func isDebuggerAttached()->Bool { return AppCenter.isDebuggerAttached; }
  func isNetworkRequestsAllowed()->Bool { return AppCenter.networkRequestsAllowed; }
  func setNetworkRequestsAllowed(_ isAllowed: Bool) { AppCenter.networkRequestsAllowed = isAllowed; }

  // MARK: Analytics section.
  func isAnalyticsEnabled()->Bool { return Analytics.enabled; }

  func setAnalyticsEnabled(_ isEnabled : Bool) { Analytics.enabled = isEnabled; }

  func trackEvent(_ eventName : String) { Analytics.trackEvent(eventName); }

  func trackEvent(_ eventName : String, withProperties properties : Dictionary<String, String>) {
    Analytics.trackEvent(eventName, withProperties : properties);
  }
  
  func startSession() {
    Analytics.startSession()
  }

  func enableManualSessionTracker() {
    Analytics.enableManualSessionTracker()
  }

  #warning("TODO: Uncomment when trackPage is moved from internal to public.")
  func trackPage(_ pageName : String) {
    // Analytics.trackPage(pageName);
  }

  #warning("TODO: Uncomment when trackPage is moved from internal to public.")
  func trackPage(_ pageName : String, withProperties properties : Dictionary<String, String>) {
    // Analytics.trackPage(pageName, withProperties: properties);
  }

  // MARK: Crashes section.

  func isCrashesEnabled() -> Bool{
    return Crashes.enabled
  }

  func setCrashesEnabled(_ isEnabled: Bool){
    Crashes.enabled = isEnabled
  }

  func hasCrashedInLastSession() -> Bool{
    return Crashes.hasCrashedInLastSession
  }

  func generateTestCrash() {
    Crashes.generateTestCrash()
  }
    
  func trackError(_ error: Error, withProperties: Dictionary<String, String>?, attachments: [ErrorAttachmentLog]?) {
    Crashes.trackError(error, properties: withProperties, attachments: attachments)
  }
      
  func trackException(_ exceptionModel: ExceptionModel, withProperties: Dictionary<String, String>?, attachments: [ErrorAttachmentLog]?) -> Void {
    Crashes.trackException(exceptionModel, properties: withProperties, attachments: attachments)
  }

  //MARK: Last crash report section.
  func lastCrashReportIncidentIdentifier() -> String?{
    return Crashes.lastSessionCrashReport?.incidentIdentifier
  }
  func lastCrashReportReporterKey() -> String?{
    return Crashes.lastSessionCrashReport?.reporterKey
  }
  func lastCrashReportSignal() -> String?{
    return Crashes.lastSessionCrashReport?.signal
  }
  func lastCrashReportExceptionName() -> String?{
    return Crashes.lastSessionCrashReport?.exceptionName
  }
  func lastCrashReportExceptionReason() -> String?{
    return Crashes.lastSessionCrashReport?.exceptionReason
  }
  func lastCrashReportAppStartTimeDescription() -> String?{
    return Crashes.lastSessionCrashReport?.appStartTime.description
  }
  func lastCrashReportAppErrorTimeDescription() -> String?{
    return Crashes.lastSessionCrashReport?.appErrorTime.description
  }
  func lastCrashReportAppProcessIdentifier() -> UInt{
    return (Crashes.lastSessionCrashReport?.appProcessIdentifier)!
  }
  func lastCrashReportIsAppKill() -> Bool{
    return (Crashes.lastSessionCrashReport?.isAppKill)!
  }
  func lastCrashReportDeviceModel() -> String?{
    return Crashes.lastSessionCrashReport?.device.model
  }
  func lastCrashReportDeviceOemName() -> String?{
    return Crashes.lastSessionCrashReport?.device.oemName
  }
  func lastCrashReportDeviceOsName() -> String?{
    return Crashes.lastSessionCrashReport?.device.osName
  }
  func lastCrashReportDeviceOsVersion() -> String?{
    return Crashes.lastSessionCrashReport?.device.osVersion
  }
  func lastCrashReportDeviceOsBuild() -> String?{
    return Crashes.lastSessionCrashReport?.device.osBuild
  }
  func lastCrashReportDeviceLocale() -> String?{
    return Crashes.lastSessionCrashReport?.device.locale
  }
  func lastCrashReportDeviceTimeZoneOffset() -> NSNumber?{
    return Crashes.lastSessionCrashReport?.device.timeZoneOffset
  }
  func lastCrashReportDeviceScreenSize() -> String?{
    return Crashes.lastSessionCrashReport?.device.screenSize
  }
  func lastCrashReportDeviceAppVersion() -> String?{
    return Crashes.lastSessionCrashReport?.device.appVersion
  }
  func lastCrashReportDeviceAppBuild() -> String?{
    return Crashes.lastSessionCrashReport?.device.appBuild
  }
  func lastCrashReportDeviceCarrierName() -> String?{
    return Crashes.lastSessionCrashReport?.device.carrierName
  }
  func lastCrashReportDeviceCarrierCountry() -> String?{
    return Crashes.lastSessionCrashReport?.device.carrierCountry
  }
  func lastCrashReportDeviceAppNamespace() -> String?{
    return Crashes.lastSessionCrashReport?.device.appNamespace
  }

  //MARK: MSEventFilter section.
  func isEventFilterEnabled() -> Bool{
    return MSEventFilter.enabled;
  }
  func setEventFilterEnabled(_ isEnabled: Bool){
    MSEventFilter.enabled = isEnabled;
  }
  func startEventFilterService() {
    AppCenter.startService(MSEventFilter.self)
  }
}
