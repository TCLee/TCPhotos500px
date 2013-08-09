//
//  TCPopularViewController.m
//  TCPhotos500px
//
//  Created by Lee Tze Cheun on 7/14/13.
//  Copyright (c) 2013 Lee Tze Cheun. All rights reserved.
//

#import "TCThumbnailsViewController.h"
#import "TCPhotoModalViewController.h"
#import "TCPhotoCell.h"
#import "TCPhotoStream.h"
#import "TCPhotoStreamCategory.h"
#import "TCPhoto.h"

// FlatUIKit
#import "UIColor+FlatUI.h"
#import "UINavigationBar+FlatUI.h"
#import "UIBarButtonItem+FlatUI.h"
#import "UIPopoverController+FlatUI.h"
#import "FUISegmentedControl.h"

// Storyboard Segue IDs
static NSString * const kSegueIdentifierCategoryPopover = @"showCategoryList";

@interface TCThumbnailsViewController ()

@property (nonatomic, weak) IBOutlet FUISegmentedControl *featureSegmentedControl;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *categoryBarButtonItem;

// Show a popover for the list of categories to filter the photo stream.
@property (nonatomic, weak) UIPopoverController *categoryListPopoverController;

// Show the large size photo in an overlay modal view.
@property (nonatomic, strong, readonly) TCPhotoModalViewController *photoModalViewController;

// Photo Stream model that is presented on the collection view.
@property (nonatomic, strong) TCPhotoStream *photoStream;

// Array of all supported photo stream features.
@property (nonatomic, strong, readonly) NSArray *photoStreamFeatures;

// User selected a new photo stream feature.
- (IBAction)featureChanged:(id)sender;

@end

#pragma mark -

@implementation TCThumbnailsViewController

@synthesize photoModalViewController = _photoModalViewController;
@synthesize photoStreamFeatures = _photoStreamFeatures;

#pragma mark - Lazy Properties

- (TCPhotoModalViewController *)photoModalViewController
{
    if (!_photoModalViewController) {
        _photoModalViewController = [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([TCPhotoModalViewController class])];
    }
    return _photoModalViewController;
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

#pragma mark - View Events

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Configure and customize the control's styles.
    [self configureNavigationBar];
    [self configureSegmentedControl];
    [self configureBarButtonItem];
    
    // Allow user to "Pull-to-Refresh" load in new photos.
    [self addPullToRefreshView];
    
    [self addDismissPopoverGestureToNavigationBar];
}

#pragma mark - Tap Navigation Bar to Dismiss Popover

/* 
 Dismiss popover when user taps on the navigation bar. By default, navigation bar is 
 added as one of popover's passthrough views.
 */
- (void)addDismissPopoverGestureToNavigationBar
{
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissPopover:)];
    tapGestureRecognizer.numberOfTapsRequired = 1;
    tapGestureRecognizer.cancelsTouchesInView = NO;
    [self.navigationController.navigationBar addGestureRecognizer:tapGestureRecognizer];
}

- (void)dismissPopover:(UITapGestureRecognizer *)tapGestureRecognizer
{
    [self.categoryListPopoverController dismissPopoverAnimated:YES];
}

#pragma mark - Customize Views UIAppearance

- (void)configureNavigationBar
{
    [self.navigationController.navigationBar configureFlatNavigationBarWithColor:[UIColor blackColor]];
}

- (void)configureSegmentedControl
{
    // Resize the segmented control here, otherwise it will get squished by the autolayout.
    static const CGFloat kSegmentedControlWidth = 500.0f;
    CGRect currentBounds = self.featureSegmentedControl.bounds;
    self.featureSegmentedControl.bounds = CGRectMake(currentBounds.origin.x,currentBounds.origin.y,
                                                     kSegmentedControlWidth, currentBounds.size.height);
    
    self.featureSegmentedControl.selectedFont = [UIFont systemFontOfSize:20.0f];
    self.featureSegmentedControl.selectedFontColor = [UIColor whiteColor];
    self.featureSegmentedControl.deselectedFont = [UIFont systemFontOfSize:20.0f];
    self.featureSegmentedControl.deselectedFontColor = [UIColor grayColor];
    self.featureSegmentedControl.selectedColor = [UIColor darkGrayColor];
    self.featureSegmentedControl.deselectedColor = [UIColor clearColor];
    self.featureSegmentedControl.dividerColor = [UIColor clearColor];
    self.featureSegmentedControl.cornerRadius = 0.0f;
    
    // Adjust segment widths based on their content widths.
    self.featureSegmentedControl.apportionsSegmentWidthsByContent = YES;
}

- (void)configureBarButtonItem
{
    [self.categoryBarButtonItem configureFlatButtonWithColor:[UIColor alizarinColor]
                                            highlightedColor:[UIColor pomegranateColor]
                                                cornerRadius:3.0f];
    
    NSDictionary *textAttributes = @{UITextAttributeFont: [UIFont systemFontOfSize:16.0f],
                                     UITextAttributeTextColor: [UIColor whiteColor],
                                     UITextAttributeTextShadowColor: [UIColor clearColor],
                                     UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:UIOffsetMake(0.0f, 0.0f)]};
    [self.categoryBarButtonItem setTitleTextAttributes:textAttributes
                                              forState:UIControlStateNormal];
}

- (void)configurePopover
{
    [self.categoryListPopoverController configureFlatPopoverWithBackgroundColor:[UIColor silverColor]
                                                                   cornerRadius:6.0f];
}

#pragma mark - View Rotation Events

/*
 We need to manually forward the view rotation events to TCPhotoModalViewController
 because it is not attached/related to any view controllers (it's view is added to 
 UIWindow). 
 Remember to check if TCPhotoModalViewController's view has been added to a window 
 before forwarding the rotation events.
*/

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (self.photoModalViewController.view.window) {
        [self.photoModalViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    }
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (self.photoModalViewController.view.window) {
        [self.photoModalViewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if (self.photoModalViewController.view.window) {
        [self.photoModalViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    }
}

#pragma mark - Pull to Refresh

- (void)addPullToRefreshView
{
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
    // While photos are still loading, we show a default number of placeholders
    // initially. After photos have finished loading, we will replace these
    // placeholders with actual number of photos.    
    NSInteger photoCount = [self.photoStream photoCount];
    return TCPhotoStreamNoPhotoCount == photoCount ? kPXAPIHelperDefaultResultsPerPage : photoCount;
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
    
    // Make sure we have a photo to display before presenting it on the modal view.
    if (photoCell.photo) {        
        [self.photoModalViewController presentWithWindow:self.view.window
                                                   photo:photoCell.photo
                                                  sender:photoCell];
    }
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
        [self configurePopover];
        
        // Set up ourself as the delegate, so that we know when a category is selected from the list.
        TCCategoryListViewController *categoryListViewController = [segue destinationViewController];
        categoryListViewController.delegate = self;
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
