/*
 * Copyright (c) Microsoft. All rights reserved. Licensed under the MIT license. See full license at the bottom of this file.
 */

#import "O365UnifiedAPIClient.h"
#import "NSDictionary+O365.h"

//Standard URL strings needed for the unified endpoint
static NSString * const BASE_URL_STRING = @"https://graph.microsoft.com/beta/";
static NSString * const RESOURCE_ID_STRING = @"https://graph.microsoft.com/";

@interface O365UnifiedAPIClient ()

@property (readonly, nonatomic) NSString *baseURL;
@property (readonly, nonatomic) NSString *resourceID;
@property (readonly, nonatomic) O365AuthenticationManager *authenticationManager;

@end

@implementation O365UnifiedAPIClient

- (instancetype)initWithTenant:(NSString *)tenant authenticationManager:(O365AuthenticationManager *)authenticationManager
{
    self = [super init];

    if (self) {
        _baseURL = [NSString stringWithFormat:@"%@%@", BASE_URL_STRING, tenant];
        _resourceID = RESOURCE_ID_STRING;
        _authenticationManager = authenticationManager;
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

    O365AuthenticationManager *authenticationManager = [[O365AuthenticationManager alloc] initWithPlist:plist];

    return [self initWithTenant:[settings valueForKey:@"Tenant"] authenticationManager:authenticationManager];
}

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

//Fetches all the users from the Active Directory
- (void)fetchAllUsersWithRequestURL:(NSString *)urlString completionHandler:(void (^)(NSArray *allUsers, NSString *nextPage, NSError *error))completionHandler
{
    NSString *requestURLString = urlString ?: [NSString stringWithFormat:@"%@%@", _baseURL, @"users?$orderby=displayName"];

    NSMutableURLRequest *mutableRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestURLString]];
    [mutableRequest setValue:@"application/json;odata.metadata=minimal;odata.streaming=true" forHTTPHeaderField:@"accept"];

    [self fetchDataWithRequest:[mutableRequest copy] completionHandler:^(NSData *data, NSError *error) {
        NSDictionary *jsonPayload = [NSJSONSerialization JSONObjectWithData:data
                                                                    options:0
                                                                      error:NULL];
        jsonPayload = [self sanitizeKeysInDictionary:jsonPayload];

        NSMutableArray *users = [[NSMutableArray alloc] init];

        for (NSDictionary *userData in jsonPayload[@"value"]) {
            O365User *user = [O365UnifiedAPIClient userFromJSONDictionary:userData];
            [users addObject:user];
        }

        NSString *nextPage = jsonPayload[@"nextLink"];
        completionHandler(users, nextPage, error);
    }];
}

//Fetches the basic user information from Active Directory
- (void)fetchUserWithId:(NSString *)userObjectID
      completionHandler:(void (^)(O365User *, NSError *))completionHandler
{
    NSURL *requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@", _baseURL, @"users/", userObjectID]];

    NSMutableURLRequest *mutableRequest = [NSMutableURLRequest requestWithURL:requestURL];
    [mutableRequest setValue:@"application/json;odata.metadata=minimal;odata.streaming=true" forHTTPHeaderField:@"accept"];

    [self fetchDataWithRequest:[mutableRequest copy] completionHandler:^(NSData *data, NSError *error) {
        NSDictionary *jsonPayload = [NSJSONSerialization JSONObjectWithData:data
                                                                    options:0
                                                                      error:NULL];

        O365User *user = [O365UnifiedAPIClient userFromJSONDictionary:jsonPayload];
        completionHandler(user, error);
    }];
}

- (void)fetchDataWithRequest:(NSURLRequest *)request
           completionHandler:(void (^)(NSData *data, NSError *error))completionHandler
{
    [self.authenticationManager acquireAuthTokenWithResourceId:self.resourceID
                                             completionHandler:^(ADAuthenticationResult *result, NSError *error) {
                                                 if (error) {
                                                     completionHandler(nil, error);
                                                     return;
                                                 }

                                                 NSString *accessToken = result.tokenCacheStoreItem.accessToken;

                                                 NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
                                                 NSURLSession *delegateFreeSession = [NSURLSession sessionWithConfiguration:config
                                                                                                                   delegate:nil
                                                                                                              delegateQueue:[NSOperationQueue mainQueue]];

                                                 NSMutableURLRequest *mutableRequest = [request mutableCopy];

                                                 NSString *authorization = [NSString stringWithFormat:@"Bearer %@", accessToken];
                                                 [mutableRequest setValue:authorization forHTTPHeaderField:@"Authorization"];

                                                 [[delegateFreeSession dataTaskWithRequest:mutableRequest
                                                                         completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                                             NSLog(@"Got response %@ with error %@.\n", response, error);
                                                                             NSLog(@"DATA:\n%@\nEND DATA\n",
                                                                                   [[NSString alloc] initWithData:data
                                                                                                         encoding:NSUTF8StringEncoding]);

                                                                             completionHandler(data, error);
                                                                         }] resume];
                                             }];
}

+ (O365User *)userFromJSONDictionary:(NSDictionary *)jsonDictionary
{
    return [[O365User alloc] initWithId:[jsonDictionary stringForKey:@"objectId"]
                            displayName:[jsonDictionary stringForKey:@"displayName"]
                              givenName:[jsonDictionary stringForKey:@"givenName"]
                                surname:[jsonDictionary stringForKey:@"surname"]
                               jobTitle:[jsonDictionary stringForKey:@"jobTitle"]
                             department:[jsonDictionary stringForKey:@"department"]
                                   city:[jsonDictionary stringForKey:@"city"]
                                 mobile:[jsonDictionary stringForKey:@"mobile"]
                                  phone:[jsonDictionary stringForKey:@"telephoneNumber"]
                                  email:[jsonDictionary stringForKey:@"mail"]];
}

- (void)fetchPhotoWithUserId:(NSString *)userObjectID
                        size:(NSUInteger)size
           completionHandler:(void (^)(UIImage *image, NSError *error))completionHandler
{
    NSURL *requestURL = [self urlForPhotoWithUserId:userObjectID size:size];
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];

    [self fetchDataWithRequest:request completionHandler:^(NSData *data, NSError *error) {
        UIImage *image = [UIImage imageWithData:data];
        completionHandler(image, nil);
    }];
}

- (NSURL *)urlForPhotoWithUserId:(NSString *)userObjectID size:(NSUInteger)size
{
    NSString *sizeString = @"";
    NSString *userPhotoString = @"/userphoto/";

    if (size > 0) {
        sizeString = [NSString stringWithFormat:@"%luX%lu/", size, (unsigned long)size];
        userPhotoString = @"/userphotos/";
    }

    NSString *requestURL = [NSString stringWithFormat:@"%@%@%@%@%@%@", _baseURL, @"users/", userObjectID, userPhotoString, sizeString, @"$value"];

    return [NSURL URLWithString:requestURL];
}

- (NSDictionary *)sanitizeKeysInDictionary:(NSDictionary *)dictionary
{
    NSMutableDictionary *sanitizedMutableDictionary = [NSMutableDictionary new];

    for (NSString *key in dictionary) {
        NSString *sanitizedKey = [key stringByReplacingOccurrencesOfString:@"@odata." withString:@""];
        sanitizedMutableDictionary[sanitizedKey] = dictionary[key];
    }

    return [sanitizedMutableDictionary copy];
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