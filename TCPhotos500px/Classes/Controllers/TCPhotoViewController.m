//
//  TCPhotoViewController.m
//  TCPhotos500px
//
//  Created by Lee Tze Cheun on 7/22/13.
//  Copyright (c) 2013 Lee Tze Cheun. All rights reserved.
//

#import "TCPhotoViewController.h"
#import "TCPhoto.h"
#import "TCDimmingView.h"

#import "UIImageView+WebCache.h"
#import "MBProgressHUD.h"

#import <QuartzCore/QuartzCore.h>

@interface TCPhotoViewController ()

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *fullNameLabel;

@property (nonatomic, strong, readonly) UITapGestureRecognizer *tapToDismissGestureRecognizer;
@property (nonatomic, strong, readonly) TCDimmingView *dimView;

// Window -> Root View Controller -> View
@property (nonatomic, weak) UIView *rootView;

@property (nonatomic, strong) TCPhoto *photo;

// The size of the photo to display on the image view.
@property (nonatomic, assign) CGSize photoSize;

@end

#pragma mark -

@implementation TCPhotoViewController

@synthesize dimView = _dimView;
@synthesize tapToDismissGestureRecognizer = _tapToDismissGestureRecognizer;

#pragma mark - Lazy Properties

- (TCDimmingView *)dimView
{
    if (!_dimView) {
        _dimView = [[TCDimmingView alloc] init];
    }
    return _dimView;
}

- (UITapGestureRecognizer *)tapToDismissGestureRecognizer
{
    if (!_tapToDismissGestureRecognizer) {
        _tapToDismissGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapToDismiss:)];
        _tapToDismissGestureRecognizer.numberOfTapsRequired = 1;
        
        // So the user can still interact with controls in the modal view.
        _tapToDismissGestureRecognizer.cancelsTouchesInView = NO;
    }
    return _tapToDismissGestureRecognizer;
}

#pragma mark - Present and Dismiss View Controller

- (void)presentWithRootViewController:(UIViewController *)rootViewController photo:(TCPhoto *)photo animated:(BOOL)animated;
{
    // The root view will have the correct transform applied to it by the root view controller.
    // We will use the same transform for this view, so that our orientation is correct.
    self.rootView = rootViewController.view;
    
    self.photo = photo;
    
    UIWindow *window = self.rootView.window;
    
    // Add the views as subviews of UIWindow.
    [self addModalViewsToWindow:window];
    
    // Add gesture recognizer to window instead of the view to detect taps outside
    // the modal view.
    [window addGestureRecognizer:self.tapToDismissGestureRecognizer];
    
    // Load the photo asynchronously and display it on the view.
    [self displayPhoto];
}

- (void)dismissAnimated:(BOOL)animated
{
    [self.view removeFromSuperview];
    [self.dimView removeFromSuperviewAnimated:animated];
}

#pragma mark - View Rotation Events

// When the root view controller's view runs its rotation animation, we will also
// match its rotation animation for a smoother transition.
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [UIView animateWithDuration:duration animations:^{
        self.view.transform = self.rootView.transform;
    }];
}

// When the view is rotated, we also have to make changes to our view's bounds.
// Otherwise, the photo will be clipped at the screen edges.
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{    
    [self sizeViewToAspectFitPhotoAnimated:YES];
}

#pragma mark - Add Modal Views to UIWindow

- (void)addModalViewsToWindow:(UIWindow *)window
{
    // Add the dimming view to the window, so that it covers every other view below it.
    // This will also give us the modal effect by disabling all the views below the dimming view.
    [self.dimView addToSuperview:window animated:YES];
    
    // In this case, we want to explicitly set the frame and not use auto layout
    // constraints. This is because our view size is determined by the photo size.
    self.view.center = self.rootView.center;
    self.view.transform = self.rootView.transform;
    self.view.bounds = CGRectMake(0, 0, 400.0f, 400.0f);
    
    // Add the photo view to the window and on top of the dimming view.
    [window addSubview:self.view];
}

#pragma mark - Dismiss Modal View on Tap Gesture

// StackOverflow - Tap to Dismiss: http://stackoverflow.com/a/6180584
- (void)handleTapToDismiss:(UITapGestureRecognizer *)sender
{
    if (UIGestureRecognizerStateRecognized == sender.state) {
        [self.view.window removeGestureRecognizer:sender];
        [self dismissAnimated:YES];
    }
}

#pragma mark - Display Photo on View

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
    
    self.titleLabel.text = self.photo.title;
    self.fullNameLabel.text = self.photo.userFullName;
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
    CGSize viewSize = CGSizeMake(floorf(self.photoSize.width * scaleFactor),
                                 floorf(self.photoSize.height * scaleFactor));
    CGRect viewBounds = CGRectMake(0, 0, viewSize.width, viewSize.height);
    
    NSLog(@"View Size = %@", NSStringFromCGSize(viewSize));
    
    // Animate the bounds changing, if animation is wanted.
    if (animated) {
        [UIView animateWithDuration:0.6f animations:^{
            self.view.bounds = viewBounds;
        }];
    } else {
        self.view.bounds = viewBounds;
    }
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
    CGSize windowSize = self.view.window.rootViewController.view.bounds.size;
    
    NSLog(@"Window Size = %@", NSStringFromCGSize(windowSize));
    NSLog(@"Photo Size = %@", NSStringFromCGSize(self.photoSize));
    
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

#pragma mark - Auto Layout Constraints

@end
