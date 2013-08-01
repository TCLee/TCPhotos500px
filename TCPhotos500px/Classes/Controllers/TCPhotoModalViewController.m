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

@interface TCPhotoModalViewController ()

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIView *dimView;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIView *textContentView;
@property (weak, nonatomic) IBOutlet UILabel *photoTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *userFullNameLabel;

// Width and Height layout constraints will be adjusted dynamically to best aspect fit the photo.
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *widthLayoutConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heightLayoutConstraint;

// Top and leading layout constraints are used for animation purposes.
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *topLayoutConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *leadingLayoutConstraint;
// Center the content view horizontally and vertically within its superview.
@property (nonatomic, strong) NSLayoutConstraint *horizontalCenterLayoutConstraint;
@property (nonatomic, strong) NSLayoutConstraint *verticalCenterLayoutConstraint;

// Tap anywhere on the photo modal view to dismiss it.
@property (nonatomic, strong, readonly) UITapGestureRecognizer *tapToDismissGestureRecognizer;

// Window -> Root View Controller -> View
// We will match our view's transform, bounds and center to the root view.
@property (nonatomic, weak) UIView *rootView;

// The source view's rect that triggered this modal view controller to be presented.
// We need this rect when we perform the present and dismiss animation.
@property (nonatomic, assign) CGRect senderRect;

@property (nonatomic, strong) TCPhoto *photo;

@end

// Constants for the animation duration.
static NSTimeInterval const kFadeAnimationDuration = 0.5f;
static NSTimeInterval const kResizeAnimationDuration = 0.5f;
static NSTimeInterval const kPresentAnimationDuration = 1.0f;

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
        
        // Resize view to aspect fit photo as rotation changes the view's bounds.
        [self sizeToAspectFitPhotoAnimated:NO];
        
        // We need to re-layout the views, otherwise our views will be out of place.
        [self.view layoutIfNeeded];
    }];
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

- (void)presentWithWindow:(UIWindow *)window photo:(TCPhoto *)photo animated:(BOOL)animated
{    
    self.photo = photo;
    
    // The root view will have the correct transform applied to it by the root view controller.
    // We will use the same transform for our view, so that its orientation is correct.
    self.rootView = window.rootViewController.view;
    [self synchronizeWithRootView];
    
    // Allow user to tap anywhere to dismiss the modal view.
    [self.view addGestureRecognizer:self.tapToDismissGestureRecognizer];    
    
    // Add our view as a subview of UIWindow so that it will be above all the
    // other views.
    [window addSubview:self.view];
    
    // We re-use the same view for all photos, so we need to reset its contents.
    [self resetContents];
    
    // Perform a simple fade in animation, if requested.
    if (animated) {
        self.view.alpha = 0.0f;
        [UIView animateWithDuration:kFadeAnimationDuration animations:^{
            self.view.alpha = 1.0f;
        }];
    }
    
    // Load the photo asynchronously and display it on the view.
    [self displayPhoto];
}

- (void)presentWithWindow:(UIWindow *)window photo:(TCPhoto *)photo sender:(UIView *)sender
{
    self.photo = photo;
    
    // We must synchronize our view's transform, bounds and center with the root view
    // controller's view. This is because our view is directly added to a window.
    self.rootView = window.rootViewController.view;
    [self synchronizeWithRootView];
    
    // Add our view as window's subview, so that it sits above all other views.
    [window addSubview:self.view];
    
    // Convert the sender's rectangle to our view's coordinate system.
    self.senderRect = [sender convertRect:sender.bounds toView:self.view];
    
    // Perform the present modal view controller animation.
    [self performPresentAnimation];
}

- (void)dismiss
{
    [self setDismissAnimationEndLayoutConstraints];
    
    [UIView animateWithDuration:kPresentAnimationDuration animations:^{
        // Fade out the dim view and labels container view.
        self.dimView.alpha = 0.0f;
        self.textContentView.alpha = 0.0f;
        
        // Tell the view to perform layout, so that constraints changes will be animated.
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        [self.view removeFromSuperview];
    }];
}

- (void)handleTapToDismiss:(UITapGestureRecognizer *)sender
{
    if (UIGestureRecognizerStateRecognized == sender.state) {
        [self.view removeGestureRecognizer:sender];
        [self dismiss];
    }
}

#pragma mark - Present and Dismiss Animations

/*
 Create and returns a horizontal or vertical center layout constraint.
 */
- (NSLayoutConstraint *)centerConstraintWithAttribute:(NSLayoutAttribute)attribute
{
    return [NSLayoutConstraint constraintWithItem:self.contentView
                                        attribute:attribute
                                        relatedBy:NSLayoutRelationEqual
                                           toItem:self.contentView.superview
                                        attribute:attribute
                                       multiplier:1.0f
                                         constant:0.0f];
}

/*
 Start layout constraints for the present animation.
 */
- (void)setPresentAnimationStartLayoutConstraints
{
    // Use the sender's rect to determine the start point and size for the content view.
    self.leadingLayoutConstraint.constant = self.senderRect.origin.x;
    self.topLayoutConstraint.constant = self.senderRect.origin.y;
    self.widthLayoutConstraint.constant = self.senderRect.size.width;
    self.heightLayoutConstraint.constant = self.senderRect.size.height;
}

