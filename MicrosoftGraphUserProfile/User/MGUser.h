#import <Foundation/Foundation.h>

@interface MGUser : NSObject

@property (readonly, nonatomic) NSString *userId;
@property (readonly, nonatomic) NSString *displayName;
@property (readonly, nonatomic) NSString *givenName;
@property (readonly, nonatomic) NSString *surname;
@property (readonly, nonatomic) NSString *jobTitle;
@property (readonly, nonatomic) NSString *department;
@property (readonly, nonatomic) NSString *city;
@property (readonly, nonatomic) NSString *mobilePhone;
@property (readonly, nonatomic) NSArray *businessPhones;
@property (readonly, nonatomic) NSString *email;

- (instancetype)initWithId:(NSString *)userId
               displayName:(NSString *)displayName
                 givenName:(NSString *)givenName
                   surname:(NSString *)surname
                  jobTitle:(NSString *)jobTitle
                department:(NSString *)department
                      city:(NSString *)city
               mobilePhone:(NSString *)mobilePhone
            businessPhones:(NSArray *)businessPhones
                     email:(NSString *)email;

- (instancetype)initWithId:(NSString *)userId
               displayName:(NSString *)displayName
                  jobTitle:(NSString *)jobTitle;

@end
