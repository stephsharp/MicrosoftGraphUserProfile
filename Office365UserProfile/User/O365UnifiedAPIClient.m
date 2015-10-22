/*
 * Copyright (c) Microsoft. All rights reserved. Licensed under the MIT license. See full license at the bottom of this file.
 */

#import "O365UnifiedAPIClient.h"

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
    [self.authenticationManager acquireAuthTokenWithResourceId:_resourceID
                                        completionHandler:^(ADAuthenticationResult *result, NSError *error) {
                                            if (error) {
                                                completionHandler(nil, nil, error);
                                                return;
                                            }
                                            
                                            NSString *accessToken = result.tokenCacheStoreItem.accessToken;
                                            
                                            NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
                                            NSURLSession *delegateFreeSession = [NSURLSession sessionWithConfiguration:
                                                                                 config delegate: nil delegateQueue: [NSOperationQueue mainQueue]];
                                            
                                            NSString *requestURL = urlString ?: [NSString stringWithFormat:@"%@%@", _baseURL, @"users?$orderby=displayName"];
                                            
                                            NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL: [NSURL URLWithString:requestURL]];
                                            
                                            
                                            NSString *authorization = [NSString stringWithFormat:@"Bearer %@", accessToken];

                                            NSLog([NSString stringWithFormat:@"AUTHTOKEN: \"%@\"", authorization]);

                                            
                                            [theRequest setValue:authorization forHTTPHeaderField:@"Authorization"];
                                            
                                            [theRequest setValue:@"application/json;odata.metadata=minimal;odata.streaming=true" forHTTPHeaderField:@"accept"];
                                            
                                            
                                            [[delegateFreeSession dataTaskWithRequest:theRequest
                                                                    completionHandler:^(NSData *data, NSURLResponse *response,
                                                                                        NSError *error) {
                                                                        NSLog(@"Got response %@ with error %@.\n", response,
                                                                              error);
                                                                        NSLog(@"DATA:\n%@\nEND DATA\n",
                                                                              [[NSString alloc] initWithData: data
                                                                                                    encoding: NSUTF8StringEncoding]);
                                                                        
                                                                        
                                                                        NSDictionary *jsonPayload = [NSJSONSerialization JSONObjectWithData:data
                                                                                                                                    options:0
                                                                                                                                      error:NULL];
                                                                        jsonPayload = [self sanitizeKeysInDictionary:jsonPayload];

                                                                        NSMutableArray *users = [[NSMutableArray alloc] init];
                                                                        
                                                                        for (NSDictionary *userData in jsonPayload[@"value"]) {
                                                                            
                                                                            NSString *objectId;

                                                                            if(userData[@"objectId"])
                                                                            {
                                                                                objectId = userData[@"objectId"];
                                                                            }
                                                                            else
                                                                            {
                                                                                objectId = @"";
                                                                            }

                                                                            NSString *displayName;

                                                                            if(userData[@"displayName"] && userData[@"displayName"] != [NSNull null])
                                                                            {
                                                                                displayName = userData[@"displayName"];
                                                                            }
                                                                            else
                                                                            {
                                                                                displayName = @"";
                                                                            }

                                                                            NSString *givenName;

                                                                            if(userData[@"givenName"] && userData[@"givenName"] != [NSNull null])
                                                                            {
                                                                                givenName = userData[@"givenName"];
                                                                            }
                                                                            else
                                                                            {
                                                                                givenName = @"";
                                                                            }

                                                                            NSString *surname;

                                                                            if(userData[@"surname"] && userData[@"surname"] != [NSNull null])
                                                                            {
                                                                                surname = userData[@"surname"];
                                                                            }
                                                                            else
                                                                            {
                                                                                surname = @"";
                                                                            }

                                                                            NSString *city;

                                                                            if(userData[@"city"] && userData[@"city"] != [NSNull null])
                                                                            {
                                                                                city = userData[@"city"];
                                                                            }
                                                                            else
                                                                            {
                                                                                city = @"";
                                                                            }

                                                                            NSString *department;

                                                                            if(userData[@"department"] && userData[@"department"] != [NSNull null])
                                                                            {
                                                                                department = userData[@"department"];
                                                                            }
                                                                            else
                                                                            {
                                                                                department = @"";
                                                                            }

                                                                            NSString *jobTitle;

                                                                            if(userData[@"jobTitle"] && userData[@"jobTitle"] != [NSNull null])
                                                                            {
                                                                                jobTitle = userData[@"jobTitle"];
                                                                            }
                                                                            else
                                                                            {
                                                                                jobTitle = @"";
                                                                            }

                                                                            NSString *mobile;

                                                                            if(userData[@"mobile"] && userData[@"mobile"] != [NSNull null])
                                                                            {
                                                                                mobile = userData[@"mobile"];
                                                                            }
                                                                            else
                                                                            {
                                                                                mobile = @"";
                                                                            }

                                                                            NSString *phone;

                                                                            if(userData[@"telephoneNumber"] && userData[@"telephoneNumber"] != [NSNull null])
                                                                            {
                                                                                phone = userData[@"telephoneNumber"];
                                                                            }
                                                                            else
                                                                            {
                                                                                phone = @"";
                                                                            }

                                                                            NSString *email;

                                                                            if(userData[@"mail"] && userData[@"mail"] != [NSNull null])
                                                                            {
                                                                                email = userData[@"mail"];
                                                                            }
                                                                            else
                                                                            {
                                                                                email = @"";
                                                                            }

                                                                            O365User *user = [[O365User alloc] initWithId:objectId
                                                                                                              displayName:displayName
                                                                                                                givenName:givenName
                                                                                                                  surname:surname
                                                                                                                 jobTitle:jobTitle
                                                                                                               department:department
                                                                                                                     city:city
                                                                                                                   mobile:mobile
                                                                                                                    phone:phone
                                                                                                                    email:email];
                                                                            [users addObject:user];
                                                                            
                                                                        }
                                                                        
                                                                        NSString *nextPage = jsonPayload[@"nextLink"];
                                                                        completionHandler(users, nextPage, error);

                                                                    }] resume];
                                            
                                        }];
  
}