/*
 End layout constraints for the present animation.
 */
- (void)setPresentAnimationEndLayoutConstraints
{
    if (!self.horizontalCenterLayoutConstraint) {
        self.horizontalCenterLayoutConstraint = [self centerConstraintWithAttribute:NSLayoutAttributeCenterX];
    }
    if (!self.verticalCenterLayoutConstraint) {
        self.verticalCenterLayoutConstraint = [self centerConstraintWithAttribute:NSLayoutAttributeCenterY];
    }
    
    self.widthLayoutConstraint.constant = 500.0f;
    self.heightLayoutConstraint.constant = 500.0f;
    
    [self.view removeConstraint:self.topLayoutConstraint];
    [self.view removeConstraint:self.leadingLayoutConstraint];
    [self.view addConstraint:self.verticalCenterLayoutConstraint];
    [self.view addConstraint:self.horizontalCenterLayoutConstraint];
}

/*
 Start layout constraints for the dismiss animation is the same as end layout 
 constraints for the present animation. So, there's nothing to do here.
 */

/*
 End layout constraints for the dismiss animation.
 */
- (void)setDismissAnimationEndLayoutConstraints
{
    // The dismiss animation is the reverse of the present animation.
    // So the start of the present animation is the end of the dismiss animation.
    [self setPresentAnimationStartLayoutConstraints];
    
    [self.view removeConstraint:self.horizontalCenterLayoutConstraint];
    [self.view removeConstraint:self.verticalCenterLayoutConstraint];
    [self.view addConstraint:self.topLayoutConstraint];
    [self.view addConstraint:self.leadingLayoutConstraint];
}

/*
 Present modal view controller animation.
 */
- (void)performPresentAnimation
{
    // Start animation layout constraints.
    [self setPresentAnimationStartLayoutConstraints];
    
    // Tell the view to perform layout immediately as our constraints have changed.
    [self.view layoutIfNeeded];
    
    // End animation layout constraints.
    [self setPresentAnimationEndLayoutConstraints];
    
    // Dim view and the labels container view will have a fade-in animation.
    self.dimView.alpha = 0.0f;
    self.textContentView.alpha = 0.0f;
    
    // Perform the animation.    
    [UIView animateWithDuration:kPresentAnimationDuration animations:^{
        self.dimView.alpha = 0.6f;
        self.textContentView.alpha = 1.0f;
        
        // Tell the view to perform layout, so that constraints changes will be animated.
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        // Add tap to dismiss gesture only after the animation is completed.
        // Otherwise, user can dismiss the view in the middle of an animation.
        [self.view addGestureRecognizer:self.tapToDismissGestureRecognizer];
    }];
}

#pragma mark - Display Photo Details on View

// Reset the view's contents before displaying a new photo.
- (void)resetContents
{
    [self setLayoutConstraintsWithSize:CGSizeMake(500.0f, 500.0f)];
    
    self.imageView.image = nil;
    self.photoTitleLabel.text = @"";
    self.userFullNameLabel.text = @"";
}

// Load the photo asynchronously and display it on the view.
- (void)displayPhoto
{
    UIImage *photo = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:[self.photo.photoURL absoluteString]];

    // If photo is in memory cache, we can just display the image immediately.
    // Else we will have to load the photo in asynchronously.
    if (photo) {
        self.imageView.image = photo;
        [self sizeToAspectFitPhotoAnimated:YES];
    } else {
        [self loadPhoto];
    }
    
    self.photoTitleLabel.text = self.photo.title;
    self.userFullNameLabel.text = self.photo.userFullName;
}

// Load the photo asynchronously and display it on the image view.
- (void)loadPhoto
{
    [MBProgressHUD showHUDAddedTo:self.imageView animated:YES];
    
    // We'll display the low resolution thumbnail as a placeholder while we
    // load the larger size photo in the background.
    UIImage *thumbnail = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:[self.photo.thumbnailURL absoluteString]];
    
    // Load image asynchronously from network or disk cache.
    [self.imageView setImageWithURL:self.photo.photoURL placeholderImage:thumbnail options:0 completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        if (image) {
            [MBProgressHUD hideHUDForView:self.imageView animated:YES];
            [self sizeToAspectFitPhotoAnimated:YES];
        } else if (error) {
            NSLog(@"[SDWebImage Error] - %@", [error localizedDescription]);
        }
    }];
}

#pragma mark - Resize to Aspect Fit Photo within Screen

/*
 Resizes the view to aspect fit the photo.
 */
