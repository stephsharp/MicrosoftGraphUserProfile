#import "MGAuthenticationManager+MGDemo.h"
#import "MGConstants.h"
#import "MGAuthenticationController.h"

@implementation MGAuthenticationManager (MGDemo)

+ (MGAuthenticationManager *)sharedInstance
{
    static MGAuthenticationManager *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] initWithPlist:MG_AUTHENTICATION_PLIST];
        _sharedInstance.authenticationResultHandler = [MGAuthenticationController new];
    });

    return _sharedInstance;
}

@end
