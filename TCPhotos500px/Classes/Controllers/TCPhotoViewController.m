//
//  TCPhotoViewController.m
//  TCPhotos500px
//
//  Created by Lee Tze Cheun on 7/22/13.
//  Copyright (c) 2013 Lee Tze Cheun. All rights reserved.
//

#import "TCPhotoViewController.h"
#import "TCPhoto.h"

#import "UIImageView+WebCache.h"
#import "MBProgressHUD.h"

#import <QuartzCore/QuartzCore.h>

@interface TCPhotoViewController ()

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *fullNameLabel;

// The size of the actual photo to display on the image view.
@property (nonatomic, assign) CGSize photoSize;

@end

#pragma mark -

@implementation TCPhotoViewController

#pragma mark - View Life Cycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
        
    // Remove rounded corner from the modal view.
    self.view.layer.cornerRadius = 0.0f;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Set the initial size of the modal view.
    // The bounds of the modal's superview determines the size of our content view
    // presented on the screen. Also set it in viewDidAppear, otherwise it will not take effect.
    // Reference: http://stackoverflow.com/a/4271364
    self.view.superview.bounds = CGRectMake(0.0f, 0.0f, 500.0f, 500.0f);
    
    // Add tap gesture recognizer in viewDidAppear because our view is now added
    // to the window.
    [self addTapToDismissGesture];
    
    // Load the image asynchronously and display it on this view.
    [self configureView];
}

#pragma mark - View Rotation

// When the view is rotated, we also have to make changes to our view's bounds.
// Otherwise, the photo will be clipped at the screen edges.
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
        
    [self sizeViewToAspectFitPhotoAnimated:YES];
}

#pragma mark - Dismiss Modal View on Tap Gesture

// StackOverflow: Tap to Dismiss http://stackoverflow.com/a/6180584
- (void)addTapToDismissGesture
{
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapToDismiss:)];
    tapGestureRecognizer.numberOfTapsRequired = 1;
    
    // So the user can still interact with controls in the modal view.
    tapGestureRecognizer.cancelsTouchesInView = NO;
    
    // Add gesture recognizer to window instead of the view to detect taps outside
    // the modal view.
    [self.view.window addGestureRecognizer:tapGestureRecognizer];
}

- (void)handleTapToDismiss:(UITapGestureRecognizer *)sender
{
    if (UIGestureRecognizerStateRecognized == sender.state) {
        [self.view.window removeGestureRecognizer:sender];
        
        // Automatically forwards message to the presenting view controller (parent)
        // to dismiss this presented view controller (child).
        [self dismissViewControllerAnimated:NO completion:NULL];
    }
}

#pragma mark - Photo Model

- (void)setPhoto:(TCPhoto *)newPhoto
{
    if (_photo != newPhoto) {
        _photo = newPhoto;
        
//        [self configureView];
    }
}

// Updates the view with the photo model's data.
- (void)configureView
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
            self.view.superview.bounds = viewBounds;
        }];
    } else {
        self.view.superview.bounds = viewBounds;
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

@end
