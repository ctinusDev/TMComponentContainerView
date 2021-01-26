//
//  UIScrollView+TMUtils.m
//  TMComponentContainerView
//
//  Created by tomychen on 2021/1/25.
//

#import "UIScrollView+TMUtils.h"
#import <objc/runtime.h>

@implementation UIScrollView (TMUtils)

- (CGFloat)preferContentSizeHeight {
    return [objc_getAssociatedObject(self, @"TMPreferContentSizeHeight") boolValue];
}

- (void)setPreferContentSizeHeight:(CGFloat)preferContentSizeHeight {
    objc_setAssociatedObject(self, @"TMPreferContentSizeHeight", @(preferContentSizeHeight), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}



- (CGFloat)minContentSizeHeight {
    return [objc_getAssociatedObject(self, @"TMMinContentSizeHeight") floatValue];
}

- (void)setMinContentSizeHeight:(CGFloat)minContentSizeHeight {
    objc_setAssociatedObject(self, @"TMMinContentSizeHeight", @(minContentSizeHeight), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
