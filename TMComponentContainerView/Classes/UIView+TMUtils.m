//
//  UIView+TMUtils.m
//  TMComponentContainerView
//
//  Created by tomychen on 2021/1/25.
//

#import "UIView+TMUtils.h"
#import <objc/runtime.h>

@implementation UIView (TMUtils)
- (UIEdgeInsets)tm_padding {
    return [objc_getAssociatedObject(self, @"tm_padding") UIEdgeInsetsValue];
}

- (void)setTm_padding:(UIEdgeInsets)tm_padding {
    objc_setAssociatedObject(self, @"tm_padding", [NSValue valueWithUIEdgeInsets:tm_padding], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (TMUIWidthAdjust)tm_widthAdjust {
    return [objc_getAssociatedObject(self, @"tm_widthAdjust") integerValue];
}

- (void)setTm_widthAdjust:(TMUIWidthAdjust)tm_widthAdjust {
    objc_setAssociatedObject(self, @"tm_widthAdjust", @(tm_widthAdjust), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}



- (CGFloat)tm_x {
    return CGRectGetMinX(self.frame);
}

- (void)setTm_x:(CGFloat)tm_x {
    CGRect newFrame = self.frame;
    newFrame.origin.x = tm_x;
    self.frame = newFrame;
}

- (CGFloat)tm_y {
    return CGRectGetMinX(self.frame);
}

- (void)setTm_y:(CGFloat)tm_y {
    CGRect newFrame = self.frame;
    newFrame.origin.y = tm_y;
    self.frame = newFrame;
}

- (CGFloat)tm_width {
    return CGRectGetWidth(self.frame);
}

- (void)setTm_width:(CGFloat)tm_width {
    CGRect newFrame = self.frame;
    newFrame.size.width = tm_width;
    self.frame = newFrame;
}

- (CGFloat)tm_height {
    return CGRectGetHeight(self.frame);
}

- (void)setTm_height:(CGFloat)tm_height {
    CGRect newFrame = self.frame;
    newFrame.size.height = tm_height;
    self.frame = newFrame;
}

- (CGFloat)tm_xCenter {
    return CGRectGetMidX(self.frame);
}

- (void)setTm_xCenter:(CGFloat)tm_xCenter {
    CGPoint newPoint = self.center;
    newPoint.x = tm_xCenter;
    self.center = newPoint;
}

- (CGFloat)tm_yCenter {
    return CGRectGetMidY(self.frame);
}

- (void)setTm_yCenter:(CGFloat)tm_yCenter {
    CGPoint newPoint = self.center;
    newPoint.y = tm_yCenter;
    self.center = newPoint;
}

- (CGPoint)tm_origin {
    return self.frame.origin;
}

- (void)setTm_origin:(CGPoint)tm_origin {
    CGRect newFrame = self.frame;
    newFrame.origin = tm_origin;
    self.frame = newFrame;
}

- (CGSize)tm_size {
    return self.frame.size;
}

- (void)setTm_size:(CGSize)tm_size {
    CGRect newFrame = self.frame;
    newFrame.size = tm_size;
    self.frame = newFrame;
}

- (CGFloat)tm_maxX {
    return CGRectGetMaxX(self.frame);
}

- (CGFloat)tm_maxY {
    return CGRectGetMaxY(self.frame);
}

@end
