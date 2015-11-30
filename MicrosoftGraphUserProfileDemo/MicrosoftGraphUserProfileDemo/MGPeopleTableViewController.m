#import "MGPeopleTableViewController.h"
#import "MGPersonController.h"
#import "MGPerson.h"
#import "NSString+MGDemo.h"
#import "MGAuthenticationController.h"
#import <ADALiOS/ADErrorCodes.h>
#import "MGProfileTableViewController.h"

@interface MGPeopleTableViewController () <UITableViewDataSource, UITableViewDelegate,MGAuthenticationControllerDelegate>

@property (nonatomic) MGPersonController *personController;

@property (nonatomic) NSArray *sectionKeys;
@property (nonatomic) NSMutableDictionary *peopleDictionary;

@end

@implementation MGPeopleTableViewController

#pragma mark - Getters & setters

- (void)setPersonController:(MGPersonController *)personController
{
    _personController = personController;
    [_personController addObserver:self forKeyPath:@"people" options:0 context:NULL];
}

- (NSMutableDictionary *)peopleDictionary
{
    if (!_peopleDictionary) {
        _peopleDictionary = [[NSMutableDictionary alloc] init];
    }
    return _peopleDictionary;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.personController = [MGPersonController sharedPersonController];
    [self setupSectionIndex];

    if (self.personController.people.count > 0) {
        [self updatePersonDictionary];
    }

    MGAuthenticationController *authController = [MGAuthenticationController new];
    authController.delegate = self;
    [authController startAuthentication];
}

- (void)dealloc
{
    [self.personController removeObserver:self forKeyPath:@"people"];
}

#pragma mark - MGAuthenticationControllerDelegate

- (void)authenticationControllerDidComplete:(MGAuthenticationController *)authenticationController
{
    [[MGPersonController sharedPersonController] fetchCurrentPersonWithCompletion:nil];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self beginRefreshing];
    });
}

- (void)authenticationController:(MGAuthenticationController *)authenticationController didFailWithError:(NSError *)error
{
    if (error.code != AD_ERROR_USER_CANCEL && error.code != AD_ERROR_SUCCEEDED) {
        [self showAlertForError:error title:@"Authentication error"];
    }
}

- (void)showAlertForError:(NSError *)error title:(NSString *)title
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:error.localizedDescription
                                                                      preferredStyle:UIAlertControllerStyleAlert];

    [alertController addAction:[UIAlertAction actionWithTitle:@"OK"
                                                        style:UIAlertActionStyleCancel
                                                      handler:nil]];

    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Update staff list

- (void)beginRefreshing
{
    // Initialize the refresh control
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.backgroundColor = [UIColor whiteColor];
    self.refreshControl.tintColor = [UIColor lightGrayColor];
    [self.refreshControl addTarget:self
                            action:@selector(pullToRefresh)
                  forControlEvents:UIControlEventValueChanged];

    // Hack to fix iOS bug with refresh control tintColor:
    // http://stackoverflow.com/q/19026351/1367622
    // https://github.com/davbeck/RefreshTintFail
    CGFloat refreshControlHeight = self.refreshControl.frame.size.height;
    [self.tableView setContentOffset:CGPointMake(0, -1) animated:NO];
    [self.tableView setContentOffset:CGPointMake(0, 0) animated:NO];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView setContentOffset:CGPointMake(0, self.tableView.contentOffset.y-refreshControlHeight) animated:YES];
        [self.refreshControl beginRefreshing];
    });

    [self updatePeople];
}

- (void)pullToRefresh
{
    [self updatePeople];
}

- (void)updatePeople
{
    [self clearTable];

    [self.personController updatePeopleWithProgress:^{
        [self.tableView reloadData];
    } success:^{
        [self.refreshControl endRefreshing];
    } failure:^(NSString *err) {
        [self.refreshControl endRefreshing];

        // If some data was fetched successfully
        if (self.peopleDictionary.count > 0) {
        }
        else {
            self.sectionKeys = nil;
            [self.tableView reloadData];
        }
    }];
}

- (void)clearTable
{
    [self.peopleDictionary removeAllObjects];
    self.sectionKeys = nil;
    [self.tableView reloadData];
}

