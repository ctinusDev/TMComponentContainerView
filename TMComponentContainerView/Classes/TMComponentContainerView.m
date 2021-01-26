//
//  TMComponentContainerView.m
//  TMComponentContainerView
//
//  Created by tomychen on 2021/1/25.
//

#import "TMComponentContainerView.h"
#import <KVOController/KVOController.h>
#import <WebKit/WebKit.h>
#import "UIScrollView+TMUtils.h"

/*weak self*/
#define tm_weakify(VAR) __weak __typeof__(VAR) VAR##_weak_ = VAR

/*strong self*/
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wshadow"
#if  __has_feature(objc_arc)
#define tm_strongify(VAR) __strong __typeof__(VAR) VAR = (VAR##_weak_)
#else
#define tm_strongify(VAR) __strong __typeof__(VAR) VAR = [[(VAR##_weak_) retain] autorelease];
#endif
#pragma clang diagnostic pop


@interface TMComponentContainerView()<UIScrollViewDelegate>

@property (nonatomic, assign) CGRect preFrame;

@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, strong) NSMutableArray *lastHeights; //用来保存最后一次各个高度，判断是和否需要刷新界面

@property (nonatomic, strong) NSMutableArray<NSNumber *> *boundaryValues;

@property (nonatomic, assign) CGPoint lastOffset;

@property (nonatomic, assign) NSTimeInterval lastOffsetCapture;

@property (nonatomic, assign) BOOL isScrollingFast;

@end

@implementation TMComponentContainerView
#pragma mark - LifeCycle
- (instancetype)initWithFrame:(CGRect)frame componentViews:(NSArray<UIView *> *)componentViews {
    if (self = [super initWithFrame:frame]) {
        self.componentViews = componentViews;
        
    }
    return self;
}

- (void)initSubViews {
    self.delegate = self;
    self.alwaysBounceVertical = YES;
    
    self.contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height * 2)];
    [self addSubview:self.contentView];
    
    self.lastHeights = [NSMutableArray array];
    [self.componentViews enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[WKWebView class]] || [obj isKindOfClass:[UIWebView class]]) {
            [(WKWebView *)obj scrollView].scrollEnabled = NO;
        } else if ([obj isKindOfClass:[UIScrollView class]]) {
            ((UIScrollView *)obj).scrollEnabled = NO;
        } else {
            //普通View
        }
        [self.contentView addSubview:obj];
        self.lastHeights[idx] = @(0);
    }];
    
    [self updateContainer];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (CGRectEqualToRect(self.preFrame, self.frame)) {
        [self updateContainerForce:NO];
    } else {
        [self updateContainerForce:YES];
    }
}


- (void)dealloc {
    [self.KVOControllerNonRetaining unobserveAll];
}

#pragma mark - Public
- (CGFloat)topWithView:(UIView *)view {
    if (![view isKindOfClass:UIView.class]) {
        return -1;
    }
    
    if (![self.componentViews containsObject:view]) {
        return -1;
    }
    
    __block CGFloat offsetY = 0;
    [self.componentViews enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj == view) {
            *stop = YES;
            return ;
        }
        CGFloat height = [self contentSizeHeightForView:obj];
        offsetY += height;
    }];
    
    offsetY = MAX(0, MIN(offsetY, self.contentSize.height + self.contentInset.bottom - self.tm_height));
    return offsetY;
}

- (void)scrollViewToTop:(UIView *)view animation:(BOOL)animation {
    [self scrollViewToTop:view offset:0 animation:animation];
}

- (void)scrollViewToTop:(UIView *)view offset:(CGFloat)offsetY animation:(BOOL)animation {
    CGFloat offset = [self topWithView:view] + offsetY;
    [self setContentOffset:CGPointMake(0, offset) animated:animation];
}

- (BOOL)viewScrollTopToOut:(UIView *)view {
    if (![view isKindOfClass:UIView.class]) {
        return NO;
    }

    if (![self.componentViews containsObject:view]) {
        return NO;
    }
    
    __block CGFloat offsetY = 0;
    [self.componentViews enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CGFloat height = [self contentSizeHeightForView:obj];
        offsetY += height;
        
        if (obj == view) {
            *stop = YES;
            return ;
        }
    }];
    
    return self.contentOffset.y > offsetY;
}

- (UIView *)visiableTopView {
    return [self visiableTopViewOffset:0];
}

