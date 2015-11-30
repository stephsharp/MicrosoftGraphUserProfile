/*
 * Copyright (c) Microsoft. All rights reserved. Licensed under the MIT license. See full license at the bottom of this file.
 */

#import "MGUserProfileAPIClient.h"
#import "NSDictionary+MGUserProfile.h"

//Standard URL strings needed for the unified endpoint
static NSString * const BASE_URL_STRING = @"https://graph.microsoft.com/v1.0/";
static NSString * const RESOURCE_ID_STRING = @"https://graph.microsoft.com/";

@interface MGUserProfileAPIClient ()

@property (readonly, nonatomic) NSString *baseURL;
@property (readonly, nonatomic) NSString *resourceID;
@property (readonly, nonatomic) MGAuthenticationManager *authenticationManager;

@end

@implementation MGUserProfileAPIClient

#pragma mark - Initializers

- (instancetype)initWithTenant:(NSString *)tenant authenticationManager:(MGAuthenticationManager *)authenticationManager
{
    self = [super init];

    if (self) {
        _baseURL = [NSString stringWithFormat:@"%@%@", BASE_URL_STRING, tenant];
        _resourceID = RESOURCE_ID_STRING;
        _authenticationManager = authenticationManager;
    }

    return self;
}

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

#pragma mark - Fetch users

//Fetches all the users from the Active Directory
- (void)fetchAllUsersWithProgressHandler:(void (^)(NSArray *users, NSError *error))progressHandler
                       completionHandler:(void (^)(NSArray *users, NSError *error))completionHandler
{
    NSString *requestURLString = [NSString stringWithFormat:@"%@%@", _baseURL, @"users?$orderby=displayName&$select=id,displayName,givenName,surname,jobTitle,department,city,mobilePhone,businessPhones,mail,userType"];


    [self fetchAllUsersWithRequestURL:requestURLString progressHandler:progressHandler completionHandler:completionHandler];
}

- (void)fetchAllUsersWithRequestURL:(NSString *)urlString
                    progressHandler:(void (^)(NSArray *users, NSError *error))progressHandler
                  completionHandler:(void (^)(NSArray *users, NSError *error))completionHandler
{
    NSMutableURLRequest *mutableRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [mutableRequest setValue:@"application/json;odata.metadata=minimal;odata.streaming=true" forHTTPHeaderField:@"accept"];

    [self fetchDataWithRequest:[mutableRequest copy] completionHandler:^(NSData *data, NSError *error) {
        if (error) {
            completionHandler(nil, error);
            return;
        }

        NSDictionary *jsonPayload = [NSJSONSerialization JSONObjectWithData:data
                                                                    options:0
                                                                      error:NULL];
        jsonPayload = [self sanitizeKeysInDictionary:jsonPayload];

        NSMutableArray *users = [[NSMutableArray alloc] init];

        for (NSDictionary *userData in jsonPayload[@"value"]) {
            MGUser *user = [MGUserProfileAPIClient userFromJSONDictionary:userData];
            [users addObject:user];
        }

        NSString *nextPage = [jsonPayload stringForKey:@"nextLink"];

        if (nextPage.length > 0) {
            progressHandler(users, nil);
            [self fetchAllUsersWithRequestURL:nextPage progressHandler:progressHandler completionHandler:completionHandler];
        }
        else {
            completionHandler(users, nil);
        }
    }];
}

