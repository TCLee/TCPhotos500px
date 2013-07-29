//
//  TCPopularViewController.m
//  TCPhotos500px
//
//  Created by Lee Tze Cheun on 7/14/13.
//  Copyright (c) 2013 Lee Tze Cheun. All rights reserved.
//

#import "TCThumbnailsViewController.h"
#import "TCPhotoViewController.h"
#import "TCPhotoCell.h"
#import "TCPhotoStream.h"
#import "TCPhotoStreamCategory.h"
#import "TCPhoto.h"

// Storyboard Segue IDs
static NSString * const kSegueIdentifierCategoryPopover = @"showCategoryList";
static NSString * const kSegueIdentifierPhotoView = @"showPhoto";

@interface TCThumbnailsViewController ()

@property (nonatomic, weak) IBOutlet UISegmentedControl *featureSegmentedControl;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *categoryBarButtonItem;

// Show a popover for the list of categories to filter the photo stream.
@property (nonatomic, weak) UIPopoverController *categoryListPopoverController;

@property (nonatomic, strong, readonly) TCPhotoViewController *photoViewController;

// Photo Stream model that is presented on the collection view.
@property (nonatomic, strong) TCPhotoStream *photoStream;

// Array of all supported photo stream features.
@property (nonatomic, strong, readonly) NSArray *photoStreamFeatures;

// User selected a new photo stream feature.
- (IBAction)featureChanged:(id)sender;

@end

#pragma mark -

@implementation TCThumbnailsViewController

@synthesize photoViewController = _photoViewController;
@synthesize photoStreamFeatures = _photoStreamFeatures;

#pragma mark - Lazy Properties

- (TCPhotoViewController *)photoViewController
{
    if (!_photoViewController) {
        // We use the class name as the Storyboard Identifier.
        _photoViewController = [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([TCPhotoViewController class])];
    }
    return _photoViewController;
}

- (NSArray *)photoStreamFeatures
{
    if (!_photoStreamFeatures) {
        _photoStreamFeatures = @[@(PXAPIHelperPhotoFeaturePopular),
                                 @(PXAPIHelperPhotoFeatureEditors),
                                 @(PXAPIHelperPhotoFeatureUpcoming),
                                 @(PXAPIHelperPhotoFeatureFreshToday)];
    }
    return _photoStreamFeatures;
}

#pragma mark - View Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Resize the segmented control here, otherwise it will get squished by the autolayout.
    CGFloat currentHeight = self.featureSegmentedControl.bounds.size.height;
    self.featureSegmentedControl.bounds = CGRectMake(0, 0, 500, currentHeight);
    
    __weak typeof(self) weakSelf = self;
    
    // When user pulls to refresh, we reload the photo stream with the currently
    // selected feature and category.
    [self.collectionView addPullToRefreshWithActionHandler:^{
        __strong typeof(self) strongSelf = weakSelf;
        
        [strongSelf reloadPhotoStreamForFeature:strongSelf.photoStream.feature
                                 category:strongSelf.photoStream.category];
        
        [strongSelf.collectionView.pullToRefreshView stopAnimating];
    }];
    
    // SVPullToRefreshView will be nil until after we call addPullToRefreshWithActionHandler:
    self.collectionView.pullToRefreshView.textColor = [UIColor whiteColor];
    self.collectionView.pullToRefreshView.arrowColor = [UIColor whiteColor];
}

#pragma mark - View Rotation Events

// We need to manually forward the view rotation events to TCPhotoViewController
// because it is not attached to the root view controller.

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self.photoViewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self.photoViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

#pragma mark - Memory Management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    // Dispose of any resources that can be recreated.    
    self.photoStream = nil;
}

#pragma mark - Photo Stream Model

- (TCPhotoStream *)photoStream
{
    if (!_photoStream) {
        // Initialize with a default photo stream for the first time.
        // Subsequently, user can choose the photo stream they want to view.
        _photoStream = [[TCPhotoStream alloc] initWithFeature:kPXAPIHelperDefaultFeature
                                                     category:PXAPIHelperUnspecifiedCategory];
    }
    return _photoStream;
}

