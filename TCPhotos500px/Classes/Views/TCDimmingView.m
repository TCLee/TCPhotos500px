//
//  TCDimmingView.m
//  TCPhotos500px
//
//  Created by Lee Tze Cheun on 7/28/13.
//  Copyright (c) 2013 Lee Tze Cheun. All rights reserved.
//

#import "TCDimmingView.h"

static NSTimeInterval const kAnimationDuration = 0.5f;

@implementation TCDimmingView

#pragma mark - UIView Methods Override

- (id)initWithDelegate:(id<TCDimmingViewDelegate>)delegate
{
    self = [super init];
    if (self) {
        _delegate = delegate;
        [self configureView];
    }
    return self;
}

/* 
 We are depending on auto layout's constraints to size this
 view properly. 
 */
+ (BOOL)requiresConstraintBasedLayout
{
    return YES;
}

#pragma mark - Add and Remove from Superview

- (void)addToSuperview:(UIView *)parentView animated:(BOOL)animated
{
    // Don't allow the dimming view to be added again to the same parent view.
    if (self.superview == parentView) {
        return;
    }
    
    // Perform a fade in animation, if animation is requested.
    if (animated) {
        self.alpha = 0.0f;
        [UIView animateWithDuration:kAnimationDuration animations:^{
            self.alpha = 1.0f;
        }];
    }
    
    // Add ourself to parent view and setup the auto layout constraints that
    // the dimming view needs.
    [parentView addSubview:self];
    [self.superview addConstraints:[self constraintsForSuperview]];
}

- (void)removeFromSuperviewAnimated:(BOOL)animated
{
    if (animated) {
        self.alpha = 1.0f;
        [UIView animateWithDuration:kAnimationDuration animations:^{
            self.alpha = 0.0f;
        } completion:^(BOOL finished) {
            [self removeFromSuperview];
        }];
    } else {
        [self removeFromSuperview];
    }
}

#pragma mark -

/*
 Initialize the properties required to display the dimming view properly.
 */
- (void)configureView
{
    // Semi-transparent black color to dim the other views.
    self.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.5f];
    self.opaque = NO;
    
    // When we add the dimming view over all the other views, it will capture
    // all the touches. This will effectively disable all the other views under
    // the dimming view.
    self.userInteractionEnabled = YES;
    
    // We're using autolayout constraints for this view. No need for any autoresizing masks.
    self.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self addTapToDismissGesture];
}

#pragma mark - Auto Layout Constraints

/*
 Create and return the constraints for the dimming view's superview.
 This is required for the dimming view to be sized properly in relation to its superview.
 */
- (NSArray *)constraintsForSuperview
{
    UIView *dimmingView = self;
    NSMutableArray *constraints = [[NSMutableArray alloc] init];
    
    // Basically, we're specifying the dimming view has zero margins to its superview.
    // (i.e. it will grow in size with the superview)
    NSArray *horizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[dimmingView]-0-|"
                                                                                        options:0
                                                                                        metrics:nil
                                                                                          views:NSDictionaryOfVariableBindings(dimmingView)];
    
    NSArray *verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[dimmingView]-0-|"
                                                                             options:0
                                                                             metrics:nil
                                                                               views:NSDictionaryOfVariableBindings(dimmingView)];
    
    [constraints addObjectsFromArray:horizontalConstraints];
    [constraints addObjectsFromArray:verticalConstraints];
    return constraints;    
}

#pragma mark - Tap Gesture Recognizer

- (void)addTapToDismissGesture
{
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapToDismiss:)];
    tapGestureRecognizer.numberOfTapsRequired = 1;
    
    // So the user can still interact with controls in the modal view.
    tapGestureRecognizer.cancelsTouchesInView = NO;
    
    // Add tap gesture recognizer to the dimming view. When user taps on it,
    // it will dismiss the modal view.
    [self addGestureRecognizer:tapGestureRecognizer];
}

- (void)handleTapToDismiss:(UITapGestureRecognizer *)sender
{
    if (UIGestureRecognizerStateRecognized == sender.state) {
        // Notify delegate that we've received a tap gesture.
        [self.delegate dimmingViewDidReceiveTapGesture:self];
    }
}


@end