- (void)updatePersonDictionary
{
    for (MGPerson *person in self.personController.people) {
        [self addPersonToDictionary:person];
    }

    // Update section keys array
    self.sectionKeys = [[self.peopleDictionary allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];

    [self.tableView reloadData];
}

- (void)addPersonToDictionary:(MGPerson *)person
{
    // Get first letter of name
    NSString *firstLetter = [person.displayName uppercaseInitial];

    // Find which section this option belongs in
    NSMutableArray *sectionForLetter = [self.peopleDictionary objectForKey:firstLetter];
    if (sectionForLetter != nil) {
        // Section exists
        if ([sectionForLetter indexOfObject:person] == NSNotFound) {
            // Add option to array
            [sectionForLetter addObject:person];
        }
    } else {
        // Section doesn't exist, create it and add option
        sectionForLetter = [[NSMutableArray alloc] initWithObjects:person, nil];
        [self.peopleDictionary setObject:sectionForLetter forKey:firstLetter];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return (NSInteger)[self.sectionKeys count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *sectionArray = [self.peopleDictionary objectForKey:[self keyForSectionIndex:section]];
    return (NSInteger)[sectionArray count];
}

- (NSString *)keyForSectionIndex:(NSInteger)index
{
    if ([self.sectionKeys count] != 0)
        return self.sectionKeys[(NSUInteger)index];

    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self keyForSectionIndex:section];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return self.sectionKeys;
}

- (void)setupSectionIndex
{
    self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
    self.tableView.sectionIndexColor = [UIColor darkGrayColor];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"PersonCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

//    [cell.avatarImageView cancelImageRequestOperation];

    NSArray *sectionArray = [self.peopleDictionary objectForKey:[self keyForSectionIndex:indexPath.section]];
    NSUInteger index = (NSUInteger)indexPath.row;
    MGPerson *person = [sectionArray objectAtIndex:index];

    cell.textLabel.text = person.displayName;
    cell.detailTextLabel.text = person.jobTitle;

//    cell.personId = thePerson.personId;
//
////    [cell.nameLabel setText:thePerson.fullName];
//
//    if ([thePerson isEqual:self.personController.currentPerson]) {
//        cell.nameLabel.textColor = [UIColor odeceeGreenColor];
//        cell.meLabel.hidden = NO;
//    }
//    else {
//        cell.nameLabel.textColor = [UIColor darkTextColor];
//        cell.meLabel.hidden = YES;
//    }
//    
//    cell.roleLabel.text = thePerson.jobTitle;

//    UIImage *placeholderImage = [thePerson.initials placeholderImageFromStringWithSize:ODThumbnailImageSize];
//    cell.avatarImageView.image = placeholderImage;
//
//    if (thePerson.thumbnailImageURL && thePerson.thumbnailImageURL.absoluteString.length > 0) {
//        [self updatePhotoForPerson:thePerson inCell:cell withPlaceholder:placeholderImage];
//    }
//    else {
//        [self.personController fetchUserPhotoInfo:thePerson completion:^(ODPerson *person, NSError *error) {
//            // Don't update image if cell has been reused
//            if (!error && person.personId == cell.personId) {
//                [self updatePhotoForPerson:person inCell:cell withPlaceholder:placeholderImage];
//            }
//        }];
//    }

    return cell;
}

//- (void)updatePhotoForPerson:(ODPerson *)person inCell:(ODStaffTableViewCell *)cell withPlaceholder:(UIImage *)placeholder
//{
//    NSURLRequest *imageRequest = person.thumbImageRequest;
//    [cell.avatarImageView setImageWithURLRequest:imageRequest placeholderImage:placeholder success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull image) {
//        cell.avatarImageView.image = image;
//    } failure:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, NSError * _Nonnull error) {
//        NSLog(@"error: %@", error);
//    }];
//
//    CGSize imageSize = CGSizeMake(ODThumbnailImageSize, ODThumbnailImageSize);
//    cell.avatarImageView.image = [cell.avatarImageView.image imageByScalingAndCroppingForSize:imageSize];
//}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqualToString:@"people"]) {
        [self updatePersonDictionary];
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"UserProfile"]) {
        if ([sender isKindOfClass:[UITableViewCell class]]) {
            UITableViewCell *cell = (UITableViewCell *)sender;
            NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];

            NSString *sectionKey = [self keyForSectionIndex:indexPath.section];
            NSArray *sectionArray = self.peopleDictionary[sectionKey];
            MGPerson *selectedPerson = sectionArray[(NSUInteger)indexPath.row];

            MGProfileTableViewController *profileTVC = (MGProfileTableViewController *)segue.destinationViewController;
            profileTVC.person = selectedPerson;
        }
    }
    else if ([segue.identifier isEqualToString:@"MyProfile"]) {
        MGProfileTableViewController *profileTVC = (MGProfileTableViewController *)segue.destinationViewController;
        profileTVC.person = self.personController.currentPerson;
    }
}

@end
