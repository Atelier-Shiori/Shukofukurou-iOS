// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wreserved-id-macro"
#ifndef __IPHONE_11_0
#define __IPHONE_11_0 110000
#endif
#pragma clang diagnostic pop

#import "MSACAlertController.h"
#import "MSACCustomApplicationDelegate.h"
#import "MSACDistribute.h"
#import "MSACDistributeInfoTracker.h"
#import <AuthenticationServices/AuthenticationServices.h>
#import <SafariServices/SafariServices.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MSACAuthenticationSession <NSObject>

- (BOOL)start;
- (void)cancel;

@end

@interface ASWebAuthenticationSession () <MSACAuthenticationSession>
@end

#if !TARGET_OS_MACCATALYST

@interface SFAuthenticationSession () <MSACAuthenticationSession>
@end

#endif

@class MSACReleaseDetails;

/**
 * A day in milliseconds.
 */
static long long const kMSACDayInMillisecond = 24 /* Hours */ * 60 /* Minutes */ * 60 /* Seconds */ * 1000 /* Milliseconds */;

/**
 * Base URL for HTTP Distribute install API calls.
 */
static NSString *const kMSACDefaultInstallUrl = @"https://install.appcenter.ms";

/**
 * Base URL for HTTP Distribute update API calls.
 */
static NSString *const kMSACDefaultApiUrl = @"https://api.appcenter.ms/v0.1";

/**
 * Distribute url query parameter key strings.
 */
static NSString *const kMSACURLQueryPlatformKey = @"platform";
static NSString *const kMSACURLQueryReleaseHashKey = @"release_hash";
static NSString *const kMSACURLQueryRedirectIdKey = @"redirect_id";
static NSString *const kMSACURLQueryRequestIdKey = @"request_id";
static NSString *const kMSACURLQueryUpdateTokenKey = @"update_token";
static NSString *const kMSACURLQueryDistributionGroupIdKey = @"distribution_group_id";
static NSString *const kMSACURLQueryEnableUpdateSetupFailureRedirectKey = @"enable_failure_redirect";
static NSString *const kMSACURLQueryUpdateSetupFailedKey = @"update_setup_failed";
static NSString *const kMSACURLQueryDownloadedReleaseIdKey = @"downloaded_release_id";
static NSString *const kMSACURLQueryInstallIdKey = @"install_id";
static NSString *const kMSACURLQueryTesterAppUpdateSetupFailedKey = @"tester_app_update_setup_failed";

/**
 * Distribute url query parameter value strings.
 */
static NSString *const kMSACURLQueryPlatformValue = @"iOS";

/**
 * Distribute custom URL scheme format.
 */
static NSString *const kMSACDefaultCustomSchemeFormat = @"appcenter-%@";

/**
 * The storage key for postponed timestamp.
 */
static NSString *const kMSACPostponedTimestampKey = @"PostponedTimestamp";

/**
 * The storage key for request ID.
 */
static NSString *const kMSACUpdateTokenRequestIdKey = @"UpdateTokenRequestId";

/**
 * The storage key for flag that can determine to clean up update token.
 */
static NSString *const kMSACSDKHasLaunchedWithDistribute = @"SDKHasLaunchedWithDistribute";

/**
 * The storage key for last mandatory release details.
 */
static NSString *const kMSACMandatoryReleaseKey = @"MandatoryRelease";

/**
 * The storage key for distribution group ID.
 */
static NSString *const kMSACDistributionGroupIdKey = @"DistributionGroupId";

/**
 * The storage key for update setup failure package hash.
 */
static NSString *const kMSACUpdateSetupFailedPackageHashKey = @"UpdateSetupFailedPackageHash";

/**
 * The storage key for latest downloaded release hash.
 */
static NSString *const kMSACDownloadedReleaseHashKey = @"DownloadedReleaseHash";

/**
 * The storage key for latest downloaded release ID.
 */
static NSString *const kMSACDownloadedReleaseIdKey = @"DownloadedReleaseId";

/**
 * The storage key for distribution group ID of latest downloaded release.
 */
static NSString *const kMSACDownloadedDistributionGroupIdKey = @"DownloadedDistributionGroupId";

