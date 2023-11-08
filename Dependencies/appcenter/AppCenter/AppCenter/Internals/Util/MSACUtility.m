// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSACAppCenterInternal.h"
#import "MSACLoggerInternal.h"
#import "MSACUtility+Application.h"
#import "MSACUtility+Date.h"
#import "MSACUtility+Environment.h"
#import "MSACUtility+File.h"
#import "MSACUtility+PropertyValidation.h"
#import "MSACUtility+StringFormatting.h"

// SDK versioning struct. Needs to be big enough to hold the info.
typedef struct {
  uint8_t info_version;
  const char ms_name[32];
  const char ms_version[32];
  const char ms_build[32];
} ms_info_t;

// SDK versioning.
static ms_info_t appcenter_library_info __attribute__((section("__TEXT,__ms_ios,regular,no_dead_strip"))) = {
    .info_version = 1, .ms_name = APP_CENTER_C_NAME, .ms_version = APP_CENTER_C_VERSION, .ms_build = APP_CENTER_C_BUILD};

@implementation MSACUtility

/**
 * Dictionary for migration classes, where key - old class name, value - new class type.
 */
static NSMutableDictionary<NSString *, id> *targetClasses;

/**
 * Array of classes that are allowed to be serialized securely using the archiver.
 */
static NSArray *allowedClasses;

/**
 * @discussion Workaround for exporting symbols from category object files. See article
 * https://medium.com/ios-os-x-development/categories-in-static-libraries-78e41f8ddb96#.aedfl1kl0
 */
__attribute__((used)) static void importCategories() {
  [NSString stringWithFormat:@"%@ %@ %@ %@ %@ %@", MSACUtilityApplicationCategory, MSACUtilityEnvironmentCategory, MSACUtilityDateCategory,
                             MSACUtilityStringFormattingCategory, MSACUtilityFileCategory, MSACUtilityPropertyValidationCategory];
}

+ (NSString *)sdkName {
  return [NSString stringWithUTF8String:appcenter_library_info.ms_name];
}

+ (NSString *)sdkVersion {
  return [NSString stringWithUTF8String:appcenter_library_info.ms_version];
}

+ (NSObject *)unarchiveKeyedData:(NSData *)data {
  if (!data) {
    return nil;
  }
  NSError *error;
  NSObject *unarchivedData;
  NSException *exception;
  @try {
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:data error:&error];
    unarchiver.requiresSecureCoding = YES;
    NSSet *allowedClassesSet = [NSSet setWithArray:allowedClasses];
    unarchivedData = [unarchiver decodeObjectOfClasses:allowedClassesSet forKey:NSKeyedArchiveRootObjectKey];
  } @catch (NSException *ex) {
    exception = ex;
  }
  if (!unarchivedData || exception) {
    // Unarchiving process failed.
    MSACLogError([MSACAppCenter logTag], @"Unarchiving NSData failed with error: %@",
                 exception ? exception.reason : error.localizedDescription);
  }
  return unarchivedData;
}

+ (NSData *)archiveKeyedData:(id)myData {
  if (!myData) {
    return nil;
  }
  NSError *error;
  NSData *archivedData;
  NSException *exception;
  @try {
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initRequiringSecureCoding:YES];
    [archiver encodeObject:myData forKey:NSKeyedArchiveRootObjectKey];
    [archiver finishEncoding];
    archivedData = archiver.encodedData;
  } @catch (NSException *ex) {
    exception = ex;
  }
  if (!archivedData || exception) {

    // Unarchiving process failed.
    MSACLogError([MSACAppCenter logTag], @"Archiving NSData failed with error: %@",
                 exception ? exception.reason : error.localizedDescription);
  }
  return archivedData;
}

+ (void)addMigrationClasses:(NSDictionary<NSString *, id> *)data {
  if (targetClasses == nil) {
    targetClasses = [NSMutableDictionary new];
  }
  [targetClasses addEntriesFromDictionary:data];
}

+ (void)addAllowedClasses:(NSArray *)allowedClassesArray {
  if (allowedClasses == nil) {
    allowedClasses = [NSMutableArray new];
  }
  allowedClasses = [allowedClasses arrayByAddingObjectsFromArray:allowedClassesArray];
}
@end
