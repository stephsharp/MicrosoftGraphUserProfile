#import "MGPlistReader.h"

@implementation MGPlistReader

+ (NSDictionary *)plistWithName:(NSString *)plist
{
    NSString *path = [[NSBundle mainBundle] pathForResource:plist ofType:@"plist"];
    NSDictionary *plistDictionary;

    if (path) {
        plistDictionary = [[NSDictionary alloc] initWithContentsOfFile:path];
    } else {
        @throw([[NSException alloc] initWithName:@"NO_PLIST_FOUND"
                                          reason:[NSString stringWithFormat:@"%@.plist not found in bundle.", plist]
                                        userInfo:[[NSDictionary alloc] init]]);
    }

    return plistDictionary;
}

@end
