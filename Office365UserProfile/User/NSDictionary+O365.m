#import "NSDictionary+O365.h"

@implementation NSDictionary (O365)

- (NSString *)stringForKey:(NSString *)key
{
    NSString *string = @"";

    if(self[key] && self[key] != [NSNull null]) {
        string = self[key];
    }

    return string;
}

@end
