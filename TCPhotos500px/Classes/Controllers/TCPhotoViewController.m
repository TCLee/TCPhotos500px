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
#import "SVProgressHUD.h"

#import <QuartzCore/QuartzCore.h>

@interface TCPhotoViewController ()

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *fullNameLabel;

@end

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

// When the view is rotated, we also have to make changes to our modal view's bounds.
// Otherwise, the image will be clipped at the screen edges.
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
#warning Place image and thumbnail in Photo model for easy retrieval.
    // Get the downloaded image from the cache.
    SDImageCache *imageCache = [SDImageCache sharedImageCache];
    UIImage *image = [imageCache imageFromDiskCacheForKey:[self.photo.imageURL absoluteString]];
    
    [self sizeViewToFitImage:image];
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
        
        [self configureView];
    }
}

// Updates the view with the photo model's data.
- (void)configureView
{
    // Get the thumbnail from the cache.
    SDImageCache *imageCache = [SDImageCache sharedImageCache];
    UIImage *thumbnail = [imageCache imageFromDiskCacheForKey:[self.photo.thumbnailURL absoluteString]];
    
#warning Use MBProgressHUD instead. It's more flexible.
    // Show progress hud over photo while loading.
    [SVProgressHUD show];
    
    [self.imageView setImageWithURL:self.photo.imageURL placeholderImage:thumbnail options:0 completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        [SVProgressHUD dismiss];

        [self sizeViewToFitImage:image];
    }];
    
    self.titleLabel.text = self.photo.title;
    self.fullNameLabel.text = self.photo.userFullName;
}

//TODO: Should include some margin from the edge of the screen.
- (void)sizeViewToFitImage:(UIImage *)image
{
    if (!image) { return; }
    
    // Use the root view's bounds so that it takes into account the
    // device orientation (portrait or landscape).
    CGSize windowSize = self.view.window.rootViewController.view.bounds.size;
    CGSize imageSize = image.size;        
    
    NSLog(@"Window Size = %@", NSStringFromCGSize(windowSize));
    NSLog(@"Image Size = %@", NSStringFromCGSize(imageSize));
    
    CGFloat scaleFactor = 1.0f;    
    if (imageSize.width > windowSize.width) {
        scaleFactor = windowSize.width / imageSize.width;
    } else if (imageSize.height > windowSize.height) {
        scaleFactor = windowSize.height / imageSize.height;
    }    
    
    CGSize modalViewSize = CGSizeMake(floorf(imageSize.width * scaleFactor), floorf(imageSize.height * scaleFactor));
    NSLog(@"Modal Size = %@", NSStringFromCGSize(modalViewSize));
    
    // Animate the bounds changing.
    [UIView animateWithDuration:0.6f animations:^{
        self.view.superview.bounds = CGRectMake(0, 0, modalViewSize.width, modalViewSize.height);
    }];
}

@end
