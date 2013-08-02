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

// The source view that triggered this modal view controller to be presented.
// We need this view's rect when we perform the present and dismiss animation.
// It is possible that the view's rect will change during rotation, so we will always
// have to calculate the most up-to-date rect.
@property (nonatomic, weak) UIView *sender;

@property (nonatomic, strong) TCPhoto *photo;

@end

// Constants for the animation duration.
static NSTimeInterval const kFadeAnimationDuration = 0.5f;
static NSTimeInterval const kResizeAnimationDuration = 0.5f;
static NSTimeInterval const kPresentAndDismissAnimationDuration = 1.0f;

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

- (void)presentWithWindow:(UIWindow *)window photo:(TCPhoto *)photo sender:(UIView *)sender
{    
    // We must synchronize our view's transform, bounds and center with the root view
    // controller's view. This is because our view is directly added to a window.
    self.rootView = window.rootViewController.view;
    [self synchronizeWithRootView];
    
    // Add our view as window's subview, so that it sits above all other views.
    [window addSubview:self.view];
    
    // Initially, display the thumbnail of the photo.
    self.photo = photo;
    [self displayThumbnail];
    
    // We need a reference to the sender to animate from and to. The sender's frame
    // can change when the view is rotated, so we cannot cache the sender's frame only.
    self.sender = sender;
    
    // Perform the present modal view controller animation.
    [self performPresentAnimation];
}

- (void)dismiss
{
    // End layout constraints for the dismiss animation.
    [self setDismissAnimationEndLayoutConstraints];    
        
    [UIView animateWithDuration:kPresentAndDismissAnimationDuration animations:^{
        // Fade out the dim view and the content view.
        self.dimView.alpha = 0.0f;        
        self.contentView.alpha = 0.0f;
        
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
    
    // Dimming view and content view will have a fade-in animation.
    self.dimView.alpha = 0.0f;
    self.contentView.alpha = 0.0f;
    
    // Perform the animation.
    [UIView animateWithDuration:kPresentAndDismissAnimationDuration animations:^{
        self.dimView.alpha = 0.6f;
        self.contentView.alpha = 1.0f;
        
        // Tell the view to perform layout, so that constraints changes will be animated.
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        // Add tap to dismiss gesture only after the animation is completed.
        // Otherwise, user can dismiss the view in the middle of an animation.
        [self.view addGestureRecognizer:self.tapToDismissGestureRecognizer];
        
        // First animation completed. Chain the second animation to
        // load and display photo.
        [self displayPhoto];
    }];
}

/*
 Returns the sender's rect in our view's coordinate system.
 */
- (CGRect)senderRectInView
{
    NSParameterAssert(self.sender.window == self.view.window);
    
    return [self.sender convertRect:self.sender.bounds toView:self.view];
}

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
    CGRect senderRect = [self senderRectInView];
    
    // NSInternalInconsistencyException, Reason: "Autolayout doesn't support crossing rotational bounds transforms with edge layout constraints, such as right, left, top, bottom..."
    // http://stackoverflow.com/q/15139909
    
//    UIView *contentView = self.contentView;
//    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(contentView);
//    NSArray *horizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-%.2f-[contentView]", senderRect.origin.x]
//                                                                             options:0
//                                                                             metrics:nil
//                                                                               views:viewsDictionary];
//    NSArray *verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-%.2f-[contentView]", senderRect.origin.y]
//                                                                           options:0
//                                                                           metrics:nil
//                                                                             views:viewsDictionary];
//    [self.view removeConstraint:self.topLayoutConstraint];
//    [self.view removeConstraint:self.leadingLayoutConstraint];
//    [self.view removeConstraint:self.horizontalCenterLayoutConstraint];
//    [self.view removeConstraint:self.verticalCenterLayoutConstraint];
//    
//    self.leadingLayoutConstraint = horizontalConstraints[0];
//    self.topLayoutConstraint = verticalConstraints[0];
//    [self.view addConstraint:self.topLayoutConstraint];
//    [self.view addConstraint:self.leadingLayoutConstraint];
    
    self.leadingLayoutConstraint.constant = senderRect.origin.x;
    self.topLayoutConstraint.constant = senderRect.origin.y;
    self.widthLayoutConstraint.constant = senderRect.size.width;
    self.heightLayoutConstraint.constant = senderRect.size.height;
}

/*
 End layout constraints for the present animation.
 */
- (void)setPresentAnimationEndLayoutConstraints
{
    // Only need to create the center layout constraints once.
    if (!self.horizontalCenterLayoutConstraint) {
        self.horizontalCenterLayoutConstraint = [self centerConstraintWithAttribute:NSLayoutAttributeCenterX];
    }
    if (!self.verticalCenterLayoutConstraint) {
        self.verticalCenterLayoutConstraint = [self centerConstraintWithAttribute:NSLayoutAttributeCenterY];
    }
    
    self.widthLayoutConstraint.constant = 450.0f;
    self.heightLayoutConstraint.constant = 450.0f;
        
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

#pragma mark - Display Photo Details on View

// Display the photo's thumbnail on the image view.
- (void)displayThumbnail
{
    // Photo title and user's full name.
    self.photoTitleLabel.text = self.photo.title;
    self.userFullNameLabel.text = self.photo.userFullName;

    UIImage *thumbnail = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:[self.photo.thumbnailURL absoluteString]];
    self.imageView.image = thumbnail;
}

// Display the photo model's contents on the view.
- (void)displayPhoto
{
    UIImage *photoImage = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:[self.photo.photoURL absoluteString]];
    
    // If photo is in memory cache, we can just display the image immediately.
    // Else we will have to load the photo in asynchronously.
    if (photoImage) {
        self.imageView.image = photoImage;
        [self sizeToAspectFitPhotoAnimated:YES];
    } else {
        [self loadPhoto];
    }    
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
        
        self.widthLayoutConstraint.constant = scaledPhotoSize.width;
        self.heightLayoutConstraint.constant = scaledPhotoSize.height;
        [UIView animateWithDuration:kResizeAnimationDuration animations:^{
            [self.view layoutIfNeeded];            
        }];
    } else {
        self.widthLayoutConstraint.constant = scaledPhotoSize.width;
        self.heightLayoutConstraint.constant = scaledPhotoSize.height;
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

@end

