#import "MGUserProfileAPIClient+MGDemo.h"
#import "MGAuthenticationManager+MGDemo.h"
#import "MGConstants.h"
#import "MGPlistReader.h"

@implementation MGUserProfileAPIClient (MGDemo)

+ (MGUserProfileAPIClient *)userProfileAPIClient
{
    MGAuthenticationManager *authManager = [MGAuthenticationManager sharedInstance];

    NSDictionary *plist = [MGPlistReader plistWithName:MG_AUTHENTICATION_PLIST];
    NSString *tenant = [plist valueForKey:@"Tenant"];

    return [[MGUserProfileAPIClient alloc] initWithTenant:tenant authenticationManager:authManager];
}

@end
