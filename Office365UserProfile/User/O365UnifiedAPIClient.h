/*
 * Copyright (c) Microsoft. All rights reserved. Licensed under the MIT license. See full license at the bottom of this file.
 */

#import <Foundation/Foundation.h>
#import "O365AuthenticationManager.h"
#import "O365User.h"

@interface O365UnifiedAPIClient : NSObject

//Note: Usually the tenant string looks like x.onmicrosoft.com/
//DO NOT FORGET END THE STRING WITH A '/'
- (instancetype)initWithTenant:(NSString *)tenant authenticationManager:(O365AuthenticationManager *)authenticationManager
 NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (void)fetchAllUsersWithRequestURL:(NSString *)urlString
                  completionHandler:(void (^)(NSArray *allUsers, NSString *nextPage, NSError *error))completionHandler;

- (void)fetchUserWithId:(NSString *)userObjectID
      completionHandler:(void (^)(O365User *user, NSError *error))completionHandler;

- (void)fetchPhotoWithUserId:(NSString *)userObjectID
           completionHandler:(void (^)(UIImage *image, NSError *error))completionHandler;

@end

// *********************************************************
//
// O365-iOS-Profile, https://github.com/OfficeDev/O365-iOS-Profile
//
// Copyright (c) Microsoft Corporation
// All rights reserved.
//
// MIT License:
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
// LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// *********************************************************