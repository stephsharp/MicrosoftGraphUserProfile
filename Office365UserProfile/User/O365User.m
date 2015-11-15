#import "O365User.h"

@implementation O365User

- (instancetype)initWithId:(NSString *)userId
               displayName:(NSString *)displayName
                 givenName:(NSString *)givenName
                   surname:(NSString *)surname
                  jobTitle:(NSString *)jobTitle
                department:(NSString *)department
                      city:(NSString *)city
                    mobile:(NSString *)mobile
                     phone:(NSString *)phone
                     email:(NSString *)email
{
    self = [super init];

    if (self) {
        _userId = userId;
        _displayName = displayName;
        _givenName = givenName;
        _surname = surname;
        _jobTitle = jobTitle;
        _department = department;
        _city = city;
        _mobile = mobile;
        _phone = phone;
        _email = email;
    }

    return self;
}

- (instancetype)initWithId:(NSString *)userId
               displayName:(NSString *)displayName
                  jobTitle:(NSString *)jobTitle
{
    return [self initWithId:userId
                displayName:displayName
                  givenName:nil
                    surname:nil
                   jobTitle:jobTitle
                 department:nil
                       city:nil
                     mobile:nil
                      phone:nil
                      email:nil];
}

- (instancetype)init
{
    return [self initWithId:nil displayName:nil jobTitle:nil];
}

@end
