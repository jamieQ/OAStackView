//
//  OAStackViewDistributionStrategy.m
//  Pods
//
//  Created by Omar Abdelhafith on 15/06/2015.
//
//

#import "OAStackViewDistributionStrategy.h"

#import "_OALayoutGuide.h"

@interface OAStackViewDistributionStrategyFill : OAStackViewDistributionStrategy
@end

@interface OAStackViewDistributionStrategyFillEqually : OAStackViewDistributionStrategy
@end

@interface OAStackViewDistributionStrategyFillProportionally : OAStackViewDistributionStrategy
@end

@interface OAStackViewDistributionStrategyEqualSpacing : OAStackViewDistributionStrategy
@end

@interface OAStackViewDistributionStrategyEqualCentering : OAStackViewDistributionStrategy
@end

@interface OAStackViewDistributionStrategy ()
@property(nonatomic, weak) OAStackView *stackView;
@property(nonatomic) NSMutableArray *constraints;
@end

@implementation OAStackViewDistributionStrategy

+ (OAStackViewDistributionStrategy*)strategyWithStackView:(OAStackView *)stackView {
  Class cls;
  
  switch (stackView.distribution) {
    case OAStackViewDistributionFill:
      cls = [OAStackViewDistributionStrategyFill class];
      break;
      
    case OAStackViewDistributionFillEqually:
      cls = [OAStackViewDistributionStrategyFillEqually class];
      break;
   
    case OAStackViewDistributionFillProportionally:
      cls = [OAStackViewDistributionStrategyFillProportionally class];
      break;
      
    case OAStackViewDistributionEqualSpacing:
      cls = [OAStackViewDistributionStrategyEqualSpacing class];
      break;
      
    case OAStackViewDistributionEqualCentering:
      cls = [OAStackViewDistributionStrategyEqualCentering class];
      break;
      
    default:
      break;
  }
  
  return [[cls alloc] initStackView:stackView];
}

- (instancetype)initStackView:(OAStackView*)stackView {
  self = [super init];
  if (self) {
    _stackView = stackView;
  }
  return self;
}

- (void)alignView:(UIView*)view afterView:(UIView*)previousView {
  if (!previousView && !view) { return; }
  
  if (!previousView) {
    return [self alignFirstView:view];
  }
  
  if(!view) {
    return [self alignLastView:previousView];
  }
  
  if (previousView && view) {
    [self alignMiddleView:view afterView:previousView];
  }
}

- (void)alignLastView:(UIView*)view {
  NSString *constraintString = [NSString stringWithFormat:@"%@:[view]-0-|", [self currentAxisString]];
  [self.stackView addConstraints:
   [NSLayoutConstraint constraintsWithVisualFormat:constraintString
                                           options:0
                                           metrics:nil
                                             views:NSDictionaryOfVariableBindings(view)]];
}

- (void)alignFirstView:(UIView*)view {
  NSString *str = [NSString stringWithFormat:@"%@:|-0-[view]", [self currentAxisString]];
  [self.stackView addConstraints:
   [NSLayoutConstraint constraintsWithVisualFormat:str
                                           options:0
                                           metrics:nil
                                             views:NSDictionaryOfVariableBindings(view)]];
}


- (void)alignMiddleView:(UIView*)view afterView:(UIView*)previousView {
  NSString *str = [NSString stringWithFormat:@"%@:[previousView]-(%@%f)-[view]",
                   [self currentAxisString],
                   [self symbolicSpacingRelation],
                   self.stackView.spacing];
  
  id arr = [NSLayoutConstraint constraintsWithVisualFormat:str
                                                   options:0
                                                   metrics:nil
                                                     views:NSDictionaryOfVariableBindings(view, previousView)];
  
  [self.constraints addObjectsFromArray:arr];
  [self.stackView addConstraints:arr];
}


- (NSString*)currentAxisString {
  return self.stackView.axis == UILayoutConstraintAxisHorizontal ? @"H" : @"V";
}

- (NSLayoutAttribute)equalityAxis {
  return self.stackView.axis == UILayoutConstraintAxisVertical ? NSLayoutAttributeHeight : NSLayoutAttributeWidth;
}

- (NSMutableArray *)constraints {
  if (!_constraints) {
    _constraints = [@[] mutableCopy];
  }
  
  return _constraints;
}

- (void)removeAddedConstraints {
  [self.stackView removeConstraints:self.constraints];
  [self.constraints removeAllObjects];
}

- (NSString *)symbolicSpacingRelation
{
  return @"==";
}

@end

@implementation OAStackViewDistributionStrategyFill
@end

@implementation OAStackViewDistributionStrategyFillEqually

- (void)alignMiddleView:(UIView*)view afterView:(UIView*)previousView {
  [super alignMiddleView:view afterView:previousView];
  [self addEqualityConstraintsBetween:view otherView:previousView];
}