//Fetches the basic user information from Active Directory
- (void)fetchUserWithId:(NSString *)userObjectID
      completionHandler:(void (^)(O365User *, NSError *))completionHandler
{
    [self.authenticationManager acquireAuthTokenWithResourceId:_resourceID
                                        completionHandler:^(ADAuthenticationResult *result, NSError *error) {
                                            if (error) {
                                                completionHandler(nil,error);
                                                return;
                                            }


                                            NSString *accessToken = result.tokenCacheStoreItem.accessToken;

                                            NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
                                            NSURLSession *delegateFreeSession = [NSURLSession sessionWithConfiguration:
                                                                                 config delegate: nil delegateQueue: [NSOperationQueue mainQueue]];
                                        
                                            NSString *requestURL = [NSString stringWithFormat:@"%@%@%@", _baseURL, @"users/", userObjectID];
                                            
                                            
                                            NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL: [NSURL URLWithString:requestURL]];


                                            NSString *authorization = [NSString stringWithFormat:@"Bearer %@", accessToken];


                                            [theRequest setValue:authorization forHTTPHeaderField:@"Authorization"];

                                            [theRequest setValue:@"application/json;odata.metadata=minimal;odata.streaming=true" forHTTPHeaderField:@"accept"];


                                            [[delegateFreeSession dataTaskWithRequest:theRequest
                                                                    completionHandler:^(NSData *data, NSURLResponse *response,
                                                                                        NSError *error) {
                                                                        NSLog(@"Got response %@ with error %@.\n", response,
                                                                              error);
                                                                        NSLog(@"DATA:\n%@\nEND DATA\n",
                                                                              [[NSString alloc] initWithData: data
                                                                                                    encoding: NSUTF8StringEncoding]);


                                                                        NSDictionary *jsonPayload = [NSJSONSerialization JSONObjectWithData:data
                                                                                                                                    options:0
                                                                                                                                      error:NULL];
                                                                        
                                                                        NSString *objectId;
                                                                        
                                                                        if(jsonPayload[@"objectId"])
                                                                        {
                                                                            objectId = jsonPayload[@"objectId"];
                                                                        }
                                                                        else
                                                                        {
                                                                            objectId = @"";
                                                                        }
                                                                        
                                                                        NSString *displayName;
                                                                        
                                                                        if(jsonPayload[@"displayName"] && jsonPayload[@"displayName"] != [NSNull null])
                                                                        {
                                                                            displayName = jsonPayload[@"displayName"];
                                                                        }
                                                                        else
                                                                        {
                                                                            displayName = @"";
                                                                        }

                                                                        NSString *givenName;

                                                                        if(jsonPayload[@"givenName"] && jsonPayload[@"givenName"] != [NSNull null])
                                                                        {
                                                                            givenName = jsonPayload[@"givenName"];
                                                                        }
                                                                        else
                                                                        {
                                                                            givenName = @"";
                                                                        }

                                                                        NSString *surname;

                                                                        if(jsonPayload[@"surname"] && jsonPayload[@"surname"] != [NSNull null])
                                                                        {
                                                                            surname = jsonPayload[@"surname"];
                                                                        }
                                                                        else
                                                                        {
                                                                            surname = @"";
                                                                        }

                                                                        NSString *city;
                                                                        
                                                                        if(jsonPayload[@"city"] && jsonPayload[@"city"] != [NSNull null])
                                                                        {
                                                                            city = jsonPayload[@"city"];
                                                                        }
                                                                        else
                                                                        {
                                                                            city = @"";
                                                                        }
                                                                        
                                                                        NSString *department;
                                                                        
                                                                        if(jsonPayload[@"department"] && jsonPayload[@"department"] != [NSNull null])
                                                                        {
                                                                            department = jsonPayload[@"department"];
                                                                        }
                                                                        else
                                                                        {
                                                                            department = @"";
                                                                        }
                                                                        
                                                                        NSString *jobTitle;
                                                                        
                                                                        if(jsonPayload[@"jobTitle"] && jsonPayload[@"jobTitle"] != [NSNull null])
                                                                        {
                                                                            jobTitle = jsonPayload[@"jobTitle"];
                                                                        }
                                                                        else
                                                                        {
                                                                            jobTitle = @"";
                                                                        }

                                                                        NSString *mobile;

                                                                        if(jsonPayload[@"mobile"] && jsonPayload[@"mobile"] != [NSNull null])
                                                                        {
                                                                            mobile = jsonPayload[@"mobile"];
                                                                        }
                                                                        else
                                                                        {
                                                                            mobile = @"";
                                                                        }

                                                                        NSString *phone;
                                                                        
                                                                        if(jsonPayload[@"telephoneNumber"] && jsonPayload[@"telephoneNumber"] != [NSNull null])
                                                                        {
                                                                            phone = jsonPayload[@"telephoneNumber"];
                                                                        }
                                                                        else
                                                                        {
                                                                            phone = @"";
                                                                        }
                                                                        
                                                                        NSString *email;
                                                                        
                                                                        if(jsonPayload[@"mail"] && jsonPayload[@"mail"] != [NSNull null])
                                                                        {
                                                                            email = jsonPayload[@"mail"];
                                                                        }
                                                                        else
                                                                        {
                                                                            email = @"";
                                                                        }
               
                                                                        

                                                                        O365User *user = [[O365User alloc] initWithId:objectId
                                                                                                          displayName:displayName
                                                                                                            givenName:givenName
                                                                                                              surname:surname
                                                                                                             jobTitle:jobTitle
                                                                                                           department:department
                                                                                                                 city:city
                                                                                                               mobile:mobile
                                                                                                                phone:phone
                                                                                                                email:email];

                                                                        completionHandler(user, error);
                                                                    }] resume];

                                        }];

}

