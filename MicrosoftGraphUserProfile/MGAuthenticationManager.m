/*
 * Copyright (c) Microsoft. All rights reserved. Licensed under the MIT license. See full license at the bottom of this file.
 */

#import "MGAuthenticationManager.h"
#import <ADALiOS/ADAuthenticationSettings.h>
#import <ADALiOS/ADLogger.h>
#import <ADALiOS/ADInstanceDiscovery.h>
#import <ADALiOS/ADAuthenticationBroker.h>

@interface MGAuthenticationManager ()

@property (nonatomic) ADAuthenticationContext *authContext;
@property (readonly, nonatomic) NSURL *redirectURL;
@property (readonly, nonatomic) NSString *authority;
@property (readonly, nonatomic) NSString *clientId;

@end

@implementation MGAuthenticationManager

- (instancetype)initWithRedirectURL:(NSString *)redirectURL
                           clientID:(NSString *)clientID
                          authority:(NSString *)authority
{
    self = [super init];

    if (self) {
        _redirectURL = [NSURL URLWithString:redirectURL];
        _clientId = clientID;
        _authority = authority;
    }

    return self;
}

- (instancetype)initWithPlist:(NSString *)plist
{
    NSString *path = [[NSBundle mainBundle] pathForResource:plist ofType:@"plist"];
    NSDictionary *settings;

    if (path) {
        settings = [[NSDictionary alloc] initWithContentsOfFile:path];
    } else {
        @throw([[NSException alloc] initWithName:@"NO_SETTINGS_PLIST"
                                          reason:[NSString stringWithFormat:@"%@.plist not found in bundle.", plist]
                                        userInfo:[[NSDictionary alloc] init]]);
    }

    return [self initWithRedirectURL:[settings valueForKey:@"RedirectURL"]
                            clientID:[settings valueForKey:@"ClientID"]
                           authority:[settings valueForKey:@"Authority"]];
}

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

// Acquire access and refresh tokens from Azure AD for the user
- (void)acquireAuthTokenWithResourceId:(NSString *)resourceId
                     completionHandler:(void (^)(ADAuthenticationResult *result, NSError *error))completionBlock
{
    [self acquireAuthTokenWithResourceId:resourceId promptBehavior:AD_PROMPT_AUTO completionHandler:completionBlock];
}

- (void)acquireAuthTokenWithResourceId:(NSString *)resourceId
                        promptBehavior:(ADPromptBehavior)promptBehavior
                     completionHandler:(void (^)(ADAuthenticationResult *result, NSError *error))completionBlock
{
    ADAuthenticationError *ADerror;
    self.authContext = [ADAuthenticationContext authenticationContextWithAuthority:self.authority
                                                                             error:&ADerror];

    // The first time this application is run, the [ADAuthenticationContext acquireTokenWithResource]
    // manager will send a request to the AUTHORITY (see the const at the top of this file) which
    // will redirect you to a login page. You will provide your credentials and the response will
    // contain your refresh and access tokens. The second time this application is run, and assuming
    // you didn't clear your token cache, the authentication manager will use the access or refresh
    // token in the cache to authenticate client requests.
    // This will result in a call to the service if you need to get an access token.
    [self.authContext acquireTokenWithResource:resourceId
                                      clientId:self.clientId
                                   redirectUri:self.redirectURL
                                promptBehavior:promptBehavior
                                        userId:nil
                          extraQueryParameters:nil
                               completionBlock:^(ADAuthenticationResult *result) {
                                   if (AD_SUCCEEDED != result.status) {
                                       completionBlock(nil, result.error);
                                   }
                                   else {
                                       NSString *currentUserId = result.tokenCacheStoreItem.userInformation.userId;
                                       NSString *token =         result.tokenCacheStoreItem.accessToken;

                                       [self.authenticationResultHandler handleAuthenticationResultWithCurrentUserId:currentUserId token:token];

                                       completionBlock(result, nil);
                                   }
                               }];
}

- (void)cancel
{
    [[ADAuthenticationBroker sharedInstance] cancel];
}

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