/**
 * The storage key for tester app update setup failure.
 */
static NSString *const kMSACTesterAppUpdateSetupFailedKey = @"TesterAppUpdateSetupFailed";

@interface MSACDistribute ()

/**
 * Current view controller presenting the `SFSafariViewController` if any.
 */
@property(nullable, nonatomic) UIViewController *safariHostingViewController;

/**
 * Current update alert view controller if any.
 */
@property(nonatomic) MSACAlertController *updateAlertController;

/**
 * Current release details.
 */
@property(nullable, nonatomic) MSACReleaseDetails *releaseDetails;

/**
 * A Distribute delegate that will be called whenever a new release is available for update.
 */
@property(nonatomic, weak) id<MSACDistributeDelegate> delegate;

/**
 * Custom application delegate dedicated to Distribute.
 */
@property(nonatomic) id<MSACCustomApplicationDelegate> appDelegate;

/**
 * Authentication session instance.
 */
@property(nullable, nonatomic) id<MSACAuthenticationSession> authenticationSession API_AVAILABLE(ios(11.0));

/**
 * Distribute info tracking component which adds extra fields to logs.
 */
@property(nonatomic) MSACDistributeInfoTracker *distributeInfoTracker;

/**
 * A flag that indicates whether update flow is in progress or not.
 */
@property(atomic) BOOL updateFlowInProgress;

/**
 * Update track.
 */
@property(nonatomic) MSACUpdateTrack updateTrack;

/**
 * A flag to indicate whether automatic update check is disabled on start or not.
 */
@property(atomic) BOOL automaticCheckForUpdateDisabled;

/**
 * Returns the singleton instance. Meant for testing/demo apps only.
 *
 * @return the singleton instance of MSACDistribute.
 */
+ (instancetype)sharedInstance;

/**
 * Build the URL for token request with the given application secret.
 *
 * @param appSecret Application secret.
 * @param releaseHash The release hash of the current version.
 * @param isTesterApp Whether the URL should be constructed to link to the tester app.
 *
 * @return The final URL to request the token or nil if an error occurred.
 */
- (nullable NSURL *)buildTokenRequestURLWithAppSecret:(NSString *)appSecret
                                          releaseHash:(NSString *)releaseHash
                                          isTesterApp:(BOOL)isTesterApp;

/**
 * Disable checking the latest release of the application when the SDK starts.
 */
- (void)disableAutomaticCheckForUpdate;

/**
 * Open the given URL using the openURL method in the Shared Application.
 *
 * @param url URL to open.
 *
 * @return Whether the URL was opened or not.
 */
- (BOOL)openUrlUsingSharedApp:(NSURL *)url;

/**
 * Open the given URL using either SFAuthenticationSession, SFSafariViewController, or the Safari app based on which iOS version is used.
 *
 * @param url URL to open.
 */
- (void)openUrlInAuthenticationSessionOrSafari:(NSURL *)url;

/**
 * Open the given URL using an `SFAuthenticationSession` or `ASWebAuthenticationSession`. Must run on the UI thread! iOS 11 only.
 *
 * @param url URL to open.
 * @param usePresentationContext assign presentationContextProvider for ASWebAuthenticationSession when appropriate
 */
- (void)openURLInAuthenticationSessionWith:(NSURL *)url usePresentationContext:(BOOL)usePresentationContext;

/**
 * Open the given URL using an `SFSafariViewController`. Must run on the UI thread! iOS 9 and 10 only.
 *
 * @param url URL to open.
 * @param clazz `SFSafariViewController` class.
 */
- (void)openURLInSafariViewControllerWith:(NSURL *)url fromClass:(Class)clazz;

/**
 * Process URL request for the service.
 *
 * @param url  The url with parameters.
 *
 * @return `YES` if the URL is intended for App Center Distribute and the current application, `NO` otherwise.
 */
- (BOOL)openURL:(NSURL *)url;

/**
 * Send a request to get the latest release.
 *
 * @param updateToken The update token stored in keychain. This value can be nil if it is public distribution.
 * @param distributionGroupId The distribution group Id in keychain.
 * @param releaseHash The release hash of the current version.
 */
