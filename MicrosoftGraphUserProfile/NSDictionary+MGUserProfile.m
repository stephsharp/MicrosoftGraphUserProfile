#import "NSDictionary+MGUserProfile.h"

@implementation NSDictionary (MGUserProfile)

- (NSString *)stringForKey:(NSString *)key
{
    NSString *string = @"";

    if(self[key] && self[key] != [NSNull null]) {
        string = self[key];
    }

    return string;
}

@end
