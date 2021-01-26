//
//  TMComponentContainerView.h
//  TMComponentContainerView
//
//  Created by tomychen on 2021/1/25.
//

#import <UIKit/UIKit.h>
#import "UIView+TMUtils.h"
#import "UIScrollView+TMUtils.h"

@class TMComponentContainerView;

@protocol TMComponentContainerViewDelegate <NSObject>

@optional
- (void)containerScrollViewDidScroll:(TMComponentContainerView *)containScrollView;
- (void)containerScrollViewAlreadyAtBottom:(TMComponentContainerView *)containScrollView;
- (void)containerScrollViewDidEndDecelerating:(TMComponentContainerView *)containScrollView;
- (BOOL)containerScrollView:(TMComponentContainerView *)containScrollView gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer;

@end

@interface TMComponentContainerView : UIScrollView

@property (nonatomic, weak) id<TMComponentContainerViewDelegate> containDelegate;
@property (nonatomic, strong, readonly) UIView *contentView;
@property (nonatomic, strong) NSArray<UIView *> *componentViews;

@property (nonatomic, assign, readonly) BOOL isScrollingFast;

- (instancetype)initWithFrame:(CGRect)frame componentViews:(NSArray<UIView *> *)componentViews;

- (CGFloat)topWithView:(UIView *)view;
- (void)scrollViewToTop:(UIView *)view animation:(BOOL)animation;
- (void)scrollViewToTop:(UIView *)view offset:(CGFloat)offsetY animation:(BOOL)animation;
- (BOOL)viewScrollTopToOut:(UIView *)view;

- (UIView *)visiableTopView;
- (UIView *)visiableTopViewOffset:(CGFloat)offset;

- (NSInteger)visiableTopViewIndex;
- (NSInteger)visiableTopViewIndexOffset:(CGFloat)offsetY;

@end
