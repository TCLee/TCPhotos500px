//
//  TCPhotoStreamCategoryList.m
//  TCPhotos500px
//
//  Created by Lee Tze Cheun on 7/20/13.
//  Copyright (c) 2013 Lee Tze Cheun. All rights reserved.
//

#import "TCPhotoStreamCategoryList.h"
#import "TCPhotoStreamCategory.h"

@interface TCPhotoStreamCategoryList ()

@property (nonatomic, copy) NSArray *categories;
@property (nonatomic, assign) NSUInteger selectedIndex;

@end

#pragma mark -

@implementation TCPhotoStreamCategoryList

+ (instancetype)defaultList
{
    static TCPhotoStreamCategoryList *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[TCPhotoStreamCategoryList alloc] init];
    });
    return sharedInstance;
}

- (NSUInteger)categoryCount
{
    return [self.categories count];
}

- (NSUInteger)indexOfSelectedCategory
{
    return _selectedIndex;
}

- (void)selectCategoryAtIndex:(NSUInteger)index
{
    // Nothing to do if attempting to select an already selected category.
    if (index == self.selectedIndex) {
        return;
    }
    
    // Deselect the currently selected category.
    [(TCPhotoStreamCategory *)self.categories[self.selectedIndex] setSelected:NO];
    
    // Select the category at given index.
    [(TCPhotoStreamCategory *)self.categories[index] setSelected:YES];
    self.selectedIndex = index;
}

- (TCPhotoStreamCategory *)categoryAtIndex:(NSUInteger)index
{
    return self.categories[index];
}

- (void)removeAllCategories
{
    self.categories = nil;
}

#pragma mark - Create Categories

- (NSArray *)categories
{
    if (!_categories) {
        _categories = [[[self class] supportedPhotoStreamCategories] copy];
    }
    return _categories;
}

/* 
 Create an array of TCPhotoStreamCategory objects.
 */
+ (NSArray *)supportedPhotoStreamCategories
{
    // Uncomment the Nude category to show adult-rated photos (which will get
    // your app rejected by Apple).
    
    NSArray *values = @[@(PXAPIHelperUnspecifiedCategory),
                        @(PXPhotoModelCategoryAbstract),
                        @(PXPhotoModelCategoryAnimals),
                        @(PXPhotoModelCategoryBlackAndWhite),
                        @(PXPhotoModelCategoryCelbrities),
                        @(PXPhotoModelCategoryCityAndArchitecture),
                        @(PXPhotoModelCategoryCommercial),
                        @(PXPhotoModelCategoryConcert),
                        @(PXPhotoModelCategoryFamily),
                        @(PXPhotoModelCategoryFashion),
                        @(PXPhotoModelCategoryFilm),
                        @(PXPhotoModelCategoryFineArt),
                        @(PXPhotoModelCategoryFood),
                        @(PXPhotoModelCategoryJournalism),
                        @(PXPhotoModelCategoryLandscapes),
                        @(PXPhotoModelCategoryMacro),
                        @(PXPhotoModelCategoryNature),
//                        @(PXPhotoModelCategoryNude),
                        @(PXPhotoModelCategoryPeople),
                        @(PXPhotoModelCategoryPerformingArts),
                        @(PXPhotoModelCategorySport),
                        @(PXPhotoModelCategoryStillLife),
                        @(PXPhotoModelCategoryStreet),
                        @(PXPhotoModelCategoryTransportation),
                        @(PXPhotoModelCategoryTravel),
                        @(PXPhotoModelCategoryUnderwater),
                        @(PXPhotoModelCategoryUrbanExploration),
                        @(PXPhotoModelCategoryWedding),
                        @(PXPhotoModelCategoryUncategorized)];
    
    NSArray *titles = @[@"All Categories",
                        @"Abstract",
                        @"Animals",
                        @"Black and White",
                        @"Celebrities",
                        @"City and Architecture",
                        @"Commercial",
                        @"Concert",
                        @"Family",
                        @"Fashion",
                        @"Film",
                        @"Fine Art",
                        @"Food",
                        @"Journalism",
                        @"Landscapes",
                        @"Macro",
                        @"Nature",
//                        @"Nude",
                        @"People",
                        @"Performing Arts",
                        @"Sport",
                        @"Still Life",
                        @"Street",
                        @"Transporation",
                        @"Travel",
                        @"Underwater",
                        @"Urban Exploration",
                        @"Wedding",
                        @"Uncategorized"];
    
    return [[self class] categoriesFromValues:values titles:titles];
}

+ (NSArray *)categoriesFromValues:(NSArray *)values titles:(NSArray *)titles
{
    NSMutableArray *categories = [[NSMutableArray alloc] initWithCapacity:[values count]];
    [values enumerateObjectsUsingBlock:^(NSNumber *value, NSUInteger index, BOOL *stop) {
        // Select the first category initially.
        TCPhotoStreamCategory *category = [[TCPhotoStreamCategory alloc] initWithTitle:titles[index]
                                                                                 value:[value integerValue]
                                                                              selected:(0 == index)];
        [categories addObject:category];
    }];
    return categories;
}

@end
