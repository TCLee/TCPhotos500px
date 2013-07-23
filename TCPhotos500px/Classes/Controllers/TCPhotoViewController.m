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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	[self reloadView];
}

//#pragma mark - Memory Management
//
//- (void)didReceiveMemoryWarning
//{
//    [super didReceiveMemoryWarning];
//}

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