- (void)addEqualityConstraintsBetween:(UIView*)view otherView:(UIView*)otherView {
  if (otherView == nil || view == nil) {
    return;
  }
  
  id constraint = [NSLayoutConstraint constraintWithItem:view
                                               attribute:[self equalityAxis]
                                               relatedBy:NSLayoutRelationEqual
                                                  toItem:otherView
                                               attribute:[self equalityAxis]
                                              multiplier:1
                                                constant:0];
  
  [self.constraints addObject:constraint];
  [self.stackView addConstraint:constraint];
}

@end

@implementation OAStackViewDistributionStrategyFillProportionally

- (void)alignMiddleView:(UIView*)view afterView:(UIView*)previousView {
  [super alignMiddleView:view afterView:previousView];
  [self addProportionalityConstraintsBetween:view otherView:previousView];
}

- (void)addProportionalityConstraintsBetween:(UIView *)view otherView:(UIView *)otherView {
  if (view == nil || otherView == nil) {
    return;
  }
  
  CGFloat multiplier = 1;
  if (self.stackView.axis == UILayoutConstraintAxisHorizontal) {
    multiplier = view.intrinsicContentSize.width / otherView.intrinsicContentSize.width;
  } else {
    multiplier = view.intrinsicContentSize.height / otherView.intrinsicContentSize.height;
  }

  id constraint = [NSLayoutConstraint constraintWithItem:view
                                               attribute:[self equalityAxis]
                                               relatedBy:NSLayoutRelationEqual
                                                  toItem:otherView
                                               attribute:[self equalityAxis]
                                              multiplier:multiplier
                                                constant:0];
  
  [self.constraints addObject:constraint];
  [self.stackView addConstraint:constraint];
}

@end

@interface OAStackViewDistributionStrategyEqualSpacing ()

@property (nonatomic, strong) NSMutableArray *equalSpacingLayoutGuides;

@end

@implementation OAStackViewDistributionStrategyEqualSpacing

- (NSLayoutAttribute)spanningAttributeForAxis:(UILayoutConstraintAxis)axis
                                isInitialEdge:(BOOL)isInitialConstraint
{
  switch (axis) {
    case UILayoutConstraintAxisHorizontal:
      return isInitialConstraint ? NSLayoutAttributeLeading : NSLayoutAttributeTrailing;

    case UILayoutConstraintAxisVertical:
      return isInitialConstraint ? NSLayoutAttributeTop : NSLayoutAttributeBottom;
  }
}

- (NSMutableArray *)equalSpacingLayoutGuides
{
  if (!_equalSpacingLayoutGuides) {
    _equalSpacingLayoutGuides = [NSMutableArray array];
  }

  return _equalSpacingLayoutGuides;
}

- (NSString *)symbolicSpacingRelation
{
  return @">=";
}

- (void)alignMiddleView:(UIView *)view afterView:(UIView *)previousView
{
  [super alignMiddleView:view afterView:previousView];

  _OALayoutGuide *guide = [_OALayoutGuide new];
  [self.equalSpacingLayoutGuides addObject:guide];
  [self.stackView addSubview:guide];

  NSMutableArray *newConstraints = [NSMutableArray array];

  UILayoutConstraintAxis axis = self.stackView.axis;

  NSLayoutConstraint *firstEdgeConstraint =
  [NSLayoutConstraint constraintWithItem:guide
                               attribute:[self spanningAttributeForAxis:axis
                                                          isInitialEdge:YES]
                               relatedBy:NSLayoutRelationEqual
                                  toItem:previousView
                               attribute:[self spanningAttributeForAxis:axis
                                                          isInitialEdge:NO]
                              multiplier:1
                                constant:0];

  NSLayoutConstraint *secondEdgeConstraint =
  [NSLayoutConstraint constraintWithItem:view
                               attribute:[self spanningAttributeForAxis:axis
                                                          isInitialEdge:YES]
                               relatedBy:NSLayoutRelationEqual
                                  toItem:guide
                               attribute:[self spanningAttributeForAxis:axis
                                                          isInitialEdge:NO]
                              multiplier:1
                                constant:0];

  [newConstraints addObjectsFromArray:@[firstEdgeConstraint, secondEdgeConstraint]];

  id firstGuide = self.equalSpacingLayoutGuides.firstObject;
  if (firstGuide != guide) {
    NSLayoutConstraint *equalWidth =
    [NSLayoutConstraint constraintWithItem:firstGuide
                                 attribute:[self equalityAxis]
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:guide
                                 attribute:[self equalityAxis]
                                multiplier:1
                                  constant:0];

    equalWidth.identifier = @"OA-fill-equally";

    [newConstraints addObject:equalWidth];
  }

  [self.constraints addObjectsFromArray:newConstraints];
  [self.stackView addConstraints:newConstraints];
}