- (UIView *)visiableTopViewOffset:(CGFloat)offset {
    __block UIView *topView = nil;
    __block CGFloat sumHeight = 0;
    [self.componentViews enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CGFloat height = [self contentSizeHeightForView:obj];
        if (self.contentOffset.y + offset >= sumHeight && self.contentOffset.y + offset <= sumHeight + height) {
            topView = obj;
            *stop = YES;
        }
        sumHeight += height;
    }];
    return topView;
}

- (NSInteger)visiableTopViewIndex {
    return [self visiableTopViewIndexOffset:0];
}

- (NSInteger)visiableTopViewIndexOffset:(CGFloat)offsetY {
    UIView *topView = [self visiableTopViewOffset:offsetY];
    if (topView) {
        return [self.componentViews indexOfObject:topView];
    }
    return NSNotFound;
}

#pragma mark - Private
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if ([self.containDelegate respondsToSelector:@selector(containerScrollView:gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:)]) {
        return [self.containDelegate containerScrollView:self gestureRecognizer:gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:otherGestureRecognizer];
    }
    return NO;
}

-(BOOL)touchesShouldCancelInContentView:(UIView *)view
{
    [super touchesShouldCancelInContentView:view];
    return YES;
}

- (UIEdgeInsets)tm_contentInset {
    if (@available(iOS 11, *)) {
        return self.adjustedContentInset;
    } else {
        return self.contentInset;
    }
}

/// 获取UIEdgeInsets在垂直方向上的值
CG_INLINE CGFloat
UIEdgeInsetsGetVerticalValue(UIEdgeInsets insets) {
    return insets.top + insets.bottom;
}

/// 获取UIEdgeInsets在水平方向上的值
CG_INLINE CGFloat
UIEdgeInsetsGetHorizontalValue(UIEdgeInsets insets) {
    return insets.left + insets.right;
}

- (BOOL)canScroll {
    // 没有高度就不用算了，肯定不可滚动，这里只是做个保护
    if (self.tm_width <= 0 || self.tm_height <= 0) {
        return NO;
    }
    BOOL canVerticalScroll = self.contentSize.height + UIEdgeInsetsGetVerticalValue(self.tm_contentInset) > self.tm_height;
    BOOL canHorizontalScoll = self.contentSize.width + UIEdgeInsetsGetHorizontalValue(self.tm_contentInset) > self.tm_width;
    return canVerticalScroll || canHorizontalScoll;
}

- (BOOL)alreadyAtBottom {
    if (!self.canScroll) {
        return YES;
    }
    
    if (((NSInteger)self.contentOffset.y) == ((NSInteger)self.contentSize.height + self.tm_contentInset.bottom - self.tm_height)) {
        return YES;
    }
    
    return NO;
}

#pragma mark - Observers
- (void)addObservers{
    tm_weakify(self);
    [self.componentViews enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        tm_strongify(self);
        if ([obj isKindOfClass:[WKWebView class]] || [obj isKindOfClass:[UIWebView class]]) {
            [self.KVOControllerNonRetaining observe:obj keyPaths:@[@"scrollView.contentSize", @"bounds"] options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    tm_strongify(self);
                    
                    if ([change[FBKVONotificationKeyPathKey] isEqualToString:@"bounds"]) {
                        if (!CGSizeEqualToSize([change[NSKeyValueChangeNewKey] CGRectValue].size, [change[NSKeyValueChangeOldKey] CGRectValue].size)  ) {
                            [self updateContainerForce:YES];
                        }
                    } else {
                        if (!CGSizeEqualToSize([change[NSKeyValueChangeNewKey] CGSizeValue], [change[NSKeyValueChangeOldKey] CGSizeValue])) {
                            [self updateContainer];
                        }
                    }
                });
            }];
        } else if ([obj isKindOfClass:[UITextView class]]) {
            //UITextView如果设置了scrllEnable = NO。contentSize 会被强制改为bounds.size
            [self.KVOControllerNonRetaining observe:obj keyPath:@"bounds" options:NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    tm_strongify(self);
                    if ([change[FBKVONotificationKeyPathKey] isEqualToString:@"bounds"]) {
                        if (!CGSizeEqualToSize([change[NSKeyValueChangeNewKey] CGRectValue].size, [change[NSKeyValueChangeOldKey] CGRectValue].size)  ) {
                            [self updateContainer];
                        }
                    }
                });
            }];
        } else if ([obj isKindOfClass:[UIScrollView class]]) {
            [self.KVOControllerNonRetaining observe:obj keyPaths:@[@"contentSize", @"bounds"] options:NSKeyValueObservingOptionNew  | NSKeyValueObservingOptionOld block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    tm_strongify(self);
                    
                    if ([change[FBKVONotificationKeyPathKey] isEqualToString:@"bounds"]) {
                        if (!CGSizeEqualToSize([change[NSKeyValueChangeNewKey] CGRectValue].size, [change[NSKeyValueChangeOldKey] CGRectValue].size)  ) {
                            [self updateContainerForce:YES];
                        }
                    } else {
                        [self updateContainer];
                    }
                });
            }];
        } else {
            //普通View,监控Frame变化
            [self.KVOControllerNonRetaining observe:obj keyPath:@"bounds" options:NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    tm_strongify(self);
                    if ([change[FBKVONotificationKeyPathKey] isEqualToString:@"bounds"]) {
                        if (!CGSizeEqualToSize([change[NSKeyValueChangeNewKey] CGRectValue].size, [change[NSKeyValueChangeOldKey] CGRectValue].size)  ) {
                            [self updateContainer];
                        }
                    }
                });
            }];
        }
    }];
}

