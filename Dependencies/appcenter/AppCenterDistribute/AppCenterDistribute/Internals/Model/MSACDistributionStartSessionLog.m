// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSACDistributionStartSessionLog.h"

static NSString *const kMSACTypeDistributionStartSessionLog = @"distributionStartSession";

@implementation MSACDistributionStartSessionLog

- (instancetype)init {
  if ((self = [super init])) {
    self.type = kMSACTypeDistributionStartSessionLog;
  }
  return self;
}

#pragma mark - NSCoding

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
}

@end
