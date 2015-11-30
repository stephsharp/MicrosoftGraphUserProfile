#import "MGAuthenticationController.h"
#import "MGAuthenticationManager+MGDemo.h"

@implementation MGAuthenticationController

static NSString *const RESOURCE_ID_STRING = @"https://graph.microsoft.com/";

- (void)startAuthentication
{
    MGAuthenticationManager *authManager = [MGAuthenticationManager sharedInstance];

    [authManager acquireAuthTokenWithResourceId:RESOURCE_ID_STRING
                              completionHandler:^(ADAuthenticationResult *result, NSError *error) {
                                  if (error) {
                                      [self.delegate authenticationController:self didFailWithError:error];
                                  }
                                  else {
                                      [self.delegate authenticationControllerDidComplete:self];
                                  }
                              }];
}

#pragma mark - AuthenticationResultHandler

- (void)handleAuthenticationResultWithCurrentUserId:(NSString *)userId token:(NSString *)token
{

}

@end