- (void)reloadPhotoStreamForFeature:(PXAPIHelperPhotoFeature)feature
                           category:(PXPhotoModelCategory)category
{
    // Creates a new photo stream (discarding the old one) for the given feature and category.
    self.photoStream = [[TCPhotoStream alloc] initWithFeature:feature category:category];
    
    // Call reloadData to trigger the data source methods to lazily fetch the photo
    // stream's pages.
    [self.collectionView reloadData];
    
    // Scroll back to top when reloading a new photo stream.
    [self.collectionView setContentOffset:CGPointZero animated:NO];
}

#pragma mark - UICollectionView Data Source

- (NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section
{
    // If there are no photos yet, we should initially show the default number of placeholders.
    return MAX([self.photoStream photoCount], kPXAPIHelperDefaultResultsPerPage);
}

// Return the photo cell view.
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * const CellIdentifier = @"PhotoCell";
    
    // Draw a border around the cell view.
    TCPhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.imageView.image = nil;
    [cell.activityIndicator startAnimating];
    
    // Get the photo from the cache if available; otherwise async fetch from network.
    TCPhoto *photo = [self.photoStream photoAtIndex:indexPath.item completion:^(TCPhoto *photo, NSError *error) {
        if (photo) {
            [collectionView reloadData];
        } else if (error) {
            NSLog(@"[500px Error] - %@", [error localizedDescription]);
        }
    }];
    
    // Display photo on the cell, if photo is available.
    [cell setPhoto:photo];
    return cell;
}

#pragma mark - UICollectionView Delegate

// User selected a thumbnail. Show the large size photo.
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    TCPhotoCell *photoCell = (TCPhotoCell *)[collectionView cellForItemAtIndexPath:indexPath];    
    [self.photoViewController presentWithRootViewController:self.view.window.rootViewController
                                                      photo:photoCell.photo
                                                   animated:YES];    
}

#pragma mark - TCCategoryListViewController Delegate

// Dismiss popover and reload photo stream with selected category.
- (void)categoryListViewController:(TCCategoryListViewController *)categoryListViewController
                 didSelectCategory:(TCPhotoStreamCategory *)category
{
    [self.categoryListPopoverController dismissPopoverAnimated:YES];
    
    self.categoryBarButtonItem.title = category.title;
    
    [self reloadPhotoStreamForFeature:self.photoStream.feature
                             category:category.value];
}

#pragma mark - Storyboard Segues

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([identifier isEqualToString:kSegueIdentifierCategoryPopover]) {
        // If the popover is already showing, we'll dismiss it and not show it again.
        // Otherwise, we will have multiple popovers stacked over each other.
        if (self.categoryListPopoverController) {
            [self.categoryListPopoverController dismissPopoverAnimated:YES];
            return NO;
        }
    } else if ([identifier isEqualToString:kSegueIdentifierPhotoView]) {
        // If photo model is available, then we can show the full size photo.
        return nil != [(TCPhotoCell *)sender photo];
    }
    
    // By default, we want to perform the segue.
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:kSegueIdentifierCategoryPopover]) {
        // Save a reference to this segue's popover controller.
        // We will need to dismiss it to dismiss the popover later.
        self.categoryListPopoverController = [(UIStoryboardPopoverSegue *)segue popoverController];
        
        // Set up ourself as the delegate, so that we know when a category is selected from the list.
        TCCategoryListViewController *categoryListViewController = [segue destinationViewController];
        categoryListViewController.delegate = self;
        
    } else if ([[segue identifier] isEqualToString:kSegueIdentifierPhotoView]) {
//        TCPhotoViewController *photoViewController = [segue destinationViewController];
//        [photoViewController setPhoto:[(TCPhotoCell *)sender photo]];
    }
}

#pragma mark - IBAction

// Reload photo stream with new selected feature.
- (IBAction)featureChanged:(id)sender
{
    NSInteger selectedSegmentIndex = [self.featureSegmentedControl selectedSegmentIndex];    
    PXAPIHelperPhotoFeature selectedFeature = [self.photoStreamFeatures[selectedSegmentIndex] integerValue];
    
    [self reloadPhotoStreamForFeature:selectedFeature
                             category:self.photoStream.category];
}

@end
