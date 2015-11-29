#import <Foundation/Foundation.h>
#import "MGAuthenticationManager.h"

@protocol MGAuthenticationControllerDelegate;

@interface MGAuthenticationController : NSObject <AuthenticationResultHandler>

@property (nonatomic, weak) id<MGAuthenticationControllerDelegate> delegate;

- (void)startAuthentication;

@end

@protocol MGAuthenticationControllerDelegate

- (void)authenticationControllerDidComplete:(MGAuthenticationController *)authenticationController;
- (void)authenticationController:(MGAuthenticationController *)authenticationController didFailWithError:(NSError *)error;

@end
