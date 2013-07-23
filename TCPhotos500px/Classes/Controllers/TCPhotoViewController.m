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

@interface TCPhotoViewController ()

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *fullNameLabel;

@end

@implementation TCPhotoViewController

#pragma mark - View Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	[self reloadView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Add tap gesture recognizer in viewDidAppear because our view is now added
    // to the window.
    [self addTapToDismissGesture];
}

#pragma mark - Dismiss Modal View on Tap Gesture

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
        [self dismissViewControllerAnimated:YES completion:^{
            
        }];
    }
}

#pragma mark - Photo Model

- (void)setPhoto:(TCPhoto *)newPhoto
{
    if (_photo != newPhoto) {
        _photo = newPhoto;
        
        [self reloadView];
    }
}

/* Updates the view with the photo model's data. */
- (void)reloadView
{
    [self.imageView setImageWithURL:self.photo.imageURL];
    self.titleLabel.text = self.photo.title;
    self.fullNameLabel.text = self.photo.userFullName;
}

@end