- (void)fetchPhotoWithUserId:(NSString *)userObjectID
                        size:(NSUInteger)size
           completionHandler:(void (^)(UIImage *image, NSError *error))completionHandler
{
    [self.authenticationManager acquireAuthTokenWithResourceId:_resourceID
                                        completionHandler:^(ADAuthenticationResult *result, NSError *error) {
                                            if (error) {
                                                completionHandler(nil,error);
                                                return;
                                            }

                                            NSString *accessToken = result.tokenCacheStoreItem.accessToken;

                                            NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
                                            NSURLSession *delegateFreeSession = [NSURLSession sessionWithConfiguration:config
                                                                                                              delegate:nil
                                                                                                         delegateQueue:[NSOperationQueue mainQueue]];

                                            NSString *sizeString = size > 0 ? [NSString stringWithFormat:@"%luX%lu/", size, (unsigned long)size] : @"";
                                            NSString *userPhotoString = size > 0 ? @"/userphotos/" : @"/userphoto/";

                                            NSString *requestURL = [NSString stringWithFormat:@"%@%@%@%@%@%@", _baseURL, @"users/", userObjectID, userPhotoString, sizeString, @"$value"];

                                            NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL: [NSURL URLWithString:requestURL]];

                                            NSString *authorization = [NSString stringWithFormat:@"Bearer %@", accessToken];
                                            [theRequest setValue:authorization forHTTPHeaderField:@"Authorization"];

                                            [[delegateFreeSession dataTaskWithRequest:theRequest
                                                                    completionHandler:^(NSData *data, NSURLResponse *response,
                                                                                        NSError *error) {

                                                                        NSLog(@"Got response %@ with error %@.\n", response,
                                                                              error);
                                                                        NSLog(@"DATA:\n%@\nEND DATA\n",
                                                                              [[NSString alloc] initWithData: data
                                                                                                    encoding: NSUTF8StringEncoding]);
                                                                        
                                                                        
                                                                        UIImage *image = [UIImage imageWithData:data];

                                                                        completionHandler(image, nil);
                                                                    }] resume];
                                            
                                        }];

}

- (NSURL *)urlForPhotoWithUserId:(NSString *)userObjectID size:(NSUInteger)size
{
    NSString *sizeString = size > 0 ? [NSString stringWithFormat:@"%luX%lu/", size, (unsigned long)size] : @"";
    NSString *userPhotoString = size > 0 ? @"/userphotos/" : @"/userphoto/";

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