# TMComponentContainerView

[![CI Status](https://img.shields.io/travis/ctinusDEV/TMComponentContainerView.svg?style=flat)](https://travis-ci.org/ctinusDEV/TMComponentContainerView)
[![Version](https://img.shields.io/cocoapods/v/TMComponentContainerView.svg?style=flat)](https://cocoapods.org/pods/TMComponentContainerView)
[![License](https://img.shields.io/cocoapods/l/TMComponentContainerView.svg?style=flat)](https://cocoapods.org/pods/TMComponentContainerView)
[![Platform](https://img.shields.io/cocoapods/p/TMComponentContainerView.svg?style=flat)](https://cocoapods.org/pods/TMComponentContainerView)

## 方案问题由来
前段时间遇到一个需求：

列表上部分是一个tableView下半部分是webview,上下滚动的时候需要能完美接上。

因为苹果官方表明了，不推荐用户嵌套使用scrollView，官方属性肯定是无法完美解决了，只能自己想办法了。

### 方案调研
下面会列出几种网上找到的方案，分别介绍下优缺点。

#### 方案一:
webview放在tableview的cell中，在scrollViewDidScroll:中通过contentOffset属性来控制具体滚动的scrollView.

这个方案源代码就不列出来了，网上有一堆。说下优缺点。

优点：

上手简单，思路也比较容易理解
缺点：

要防止手势冲突需要实现tableView和webView的子类，并重载下面的方法

- (BOOL*)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer;
其中一个scrollView滑动到临界点，需要切换另一个scrollView滑动时，会出现减速效果对接不上的问题。

另外这种方案因为需要cell中的webview与tableView属性关联，或多或少会造成一些耦合。

#### 方案二:
直接将webview的frame撑满到contentSize大小

看到这个方案的时候，我是一愣，还能这么玩。于是就顺手尝试了下。核心实现逻辑就是KVO webview的contentSize,contentSize变化时reload下tableView，改变承载webview的cell的高度。

这个方案实现上是最简单的，但是debug发现webview占用的内存大大增加。原因是系统对webview做了优化，没有显示出来的部分实际不会全部渲染。但是如果将webview全部撑开了，会导致所有内容全部直接渲染。

#### 方案三:
UIKit Dynamics模仿UIScrollView。

说实话当看到这个方案时，内心确实有一种打开新世界大门的感觉。曾今一度我都准备选择这个方案了，但是当我准备上手的时候，发现scrollView的各种效果（惯性滚动, 弹性, 橡皮筋）实现起来真的是不容易了，而且还需要调整各种参数。要达到UIScrollView原生效果效果真的是不容易，最终还是选择了放弃。感兴趣的同学可以去用UIKit Dynamics模仿UIScrollView了解。

#### 方案四：
一个rootScrolleView作为最底成的scrollView，将一个contentView(UIView)放在rootScrolleView上， tableview 和webview都放在contentView上，并禁止tableView和webView的滚动。当rootScrolleView滚动时，动态调整contentView的originY或者tableView和webView的contentOffset。

方案四的缺点是计算什么时候进行contentView 的偏移？和什么时候进行tableView的contentOffset修改？是比较复杂的过程。但这也是方案四的优点，如果算法实现的足够好，可以实现多级联动的scrollView是可以没有上限的（也就是说可以做到很多个scrollview联动，甚至包括其他的UIView也可以实现联动）。

说到这里，大家应该页猜到了方案四就是我当前使用的方案，下面我用这个方案实现的一个通用的多个scrollView多级联动的方案。

1、监听UIScrollView的contentSize和bounds的变化，实时调整rootScrollView的cotnentSize和contentView中subview的originY。

注意UIScrollView需要contentSize和bounds的变化，而UIView只需要监听bounds的变化就可以了。

2、rootScrolleView在scroll过程中，需要重新计算contentView的originY和scrollView的contentOffset来保证scrollView的相应区域显示在屏幕上。


## Example
``` objc
    self.componentView = [[TMComponentContainerView alloc] init];
    
    WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 0) configuration:[[WKWebViewConfiguration alloc] init]];
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://xclient.info/s/"]]];
    webView.tm_padding = UIEdgeInsetsMake(10, 10, 10, 10);
    webView.tm_widthAdjust = TMUIWidthAdjustAutoFix;
    
    WKWebView *webView1 = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width-80, 0) configuration:[[WKWebViewConfiguration alloc] init]];
    [webView1 loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://baijiahao.baidu.com/s?id=1689828849661274143&wfr=spider&for=pc"]]];
    webView1.tm_widthAdjust = TMUIWidthAdjustAutoFix;
    
    self.componentView.componentViews = @[webView, webView1];
```
To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements
iOS9

## Installation

TMComponentContainerView is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'TMComponentContainerView'
```

## Author

ctinusDEV, 1158433594@qq.com

## License

TMComponentContainerView is available under the MIT license. See the LICENSE file for more info.
