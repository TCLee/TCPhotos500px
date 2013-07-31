//
//  TCPhotoModalViewController.m
//  TCPhotos500px
//
//  Created by Lee Tze Cheun on 7/29/13.
//  Copyright (c) 2013 Lee Tze Cheun. All rights reserved.
//

#import "TCPhotoModalViewController.h"
#import "TCPhoto.h"

#import "MBProgressHUD.h"

#import <QuartzCore/QuartzCore.h>

@interface TCPhotoModalViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *photoTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *userFullNameLabel;

// Width and Height layout constraints will be adjusted dynamically to best aspect
// fit the photo.
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *widthLayoutConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heightLayoutConstraint;

// Tap anywhere on the photo modal view to dismiss it.
@property (nonatomic, strong, readonly) UITapGestureRecognizer *tapToDismissGestureRecognizer;

// Window -> Root View Controller -> View
// 
@property (nonatomic, weak) UIView *rootView;

@property (nonatomic, strong) TCPhoto *photo;

// The size of the photo to display on the UIImageView.
@property (nonatomic, assign) CGSize photoSize;

@end

@implementation TCPhotoModalViewController

@synthesize tapToDismissGestureRecognizer = _tapToDismissGestureRecognizer;

#pragma mark - Lazy Properties

// Tap to Dismiss Modal View - http://stackoverflow.com/a/6180584
- (UITapGestureRecognizer *)tapToDismissGestureRecognizer
{
    if (!_tapToDismissGestureRecognizer) {
        _tapToDismissGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapToDismiss:)];
        _tapToDismissGestureRecognizer.numberOfTapsRequired = 1;
        
        // So the user can still interact with controls in the view.
        _tapToDismissGestureRecognizer.cancelsTouchesInView = NO;
    }
    return _tapToDismissGestureRecognizer;
}

#pragma mark - View Rotation Events

// When the root view controller's view runs its rotation animation, we will also
// match its rotation animation for a smoother transition.
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [UIView animateWithDuration:duration animations:^{
        [self synchronizeWithRootView];        
    }];
    
    // TODO: Pass in a duration parameter to match rotation duration.
    // Resize view to fit photo again as rotation changes the view's bounds.
    [self sizeViewToAspectFitPhotoAnimated:YES];
}

#pragma mark - Synchronize Transform, Bounds and Center with Root View

/*
 Rotate a UIView that is added to a UIWindow:
 [Good] Modifies transform and frame - http://stackoverflow.com/a/4960988
 [Better] Modifies transform and bounds/center - http://stackoverflow.com/a/14855914
 */

// We need to call this method to ensure that our view is always in sync with the
// root view controller's view. This is because our view is added to a UIWindow.
- (void)synchronizeWithRootView
{
    self.view.transform = self.rootView.transform;
    
    // Transform invalidates the frame, so use bounds and center instead.
    self.view.bounds = self.rootView.bounds;
    self.view.center = self.rootView.center;
}

#pragma mark - Present and Dismiss Modal View Controller

- (void)presentViewWithWindow:(UIWindow *)window photo:(TCPhoto *)photo animated:(BOOL)animated
{    
    self.photo = photo;
    
    // The root view will have the correct transform applied to it by the root view controller.
    // We will use the same transform for the modal view, so that its orientation is correct.
    self.rootView = window.rootViewController.view;
    [self synchronizeWithRootView];
    
    // Allow user to tap anywhere to dismiss the modal view.
    [self.view addGestureRecognizer:self.tapToDismissGestureRecognizer];    
    
    // Add our view as a subview of UIWindow so that it will be above all the other views.
    [window addSubview:self.view];
    
    // We re-use the same view for all photos, so we need to reset its contents.
    [self resetContents];
    
    // Perform a simple fade in animation, if requested.
    if (animated) {
        self.view.alpha = 0.0f;
        [UIView animateWithDuration:0.5f animations:^{
            self.view.alpha = 1.0f;
        }];
    }
    
    // Load the photo asynchronously and display it on the view.
    [self displayPhoto];
}

- (void)dismissAnimated:(BOOL)animated
{
    if (animated) {
        self.view.alpha = 1.0f;
        [UIView animateWithDuration:0.5f animations:^{
            self.view.alpha = 0.0f;
        } completion:^(BOOL finished) {
            [self.view removeFromSuperview];
        }];
    } else {
        [self.view removeFromSuperview];    
    }
}

- (void)handleTapToDismiss:(UITapGestureRecognizer *)sender
{
    if (UIGestureRecognizerStateRecognized == sender.state) {
        [self.view removeGestureRecognizer:sender];
        [self dismissAnimated:YES];
    }
}

#pragma mark - Display Photo on View

