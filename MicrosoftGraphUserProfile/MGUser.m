#import "MGUser.h"

@implementation MGUser

- (instancetype)initWithId:(NSString *)userId
               displayName:(NSString *)displayName
                 givenName:(NSString *)givenName
                   surname:(NSString *)surname
                  jobTitle:(NSString *)jobTitle
                department:(NSString *)department
                      city:(NSString *)city
               mobilePhone:(NSString *)mobilePhone
            businessPhones:(NSArray *)businessPhones
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
        _mobilePhone = mobilePhone;
        _businessPhones = businessPhones;
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
                mobilePhone:nil
             businessPhones:nil
                      email:nil];
}

- (instancetype)init
{
    return [self initWithId:nil displayName:nil jobTitle:nil];
}

@end