- (void)removeObservers {
    [self.KVOControllerNonRetaining unobserveAll];
}

- (void)updateContainerForce:(BOOL)force {
    self.contentView.tm_width = self.tm_width;
    
    __block BOOL changed = NO;
    __block CGFloat totalHeight = 0;
    [self.componentViews enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CGFloat lastHeight = [self.lastHeights[idx] floatValue];
        CGFloat height = [self contentSizeHeightForView:obj];
        if (lastHeight != height) {
            self.lastHeights[idx] = @(height);
            changed = YES;
        }
        totalHeight += height;
    }];
    //如果所有View高度没有变化不需要修改
    if (!changed && !force) {
        return;
    }
    self.contentSize = CGSizeMake(self.frame.size.width, totalHeight);
    
    totalHeight = 0;
    [self.componentViews enumerateObjectsUsingBlock:^(UIView * _Nonnull view, NSUInteger idx, BOOL * _Nonnull stop) {
        CGFloat height = [self contentSizeHeightForView:view];
        
        totalHeight += view.tm_padding.top;
        
        if ([view isKindOfClass:[WKWebView class]] || [view isKindOfClass:[UIWebView class]]) {
            height = (height < self.tm_height) ? height :self.tm_height;
            view.tm_height = height <= 0.1 ? 0.1 : height;
        } else if (![view isKindOfClass:[UITextView class]] && [view isKindOfClass:[UIScrollView class]]) {
            height = (height < self.tm_height) ? height :self.tm_height;
            view.tm_height = height;
        } else {
            //普通页面不需要修改宽高，内部不会改变size
        }
        
        view.tm_y = totalHeight;
        
        view.tm_x = view.tm_padding.left;
        if (view.tm_widthAdjust == TMUIWidthAdjustAutoFix) {
            view.tm_width = self.contentView.tm_width - view.tm_padding.left - view.tm_padding.right;
        }
        
        totalHeight += height;
        totalHeight += view.tm_padding.bottom;
    }];
    self.contentView.tm_height = totalHeight;
    
    totalHeight = 0;
    self.boundaryValues = [NSMutableArray array];
    [self.componentViews enumerateObjectsUsingBlock:^(UIView * _Nonnull view, NSUInteger idx, BOOL * _Nonnull stop) {
        CGFloat contentHeight = [self contentSizeHeightForView:view];
        CGFloat boundsHeight = view.tm_height;
        CGFloat value = view.tm_padding.top + totalHeight + contentHeight - boundsHeight;
        [self.boundaryValues addObject:@(value)];
        [self.boundaryValues addObject:@(totalHeight + contentHeight + view.tm_padding.bottom)];
        totalHeight += contentHeight;
    }];
    
    //Fix:contentSize变化时需要更新各个控件的位置
    [self scrollViewDidScroll:self];
}