// Reset the view's contents for each photo to display.
// We need to reset contents because we reuse the same view.
- (void)resetContents
{
    [self setLayoutConstraintsWithSize:CGSizeMake(500.0f, 500.0f)];    
    self.imageView.image = nil;
    self.photoTitleLabel.text = @"";
    self.userFullNameLabel.text = @"";
}

- (void)displayPhoto
{
    // Get the thumbnail from the memory (if available) or disk cache.
    // We'll display the low resolution thumbnail while we load the larger size
    // photo in the background.
    SDImageCache *imageCache = [SDImageCache sharedImageCache];
    UIImage *thumbnail = [imageCache imageFromDiskCacheForKey:[self.photo.thumbnailURL absoluteString]];
    
    // If photo is in memory cache, we can just display the image immediately.
    // So, there's no need to show a progress HUD. Otherwise, the progress HUD will
    // flash on screen and disappear.
    UIImage *photo = [imageCache imageFromMemoryCacheForKey:[self.photo.photoURL absoluteString]];
    
    if (photo) {
        self.imageView.image = photo;
        self.photoSize = photo.size;
        [self sizeViewToAspectFitPhotoAnimated:YES];
    } else {
        [MBProgressHUD showHUDAddedTo:self.imageView animated:YES];
        
        // Load image asynchronously from network or disk cache.
        [self.imageView setImageWithURL:self.photo.photoURL placeholderImage:thumbnail options:0 completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
            [MBProgressHUD hideHUDForView:self.imageView animated:YES];
            self.photoSize = image.size;
            [self sizeViewToAspectFitPhotoAnimated:YES];
        }];
    }
    
    self.photoTitleLabel.text = self.photo.title;
    self.userFullNameLabel.text = self.photo.userFullName;
}

#pragma mark - Resize View to Aspect Fit Photo

/*
 Resizes this view to aspect fit the photo without exceeding the window's bounds.
 */
- (void)sizeViewToAspectFitPhotoAnimated:(BOOL)animated
{
    // Invalid photo size. Do nothing.
    if (0 == self.photoSize.width || 0 == self.photoSize.height) {
        return;
    }
    
    // Calculate scale factor required to aspect fit the photo.
    CGFloat scaleFactor = [self scaleFactorForViewToAspectFitPhoto];
    
    // Create the view's new bounds from the scaled size.
    CGSize scaledPhotoSize = CGSizeMake(floorf(self.photoSize.width * scaleFactor),
                                        floorf(self.photoSize.height * scaleFactor));
    
//    NSLog(@"Scaled Photo Size = %@", NSStringFromCGSize(scaledPhotoSize));
    
    // Animate the layout constraints changing, if animation is wanted.
    if (animated) {
        // Animating NSLayoutConstraints - http://stackoverflow.com/a/12926646
        [self setLayoutConstraintsWithSize:scaledPhotoSize];
        [UIView animateWithDuration:0.5f animations:^{
            [self.view layoutIfNeeded];
        }];
    } else {
        [self setLayoutConstraintsWithSize:scaledPhotoSize];
    }
}

/*
 Set the content view's width and height layout constraints to the given size.
 */
- (void)setLayoutConstraintsWithSize:(CGSize)size
{
    self.widthLayoutConstraint.constant = size.width;
    self.heightLayoutConstraint.constant = size.height;
   
    // Let the view know that we have modified the constraints,
    // so that it can update any dependent constraints.
    [self.view setNeedsUpdateConstraints];
}

// The padding from the view's edge to the window's edge.
static CGFloat const kViewToWindowPadding = 60.0f;

/*
 Calculate the scale factor to resize view so that it aspect fits the
 photo within the window bounds (with some margin spacing).
 */
- (CGFloat)scaleFactorForViewToAspectFitPhoto
{
    // Use the root view's bounds so that it takes into account the
    // device orientation (portrait or landscape).
    CGSize windowSize = self.rootView.bounds.size;
    
//    NSLog(@"Window Size = %@", NSStringFromCGSize(windowSize));
//    NSLog(@"Photo Size = %@", NSStringFromCGSize(self.photoSize));
    
    // Include a padding space, so that scaled view will not be too close to
    // the window's edge.
    CGSize photoWithPaddingSize = CGSizeMake(self.photoSize.width + kViewToWindowPadding,
                                             self.photoSize.height + kViewToWindowPadding);
    CGFloat scaleFactor = 1.0f;
    if (photoWithPaddingSize.width > windowSize.width) {
        scaleFactor = windowSize.width / photoWithPaddingSize.width;
    } else if (photoWithPaddingSize.height > windowSize.height) {
        scaleFactor = windowSize.height / photoWithPaddingSize.height;
    }
    
    return scaleFactor;
}

@end
