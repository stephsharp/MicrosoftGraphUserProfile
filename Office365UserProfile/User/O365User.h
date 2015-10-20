#import <Foundation/Foundation.h>

@interface O365User : NSObject

@property (readonly, nonatomic) NSString *objectId;
@property (readonly, nonatomic) NSString *displayName;
@property (readonly, nonatomic) NSString *jobTitle;
@property (readonly, nonatomic) NSString *department;
@property (readonly, nonatomic) NSString *city;
@property (readonly, nonatomic) NSString *mobile;
@property (readonly, nonatomic) NSString *phone;
@property (readonly, nonatomic) NSString *email;

- (instancetype)initWithId:(NSString *)objectId
               displayName:(NSString *)displayName
                  jobTitle:(NSString *)jobTitle
                department:(NSString *)department
                      city:(NSString *)city
                    mobile:(NSString *)mobile
                     phone:(NSString *)phone
                     email:(NSString *)email;

- (instancetype)initWithId:(NSString *)objectId
               displayName:(NSString *)displayName
                  jobTitle:(NSString *)jobTitle;

@end