- (void)updateContainer {
    [self updateContainerForce:NO];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if (self != scrollView) {
        return;
    }
    
    CGPoint currentOffset = scrollView.contentOffset;
    NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
    
    NSTimeInterval timeDiff = currentTime - self.lastOffsetCapture;
    if(timeDiff > 0.1) {
        CGFloat distance = currentOffset.y - self.lastOffset.y;
        //The multiply by 10, / 1000 isn't really necessary.......
        CGFloat scrollSpeedNotAbs = (distance * 10) / 1000; //in pixels per millisecond
        
        CGFloat scrollSpeed = fabs(scrollSpeedNotAbs);
        if (scrollSpeed > 0.5) {
            self.isScrollingFast = YES;
        } else {
            self.isScrollingFast = NO;
        }
        
        self.lastOffset = currentOffset;
        self.lastOffsetCapture = currentTime;
    }
    
    if ([self.containDelegate respondsToSelector:@selector(containerScrollViewDidScroll:)]) {
        [self.containDelegate containerScrollViewDidScroll:self];
    }
    
    CGFloat offsetY = scrollView.contentOffset.y;
    if (offsetY <= 0) {
        self.contentView.tm_y = 0;
        [self.componentViews enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self setView:obj contentOffsetY:0];
        }];
        
        return;
    }
    
    __block NSInteger handleViewIndex = 0;
    [self.boundaryValues enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (offsetY < obj.floatValue) {
            handleViewIndex = idx/2;
            UIView *handleView = self.componentViews[handleViewIndex];
            
            if (idx % 2 == 0) {
                //contentview不跟随scrollView滚动， componentView滚动
                CGFloat preContentHeight = 0;
                if (idx > 0) {
                    preContentHeight = [self.boundaryValues[idx - 1] floatValue];
                }
                self.contentView.tm_y = offsetY - ((handleViewIndex > 0) ? CGRectGetMaxY(self.componentViews[handleViewIndex - 1].frame) : 0);
                [self setView:handleView contentOffsetY:offsetY - preContentHeight];
            } else {
                //contentView跟随scrollView滚动，componentView不滚动
                CGFloat preContentHeight = 0;
                if (idx > 1) {
                    preContentHeight = [self.boundaryValues[idx - 2] floatValue];
                }
                self.contentView.tm_y = preContentHeight - handleView.frame.origin.y + handleView.tm_padding.top + [self contentSizeHeightForView:handleView] - handleView.frame.size.height;
                [self setView:handleView contentOffsetY:[self contentSizeHeightForView:handleView] - handleView.frame.size.height];
            }
            *stop = YES;
        } else {
            UIView *view = self.componentViews[idx/2];
            [self setView:view contentOffsetY:[self contentSizeHeightForView:view] - view.frame.size.height];
        }
    }];
    
    for (NSInteger i = handleViewIndex + 1; i < self.componentViews.count; i++) {
        UIView *view = self.componentViews[i];
        [self setView:view contentOffsetY:0];
    }
    
    if ([self alreadyAtBottom]) {
        if ([self.containDelegate respondsToSelector:@selector(containerScrollViewAlreadyAtBottom:)]) {
            [self.containDelegate containerScrollViewAlreadyAtBottom:self];
        }
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (decelerate) {
        return;
    }
    if ([self.containDelegate respondsToSelector:@selector(containerScrollViewDidEndDecelerating:)]) {
        [self.containDelegate containerScrollViewDidEndDecelerating:self];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if ([self.containDelegate respondsToSelector:@selector(containerScrollViewDidEndDecelerating:)]) {
        [self.containDelegate containerScrollViewDidEndDecelerating:self];
    }
}

#pragma mark - Setter
- (void)setComponentViews:(NSArray<UIView *> *)componentViews {
    _componentViews = componentViews;
    
    [self.KVOControllerNonRetaining unobserveAll];
    [self.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    [self initSubViews];
    [self addObservers];
}

- (void)setView:(UIView *)view contentOffsetY:(CGFloat)offsetY {
    if ([view isKindOfClass:[WKWebView class]] || [view isKindOfClass:[UIWebView class]]) {
        [[((WKWebView *)view) scrollView] setContentOffset:CGPointMake(0, offsetY) animated:NO];
    } else if (![view isKindOfClass:[UITextView class]] && [view isKindOfClass:[UIScrollView class]]) {
        [((UIScrollView *)view) setContentOffset:CGPointMake(0, offsetY) animated:NO];
    } else {
        //普通View,监控Frame变化
    }
}

#pragma mark - Getter
- (CGFloat)contentSizeHeightForView:(UIView *)view {
    if ([view isKindOfClass:[WKWebView class]] || [view isKindOfClass:[UIWebView class]]) {
        return [((WKWebView *)view) scrollView].contentSize.height > 0 ? MAX([((WKWebView *)view) scrollView].contentSize.height, [((WKWebView *)view) scrollView].minContentSizeHeight) : [((WKWebView *)view) scrollView].preferContentSizeHeight;
    } else if (![view isKindOfClass:[UITextView class]] && [view isKindOfClass:[UIScrollView class]]) {
        return ((UIScrollView *)view).contentSize.height > 0 ? MAX(((UIScrollView *)view).contentSize.height, ((UIScrollView *)view).minContentSizeHeight) : ((UIScrollView *)view).preferContentSizeHeight;
    } else {
        //普通View,监控Frame变化
        return view.tm_height;
    }
}


@end
