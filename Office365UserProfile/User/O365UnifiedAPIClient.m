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

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

//Fetches all the users from the Active Directory
- (void)fetchAllUsersWithCompletionHandler:(void (^)(NSArray *, NSError *)) completionHandler
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
                                            
                                            NSString *requestURL = [NSString stringWithFormat:@"%@%@", _baseURL, @"users?$filter=userType%20eq%20'Member'"];
                                            
                                            
                                            NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL: [NSURL URLWithString:requestURL]];
                                            
                                            
                                            NSString *authorization = [NSString stringWithFormat:@"Bearer %@", accessToken];

                                            NSString *auth = [NSString stringWithFormat:@"AUTHTOKEN: \"%@\"", authorization];
                                            NSLog(auth);
                                            
                                            
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
                                                                            
                                                                            NSString *jobTitle;
                                                                            
                                                                            if(userData[@"jobTitle"] && userData[@"jobTitle"] != [NSNull null])
                                                                            {
                                                                                jobTitle = userData[@"jobTitle"];
                                                                            }
                                                                            else
                                                                            {
                                                                                jobTitle = @"";
                                                                            }
                                                                            
                                                                            O365User *user = [[O365User alloc] initWithId:objectId
                                                                                                              displayName:displayName
                                                                                                                 jobTitle:jobTitle];
                                                                            [users addObject:user];
                                                                            
                                                                        }
                                                                        
                                                                        
                                                                        completionHandler(users, error);
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

                                            NSString *requestURL = [NSString stringWithFormat:@"%@%@%@%@", _baseURL, @"users/", userObjectID, @"/userphoto/$value"];

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