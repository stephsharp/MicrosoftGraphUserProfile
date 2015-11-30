#import "MGPersonController.h"
#import "MGPerson.h"
#import "MGUserProfileAPIClient+MGDemo.h"
#import "MGAuthenticationController.h"

@interface MGPersonController ()

@property (nonatomic) MGUserProfileAPIClient *userProfileAPIClient;
@property (nonatomic) BOOL fetching;
@property (nonatomic) NSMutableArray *fetchedPeople;

@end

@implementation MGPersonController

static MGPersonController *_sharedPersonController = nil;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _userProfileAPIClient = [MGUserProfileAPIClient userProfileAPIClient];
    }
    return self;
}

+ (MGPersonController *)sharedPersonController
{
    if (_sharedPersonController)
        return _sharedPersonController;
    
    _sharedPersonController = [[MGPersonController alloc] init];
    
    return  _sharedPersonController;
}

+ (void)resetSharedPersonController
{
    _sharedPersonController = nil;
}

- (NSMutableArray *)people
{
    if (!_people) {
        _people = [[NSMutableArray alloc] init];
    }

    return _people;
}

- (NSArray *)fetchedPeople
{
    if (!_fetchedPeople) {
        _fetchedPeople = [[NSMutableArray alloc] init];
    }

    return _fetchedPeople;
}

- (void)fetchCurrentPersonWithCompletion:(void (^)(MGPerson *person, NSString *errorString))completion
{
    __weak MGPersonController *weakSelf = self;

    [self.userProfileAPIClient fetchCurrentUserWithCompletionHandler:^(MGUser *user, NSError *error) {
        if (!error) {
            if ([user isKindOfClass:[MGUser class]]) {
                MGPerson *person = [[MGPerson alloc] initWithUser:user];
                weakSelf.currentPerson = person;
                if (completion) {
                    completion(person, nil);
                }
            }
            else {
                if (completion) {
                    completion(nil, @"Invalid response");
                }
            }
        }
        else {
            if (completion) {
                completion(nil, error.localizedDescription);
            }
        }
    }];
}

- (void)updatePeopleWithProgress:(void (^)(void))progress
                         success:(void (^)(void))success
                         failure:(void (^)(NSString *))failure
{
    if (!self.fetching) {
        self.fetching = YES;

        // Need a separate array to store the people currently being fetched so the view
        // can use self.thePeople to display people until the fetch has completed
        self.fetchedPeople = nil;

        void (^errorBlock)(NSError *error) = ^void(NSError *error) {
            self.fetching = NO;
            failure(error.localizedDescription);
        };

        void (^progressBlock)(NSArray *users) = ^void(NSArray *users) {
            [self parseUsers:users withSuccess:^{
                self.people = self.fetchedPeople;
                progress();
            }];
        };

        [self.userProfileAPIClient fetchAllUsersWithProgressHandler:^(NSArray *users, NSError *error) {
            if (error) {
                errorBlock(error);
            }
            else {
                progressBlock(users);
            }
        } completionHandler:^(NSArray *users, NSError *error) {
            if (error) {
                errorBlock(error);
            }
            else {
                progressBlock(users);
                
                self.fetching = NO;
                success();
            }
        }];
    }
}

- (void)parseUsers:(NSArray *)users withSuccess:(void (^)(void))success
{
    for (MGUser *user in users) {
        MGPerson *person = [[MGPerson alloc] initWithUser:user];
        [self.fetchedPeople addObject:person];
    }

    NSArray *sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"displayName"
                                                             ascending:YES
                                                              selector:@selector(localizedCaseInsensitiveCompare:)]];
    self.fetchedPeople = [[self.fetchedPeople sortedArrayUsingDescriptors:sortDescriptors] mutableCopy];

    success();
}

//- (void)fetchUserPhotoInfo:(MGPerson *)person completion:(void (^)(MGPerson *person, NSError *error))completion
//{
//    [self.userProfileAPIClient fetchPhotoInfoWithUserId:person.personId
//                                  completionHandler:^(NSDictionary *photoInfo, NSError *error) {
//
//                                      NSUInteger photoWidth = [photoInfo[@"width"] unsignedIntegerValue];
//
//                                      if (!photoWidth) {
//                                          completion(nil, error);
//                                          return;
//                                      }
//
//                                      person.thumbnailImageURL = [self.unifiedAPIClient urlForPhotoWithUserId:person.personId size:photoWidth];
//
//                                      completion(person, nil);
//    }];
//}

@end
