//
//  UIView+TMUtils.h
//  TMComponentContainerView
//
//  Created by tomychen on 2021/1/25.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, TMUIWidthAdjust) {
    TMUIWidthAdjustAutoFix,
    TMUIWidthAdjustStandard,
};

@interface UIView (TMUtils)

@property (nonatomic, assign) UIEdgeInsets tm_padding;
@property (nonatomic, assign) TMUIWidthAdjust tm_widthAdjust;

/**
 * frame.origin.x
 */
@property (nonatomic) CGFloat tm_x;

/**
 * frame.origin.y
 */
@property (nonatomic) CGFloat tm_y;

/**
 * frame.size.width;
 */
@property (nonatomic) CGFloat tm_width;

/**
 *  frame.size.height
 */
@property (nonatomic) CGFloat tm_height;

/**
 *  center.x
 */
@property (nonatomic) CGFloat tm_xCenter;

/**
 *  center.y
 */
@property (nonatomic) CGFloat tm_yCenter;

/**
 *  frame.origin
 */
@property (nonatomic) CGPoint tm_origin;

/**
 *  frame.size
 */
@property (nonatomic) CGSize tm_size;

/**
 * CGRectGetMaxX
 */
@property (nonatomic, readonly) CGFloat tm_maxX;

/**
 *  CGRectGetMaxY
 */
@property (nonatomic, readonly) CGFloat tm_maxY;

@end
