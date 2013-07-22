//
//  TCPhotoStreamPage.m
//  TCPhotos500px
//
//  Created by Lee Tze Cheun on 7/17/13.
//  Copyright (c) 2013 Lee Tze Cheun. All rights reserved.
//

#import "TCPhotoStreamPage.h"
#import "TCPhotoStream.h"
#import "TCPhoto.h"

@interface TCPhotoStreamPage ()

@property (nonatomic, strong) NSMutableArray *photos;

@end

@implementation TCPhotoStreamPage

- (id)initWithPhotoStream:(TCPhotoStream *)photoStream
               pageNumber:(NSInteger)pageNumber
{
    self = [super init];
    
    if (self) {
        _photoStream = photoStream;
        _pageNumber = pageNumber;                
    }
    
    return self;
}

- (void)setAttributes:(NSDictionary *)attributes
{
    NSArray *photoArray = attributes[@"photos"];
    self.photos = [[NSMutableArray alloc] initWithCapacity:[photoArray count]];
    
    for (NSDictionary *photoDict in photoArray) {
        TCPhoto *photo = [[TCPhoto alloc] initWithPage:self attributes:photoDict];
        [self.photos addObject:photo];
    }
}

- (NSUInteger)photoCount
{
    return [self.photos count];
}

- (TCPhoto *)photoAtIndex:(NSUInteger)index
{
    return (index < [self photoCount]) ? self.photos[index] : nil;
}

@end
