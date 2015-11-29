#import "MGPerson.h"
#import "MGUser.h"

@implementation MGPerson

- (instancetype)initWithUser:(MGUser *)user
{
    if (self = [super init]) {
        _personId = user.userId;
        _displayName = user.displayName;
        _firstName = user.givenName;
        _lastName = user.surname;
        _email = user.email;
        _mobilePhone = user.mobilePhone;
        _workPhones = user.businessPhones;
        _jobTitle = user.jobTitle;
        _location = user.city;
        _department = user.department;
    }
    return self;
}

//- (NSURLRequest *)photoRequest
//{
//    return [self imageRequestWithURL:self.thumbnailImageURL];
//}
//
//- (NSURLRequest *)imageRequestWithURL:(NSURL *)url
//{
//    NSMutableURLRequest *imageRequest = [NSMutableURLRequest requestWithURL:url
//                                                                cachePolicy:NSURLRequestReturnCacheDataElseLoad
//                                                            timeoutInterval:60];
//
//    NSString *authorization = [ODLoginController storedAuthToken];
//    [imageRequest setValue:authorization forHTTPHeaderField:@"Authorization"];
//
//    return [imageRequest copy];
//}

@end