- (void)sizeToAspectFitPhotoAnimated:(BOOL)animated
{
    // If there is no image, there's no need to resize view.
    if (!self.imageView.image) {
        return;
    }
    
    // Original photo size before any scaling.
    CGSize photoSize = self.imageView.image.size;
    
    // Calculate scale factor required to aspect fit the photo.
    CGFloat scaleFactor = [self scaleFactorToAspectFitPhotoWithSize:photoSize];
    
    // Create the view's new bounds from the scaled size.
    CGSize scaledPhotoSize = CGSizeMake(floorf(photoSize.width * scaleFactor),
                                        floorf(photoSize.height * scaleFactor));
    
    // Animate the layout constraints changing, if animation is wanted.
    if (animated) {
        // Animating NSLayoutConstraints:
        // http://stackoverflow.com/a/12926646
        // http://stackoverflow.com/q/12622424
        
        [self setLayoutConstraintsWithSize:scaledPhotoSize];
        [UIView animateWithDuration:kResizeAnimationDuration animations:^{
            [self.view layoutIfNeeded];
        }];
    } else {
        [self setLayoutConstraintsWithSize:scaledPhotoSize];
    }
}

// The padding from the view's edge to the window's edge.
static CGFloat const kViewToWindowPadding = 60.0f;

/*
 Calculate the scale factor to resize view so that it aspect fits the
 photo within the window bounds (with some margin spacing).
 */
- (CGFloat)scaleFactorToAspectFitPhotoWithSize:(CGSize)photoSize
{
    // Use the root view's bounds so that it takes into account the
    // device orientation.
    CGSize viewSize = self.rootView.bounds.size;
    
    // Include a padding space, so that scaled view will not be too close to
    // the window's edge.
    CGSize photoWithPaddingSize = CGSizeMake(photoSize.width + kViewToWindowPadding,
                                             photoSize.height + kViewToWindowPadding);
    
    // Scale factor to fit photo's width.
    CGFloat widthScaleFactor = 1.0f;
    if (photoWithPaddingSize.width > viewSize.width) {
        widthScaleFactor = viewSize.width / photoWithPaddingSize.width;
    }

    // Scale factor to fit photo's height.
    CGFloat heightScaleFactor = 1.0f;
    if (photoWithPaddingSize.height > viewSize.height) {
        heightScaleFactor = viewSize.height / photoWithPaddingSize.height;
    }
    
    // Return the scale factor that will be needed to fit both photo's width and height.
    return fminf(widthScaleFactor, heightScaleFactor);
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

//- (void)presentWithWindow:(UIWindow *)window photo:(TCPhoto *)photo senderRect:(CGRect)senderRect
//{
//    // Add our view as window's subview.
//    self.rootView = window.rootViewController.view;
//    [self synchronizeWithRootView];
//    [window addSubview:self.view];
//
//    // Display thumbnail on image view as a placeholder.
//    UIImage *thumbnail = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:[photo.thumbnailURL absoluteString]];
//    self.imageView.image = thumbnail;
//
//    // Create the top and left margin constraints to match the sender's rect.
//    // This will make it look like the photo is expanding from the thumbnail.
//    NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:self.contentView
//                                                                     attribute:NSLayoutAttributeTop
//                                                                     relatedBy:NSLayoutRelationEqual
//                                                                        toItem:self.view
//                                                                     attribute:NSLayoutAttributeTop
//                                                                    multiplier:1.0f
//                                                                      constant:senderRect.origin.y];
//    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:self.contentView
//                                                                         attribute:NSLayoutAttributeLeading
//                                                                         relatedBy:NSLayoutRelationEqual
//                                                                            toItem:self.view
//                                                                         attribute:NSLayoutAttributeLeading
//                                                                        multiplier:1.0f
//                                                                          constant:senderRect.origin.x];
//
//    // Remove the end center constraints and replace with the start top and left
//    // constraints for the animation.
//    [self.view removeConstraint:self.horizontalCenterLayoutConstraint];
//    [self.view removeConstraint:self.verticalCenterLayoutConstraint];
//    [self.view addConstraint:topConstraint];
//    [self.view addConstraint:leftConstraint];
//
//    // Start size to animate from.
//    self.widthLayoutConstraint.constant = senderRect.size.width;
//    self.heightLayoutConstraint.constant = senderRect.size.height;
//
//    // Tell the view to perform the necessary layout as our constraints have changed.
//    [self.view setNeedsUpdateConstraints];
//    [self.view layoutIfNeeded];
//
//    // Dim view will have a fade-in animation.
//    self.dimView.alpha = 0.0f;
//    self.textContentView.alpha = 0.0f;
//
//    // Animate to the end constraints.
//    [UIView animateWithDuration:1.0f animations:^{
//        self.dimView.alpha = 0.6f;
//        self.textContentView.alpha = 1.0f;
//
//        [self.view removeConstraint:topConstraint];
//        [self.view removeConstraint:leftConstraint];
//        [self.view addConstraint:self.verticalCenterLayoutConstraint];
//        [self.view addConstraint:self.horizontalCenterLayoutConstraint];
//
//        self.widthLayoutConstraint.constant = 500.0f;
//        self.heightLayoutConstraint.constant = 500.0f;
//
//        [self.view setNeedsUpdateConstraints];
//        [self.view layoutIfNeeded];
//    } completion:^(BOOL finished) {
//        // Add tap to dismiss gesture only after the animation is completed.
//        [self.view addGestureRecognizer:self.tapToDismissGestureRecognizer];
//    }];
//}


@end