- (void)fetchUserWithId:(NSString *)userId
      completionHandler:(void (^)(MGUser *, NSError *))completionHandler
{
    NSURL *requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@%@", _baseURL, @"users/", userId, @"?$select=id,displayName,givenName,surname,jobTitle,department,city,mobilePhone,businessPhones,mail,userType"]];

    NSMutableURLRequest *mutableRequest = [NSMutableURLRequest requestWithURL:requestURL];
    [mutableRequest setValue:@"application/json;odata.metadata=minimal;odata.streaming=true" forHTTPHeaderField:@"accept"];

    [self fetchDataWithRequest:[mutableRequest copy] completionHandler:^(NSData *data, NSError *error) {
        if (error) {
            completionHandler(nil, error);
            return;
        }

        NSDictionary *jsonPayload = [NSJSONSerialization JSONObjectWithData:data
                                                                    options:0
                                                                      error:NULL];

        MGUser *user = [MGUserProfileAPIClient userFromJSONDictionary:jsonPayload];
        completionHandler(user, nil);
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

#pragma mark - Fetch photos

- (void)fetchPhotoInfoWithUserId:(NSString *)userId
               completionHandler:(void (^)(NSDictionary *photoInfo, NSError *error))completionHandler
{
    NSURL *requestURL = [self urlForPhotoInfoWithUserId:userId];

    NSMutableURLRequest *mutableRequest = [NSMutableURLRequest requestWithURL:requestURL];
    [mutableRequest setValue:@"application/json;odata.metadata=minimal;odata.streaming=true" forHTTPHeaderField:@"accept"];

    [self fetchDataWithRequest:[mutableRequest copy] completionHandler:^(NSData *data, NSError *error) {
        if (error) {
            completionHandler(nil, error);
            return;
        }

        NSDictionary *jsonPayload = [NSJSONSerialization JSONObjectWithData:data
                                                                    options:0
                                                                      error:NULL];
        completionHandler(jsonPayload, nil);
    }];
}

- (void)fetchPhotoWithUserId:(NSString *)userId
                        size:(NSUInteger)size
           completionHandler:(void (^)(UIImage *image, NSError *error))completionHandler
{
    NSURL *requestURL = [self urlForPhotoWithUserId:userId size:size];
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];

    [self fetchDataWithRequest:request completionHandler:^(NSData *data, NSError *error) {
        UIImage *image = [UIImage imageWithData:data];
        completionHandler(image, nil);
    }];
}

- (NSURL *)urlForPhotoWithUserId:(NSString *)userId size:(NSUInteger)size
{
    return [self userPhotoURLWithUserId:userId size:size metadataOnly:NO];
}

- (NSURL *)urlForPhotoInfoWithUserId:(NSString *)userId
{
    return [self userPhotoURLWithUserId:userId size:0 metadataOnly:YES];
}

- (NSURL *)userPhotoURLWithUserId:(NSString *)userId size:(NSUInteger)size metadataOnly:(BOOL)metadata
{
//    NSString *sizeString = (size > 0) ? [NSString stringWithFormat:@"%luX%lu/", (unsigned long)size, (unsigned long)size] : @"";
    NSString *userPhotoString = @"/photo/";
    NSString *valueString = metadata ? @"" : @"$value";

//    if (size > 0 || metadata) {
//        userPhotoString = @"/photos/";
//    }

    NSString *requestURL = [NSString stringWithFormat:@"%@%@%@%@%@", _baseURL, @"users/", userId, userPhotoString, /*sizeString,*/ valueString];

    return [NSURL URLWithString:requestURL];
}

#pragma mark - JSON helpers

+ (MGUser *)userFromJSONDictionary:(NSDictionary *)jsonDictionary
{
    return [[MGUser alloc] initWithId:[jsonDictionary stringForKey:@"id"]
                          displayName:[jsonDictionary stringForKey:@"displayName"]
                            givenName:[jsonDictionary stringForKey:@"givenName"]
                              surname:[jsonDictionary stringForKey:@"surname"]
                             jobTitle:[jsonDictionary stringForKey:@"jobTitle"]
                           department:[jsonDictionary stringForKey:@"department"]
                                 city:[jsonDictionary stringForKey:@"city"]
                          mobilePhone:[jsonDictionary stringForKey:@"mobilePhone"]
                       businessPhones:jsonDictionary[@"businessPhones"]
                                email:[jsonDictionary stringForKey:@"mail"]];
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