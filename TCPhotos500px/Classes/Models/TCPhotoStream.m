//
//  TCPhotoStream.m
//  TCPhotos500px
//
//  Created by Lee Tze Cheun on 7/15/13.
//  Copyright (c) 2013 Lee Tze Cheun. All rights reserved.
//

#import "TCPhotoStream.h"
#import "TCPhotoStreamPage.h"

typedef void(^TCPhotoStreamPageCompletionBlock)(TCPhotoStreamPage *page, NSError *error);

@interface TCPhotoStream ()

// Keeps track of the total number of photos in this photo stream.
@property (nonatomic, assign) NSUInteger photoCount;

// We're using a pointer array because our array will be quite sparse.
// E.g. We may have 2000 pages, but user is only viewing the first 2 pages.
@property (nonatomic, strong) NSPointerArray *pages;

@end

#pragma mark -

@implementation TCPhotoStream

- (id)initWithFeature:(PXAPIHelperPhotoFeature)feature category:(PXPhotoModelCategory)category
{
    self = [super init];    
    if (self) {
        _feature = feature;
        _category = category;
    }    
    return self;
}

- (NSUInteger)photoCount
{
    return _photoCount;
}

- (TCPhoto *)photoAtIndex:(NSUInteger)photoIndex completion:(TCPhotoCompletionBlock)completionBlock
{
    // Find the page index from the given photo index.
    NSUInteger pageIndex = photoIndex / kPXAPIHelperDefaultResultsPerPage;
    
    // Find the index of the photo within the page.
    NSUInteger photoIndexWithinPage = photoIndex % kPXAPIHelperDefaultResultsPerPage;
    
    TCPhotoStreamPage *page = [self pageAtIndex:pageIndex];
    
    // If page is available, we will return the photo in the page.
    // If we're currently fetching the page, this will prevent us from fetching
    // the same page again.
    if (page) {
        TCPhoto *photo = [page photoAtIndex:photoIndexWithinPage];
        return photo;
    }
    
    // Create a new empty page at the given page index.
    // This is to indicate that we're currently fetching the page and that we should not fetch it again.
    page = [[TCPhotoStreamPage alloc] initWithPhotoStream:self pageNumber:pageIndex+1];
    [self setPage:page atIndex:pageIndex];
    
    // Fetch the page's photos asynchronously.
    [self fetchPage:page completion:^(TCPhotoStreamPage *page, NSError *error) {
        TCPhoto *photo = page ? [page photoAtIndex:photoIndexWithinPage] : nil;
        completionBlock(photo, error);
    }];
    
    // Return nil to indicate we're fetching from network.
    return nil;
}

#pragma mark - Pages

- (NSPointerArray *)pages
{
    if (!_pages) {
        // We need strong references to the page objects because we're the only
        // object with a strong reference to them.
        _pages = [NSPointerArray strongObjectsPointerArray];
    }
    return _pages;
}

- (TCPhotoStreamPage *)pageAtIndex:(NSUInteger)pageIndex
{
    return (pageIndex < [self.pages count]) ? (__bridge TCPhotoStreamPage *)[self.pages pointerAtIndex:pageIndex] : nil;
}

- (void)setPage:(TCPhotoStreamPage *)page atIndex:(NSUInteger)pageIndex
{
    // Dynamically grow the pointer array to match the number of pages.
    if (pageIndex >= [self.pages count]) {
        [self.pages setCount:(pageIndex + 1)];
    }
    [self.pages replacePointerAtIndex:pageIndex withPointer:(__bridge void *)(page)];
}

- (void)fetchPage:(TCPhotoStreamPage *)page completion:(TCPhotoStreamPageCompletionBlock)completionBlock
{
    TCPhotoStreamPage * __block blockPage = page;
    
    // By default, we exclude Nude photos to make this app child-friendly.
    [PXRequest requestForPhotoFeature:self.feature resultsPerPage:kPXAPIHelperDefaultResultsPerPage page:page.pageNumber photoSizes:(PXPhotoModelSizeThumbnail|PXPhotoModelSizeLarge) sortOrder:kPXAPIHelperDefaultSortOrder except:PXPhotoModelCategoryNude only:self.category completion:^(NSDictionary *results, NSError *error) {
        if (results) {
            NSLog(@"%@", results);
            
            [blockPage setAttributes:results];
            
            // Update the total number of pages and photos in this photo stream.
            self.photoCount = [results[@"total_items"] unsignedIntegerValue];
            [self.pages setCount:[results[@"total_pages"] unsignedIntegerValue]];
        } else if (error) {
            // nil out the page on error, so that we can retry loading it again.
            blockPage = nil;
            [self setPage:blockPage atIndex:(page.pageNumber - 1)];
        }
        
        completionBlock(blockPage, error);
    }];
}

#pragma mark - Debug

- (NSString *)description
{
    return [DescriptionBuilder reflectDescription:self style:DescriptionStyleMultiLine];
}

@end
