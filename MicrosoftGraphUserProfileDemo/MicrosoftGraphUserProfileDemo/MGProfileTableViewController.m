#import "MGProfileTableViewController.h"

@interface MGProfileTableViewController () <UITableViewDataSource>

@property (nonatomic, weak) IBOutlet UILabel *displayNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *jobTitleLabel;

@end

@implementation MGProfileTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.displayNameLabel.text = self.person.displayName;
    self.jobTitleLabel.text = self.person.jobTitle;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"PersonDetailCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    NSInteger row = indexPath.row;

    switch (row) {
        case 0:
            cell.textLabel.text = @"email";
            cell.detailTextLabel.text = self.person.email;
            break;
        case 1:
            cell.textLabel.text = @"mobile";
            cell.detailTextLabel.text = self.person.mobilePhone;
            break;
        case 2:
            cell.textLabel.text = @"work phone";
            cell.detailTextLabel.text = self.person.workPhones.firstObject;
            break;
        case 3:
            cell.textLabel.text = @"department";
            cell.detailTextLabel.text = self.person.department;
            break;
        case 4:
            cell.textLabel.text = @"location";
            cell.detailTextLabel.text = self.person.location;
            break;
        default:
            break;
    }

    return cell;
}

@end