- (void)checkLatestRelease:(nullable NSString *)updateToken
       distributionGroupId:(nullable NSString *)distributionGroupId
               releaseHash:(NSString *)releaseHash;

/**
 * Send distribution first session log update.
 */
- (void)sendFirstSessionUpdateLog;

/**
 * Send a request to get information for installation.
 *
 * @param releaseHash The release hash of the current version.
 */
- (void)requestInstallInformationWith:(NSString *)releaseHash;

/**
 * Update workflow to make a decision based on release details.
 *
 * @param details Release details to handle.
 *
 * @return `YES` if this update is handled or `NO` otherwise.
 */
- (BOOL)handleUpdate:(MSACReleaseDetails *)details;

/**
 * Check if delegate is set and responds to selector of distributeNoReleaseAvailable, and invoke it if everything is correct.
 */
- (void)checkDelegateAndInvokeDistributeNoReleaseAvailableCallback;

/**
 * Save details about a downloaded release. After an app is updated and restarted, this info will be used to report a download and to update
 * the group ID (if it was changed).
 *
 * @param details Release details.
 */
- (void)storeDownloadedReleaseDetails:(nullable MSACReleaseDetails *)details;

/**
 * Remove details about downloaded release after it was installed.
 *
 * @param currentInstalledReleaseHash The release hash of the current version.
 */
- (void)removeDownloadedReleaseDetailsIfUpdated:(NSString *)currentInstalledReleaseHash;

/**
 * Get reporting parameters for updated release.
 *
 * @param isPublic YES if reporting stats for a public track, NO otherwise.
 * @param currentInstalledReleaseHash The release hash of the current version.
 * @param distributionGroupId The distribution group Id in keychain.
 *
 * @return Reporting parameters dictionary.
 */
- (nullable NSMutableDictionary *)getReportingParametersForUpdatedRelease:(BOOL)isPublic
                                              currentInstalledReleaseHash:(NSString *)currentInstalledReleaseHash
                                                      distributionGroupId:(nullable NSString *)distributionGroupId;

/**
 * After an app is updated and restarted, check if an updated release has different group ID and update current group ID if needed. Group ID
 * may change if one user is added to different distribution groups and a new release was updated from another group.
 *
 * @param currentInstalledReleaseHash The release hash of the current version.
 */
- (void)changeDistributionGroupIdAfterAppUpdateIfNeeded:(NSString *)currentInstalledReleaseHash;

/**
 * Show a dialog to ask a user to confirm update for a new release.
 */
- (void)showConfirmationAlert:(MSACReleaseDetails *)details;

/**
 * Notify custom user action for current release.
 *
 * @param action The action for the release.
 *
 * @discussion This method will be moved to public once Distribute allows to customize the update dialog.
 */
- (void)notifyUpdateAction:(MSACUpdateAction)action;

/**
 * Show a dialog to the user in case MSACDistribute was disabled while the updates-alert is shown.
 */
- (void)showDistributeDisabledAlert;

/**
 * Show a dialog to the user in case in-app updates are disabled due to update setup failure.
 *
 * @param errorMessage An error message to show in the dialog.
 */
- (void)showUpdateSetupFailedAlert:(NSString *)errorMessage;

/**
 * Check whether release details contain a newer version of release than current version.
 */
- (BOOL)isNewerVersion:(MSACReleaseDetails *)details;

/**
 * Check all parameters that determine if it's okay to check for an update.
 *
 * @return BOOL indicating that it's okay to check for updates.
 */
- (BOOL)checkForUpdatesAllowed;

/**
 * Dismiss the Safari hosting view controller.
 */
- (void)dismissEmbeddedSafari;

/**
 * Start update workflow.
 */
- (void)startUpdate;

/**
 * Start download for the given details.
 */
- (void)startDownload:(nullable MSACReleaseDetails *)details;

/**
 * Close application for update.
 */
- (void)closeApp;

/**
 * Check for the latest release using the selected update track.
 */
- (void)checkForUpdate;

/**
 * Method to reset the singleton when running tests only. So calling sharedInstance returns a fresh instance.
 */
+ (void)resetSharedInstance;

@end

NS_ASSUME_NONNULL_END
