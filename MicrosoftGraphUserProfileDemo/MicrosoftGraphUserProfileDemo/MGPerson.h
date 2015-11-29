#import <Foundation/Foundation.h>

@class MGUser;

@interface MGPerson : NSObject

@property (nonatomic, readonly) NSString *personId;
@property (nonatomic) NSString *displayName;
@property (nonatomic) NSString *firstName;
@property (nonatomic) NSString *lastName;

@property (nonatomic) NSString *email;
@property (nonatomic) NSString *mobilePhone;
@property (nonatomic) NSArray *workPhones;

@property (nonatomic) NSString *jobTitle;
@property (nonatomic) NSString *department;
@property (nonatomic) NSString *location;

@property (nonatomic) NSURL *photoURL;
@property (nonatomic, readonly) NSURLRequest *photoRequest;

- (instancetype)initWithUser:(MGUser *)user;

@end
