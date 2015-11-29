#import <Foundation/Foundation.h>
#import "MGPerson.h"

@interface MGPersonController : NSObject

+ (MGPersonController *)sharedPersonController;
+ (void)resetSharedPersonController;

@property (nonatomic) NSMutableArray *people;
@property (nonatomic) MGPerson *currentPerson;

- (void)fetchCurrentPersonWithCompletion:(void (^)(MGPerson *person, NSString *errorString))completion;
//- (void)fetchUserPhotoInfo:(ODPerson *)person completion:(void (^)(MGPerson *person, NSError *error))completion;

- (void)updatePeopleWithProgress:(void (^)(void))progress
                         success:(void (^)(void))success
                         failure:(void (^)(NSString *error))failure;

@end