- (void)removeAddedConstraints
{
  [self.stackView removeConstraints:self.constraints];
  [self.constraints removeAllObjects];

  [self.equalSpacingLayoutGuides makeObjectsPerformSelector:@selector(removeFromSuperview)];
  [self.equalSpacingLayoutGuides removeAllObjects];
}

@end

@interface OAStackViewDistributionStrategyEqualCentering ()

@property (nonatomic, strong) NSMutableArray *equalCenteringLayoutGuides;

@end

@implementation OAStackViewDistributionStrategyEqualCentering

- (NSLayoutAttribute)spanningAttributeForAxis:(UILayoutConstraintAxis)axis
                                isLayoutGuide:(BOOL)isLayoutGuide
                                  isFirstItem:(BOOL)isFirstItem
{
  switch (axis) {
    case UILayoutConstraintAxisHorizontal:
      if (isLayoutGuide) {
        return isFirstItem ? NSLayoutAttributeLeading : NSLayoutAttributeTrailing;
      } else {
        return NSLayoutAttributeCenterX;
      }

    case UILayoutConstraintAxisVertical:
      if (isLayoutGuide) {
        return isFirstItem ? NSLayoutAttributeTop : NSLayoutAttributeBottom;
      } else {
        return NSLayoutAttributeCenterY;
      }
  }
}

- (NSLayoutAttribute)spacingAttributeForAxis:(UILayoutConstraintAxis)axis
{
  switch (axis) {
    case UILayoutConstraintAxisHorizontal:
      return NSLayoutAttributeWidth;

      case UILayoutConstraintAxisVertical:
      return NSLayoutAttributeHeight;
  }
}

- (NSMutableArray *)equalCenteringLayoutGuides
{
  if (!_equalCenteringLayoutGuides) {
    _equalCenteringLayoutGuides = [NSMutableArray array];
  }

  return _equalCenteringLayoutGuides;
}

- (NSString *)symbolicSpacingRelation
{
  return @">=";
}

- (void)alignMiddleView:(UIView *)view afterView:(UIView *)previousView
{
  [super alignMiddleView:view afterView:previousView];

  _OALayoutGuide *guide = [_OALayoutGuide new];
  [self.equalCenteringLayoutGuides addObject:guide];
  [self.stackView addSubview:guide];

  NSMutableArray *newConstraints = [NSMutableArray array];

  UILayoutConstraintAxis axis = self.stackView.axis;

  NSLayoutConstraint *firstEdgeConstraint =
  [NSLayoutConstraint constraintWithItem:guide
                               attribute:[self spanningAttributeForAxis:axis
                                                          isLayoutGuide:YES
                                                            isFirstItem:YES]
                               relatedBy:NSLayoutRelationEqual
                                  toItem:previousView
                               attribute:[self spanningAttributeForAxis:axis
                                                          isLayoutGuide:NO
                                                            isFirstItem:YES]
                              multiplier:1
                                constant:0];

  NSLayoutConstraint *secondEdgeConstraint =
  [NSLayoutConstraint constraintWithItem:view
                               attribute:[self spanningAttributeForAxis:axis
                                                          isLayoutGuide:NO
                                                            isFirstItem:NO]
                               relatedBy:NSLayoutRelationEqual
                                  toItem:guide
                               attribute:[self spanningAttributeForAxis:axis
                                                          isLayoutGuide:YES
                                                            isFirstItem:NO]
                              multiplier:1
                                constant:0];

  [newConstraints addObjectsFromArray:@[firstEdgeConstraint, secondEdgeConstraint]];

  id firstGuide = self.equalCenteringLayoutGuides.firstObject;
  if (firstGuide != guide) {
    NSLayoutConstraint *equalDimension =
    [NSLayoutConstraint constraintWithItem:firstGuide
                                 attribute:[self equalityAxis]
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:guide
                                 attribute:[self equalityAxis]
                                multiplier:1
                                  constant:0];

    NSUInteger gapCount = self.equalCenteringLayoutGuides.count;
    if (gapCount > 1) {
      float const OAEqualCenteringLayoutPriority = 150;
      equalDimension.priority = MAX(OAEqualCenteringLayoutPriority - gapCount + 1,
                                    UILayoutPriorityFittingSizeLevel);
    }

    equalDimension.identifier = @"OA-fill-equally";

    [newConstraints addObject:equalDimension];
  }

  [self.constraints addObjectsFromArray:newConstraints];
  [self.stackView addConstraints:newConstraints];
}

- (void)removeAddedConstraints
{
  [self.stackView removeConstraints:self.constraints];
  [self.constraints removeAllObjects];

  [self.equalCenteringLayoutGuides makeObjectsPerformSelector:@selector(removeFromSuperview)];
  [self.equalCenteringLayoutGuides removeAllObjects];
}

@end
