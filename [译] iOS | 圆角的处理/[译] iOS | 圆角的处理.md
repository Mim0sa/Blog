## [译] iOS | 圆角的处理

### 前言

原文出自`AsyncDisplayKit`（现在叫`Texture`）文档中的一篇关于圆角的文章：[Corner Rounding](https://texturegroup.org/docs/corner-rounding.html)

### 圆角的处理

当谈到圆角处理，许多开发人员都坚持使用`CALayer`的`.cornerRadius`属性。不幸的是，这个使用方便的属性极大地增加了性能压力，你应当在没有其他选择时才使用这个属性才对。这篇文章将涵盖：

* 为什么不应该使用`CALayer`的`.cornerRadius`
* 更多高性能的圆角设置方式以及何时使用它们
* 一张告诉你该如何选择圆角策略的流程图
* 在`Texture`中设置圆角的样例

### 设置`.cornerRadius`的代价很大

为什么`.cornerRadius`的代价很大？因为使用`CALayer`的`.cornerRadius`属性会在滚动期间为60FPS的屏幕上触发离屏渲染（offscreen rendering），即使该区域的内容没有任何改变。这意味着GPU必须在每一帧上切换上下文（context），包括合成整个帧和每次使用`.cornerRadius`所导致的附加遍历之间(?)。

重要的是，这些消耗不会显示在Time Profiler中，因为它们会影响到CoreAnimation Render Server帮助App做的工作(?)。这种莽的不行的行为消耗了许多设备的性能。在iPhone 4、4S和5 / 5C（以及类似的iPad / iPod）上，你能性能显着下降。在更新版本的iPhone上，即使你看不到直接的影响，它也会使内存空间减少，从而更容易产生掉帧的情况。

### 圆角的高性能设置策略

选择圆角设置策时只需要考虑三件事：

* 在圆角下方有移动嘛？
* 在圆角处有移动么？
* 四个圆角都属于同一个**节点**？ 并且 有没有其他**节点**在圆角区域相交？

> **译者注**：这里的**节点**指的是`AsyncDisplayKit`（`Texture`）中的最基本单位，相当于`UIKit`中的`UIView`。

在**圆角下方的移动**指的是一切在圆角图层下方的移动。例如，当一个有圆角的collection view cell在背景图层上滚动时，背景将在圆角底下移动并移出圆角。

至于**圆角处的移动**，请想象一个较小的带圆角的scroll view中包含了一张很大的图片。在scroll view内部缩放和平移图片时，图片将在scroll view的各个圆角处移动。

![corner-rounding-movement](resources/corner-rounding-movement.png)

上图将**圆角下方的移动**高亮为蓝色并且将**圆角处的移动**高亮为橙色。

> **提示**：在圆角对象内部可以有无需经过圆角的移动。下图展示了一块绿色高亮的区域，与scroll view边框有一个等同于圆角角度的内边距，当这块区域滚动时，就不算是在圆角处移动。

![corner-rounding-scrolling](resources/corner-rounding-scrolling.png)

根据上述的说法来调整你的设计，消除其中的一种圆角移动，能让你在使用快速圆角技术时和使用`.cornerRadius`时产生巨大区别(?)。

最后要考虑的是确定所有四个角是否都在同一节点，或者是否有任何子节点与圆角区域相交。

![corner-rounding-overlap](resources/corner-rounding-overlap.png)

### 预合成圆角

预合成的圆角是指使用贝塞尔曲线路径在`CGContext`/`UIGraphicsContext`中剪切内容（`path.clip`）所绘制的圆角。 在这种情况下，拐角将成为图像本身的一部分，并被整合到单个`CALayer`中。 有两种类型的预合成圆角。

最佳的方法是使用**预合成的不透明角**。这是可用的最有效方法，可以做到无Alpha混合（尽管这比起离屏渲染没那么重要），那不幸的是，这种方法最不灵活。如果圆角图像需要在某个背景上移动，则这个背景将需要为纯色才行。有一个小技巧是，你可以使用带纹理背景或照片背景来制作预合成圆角的，但通常来说你最好使用**预合成的带Alpha圆角**。

第二种方法是涉及有**预合成的带Alpha圆角**的贝塞尔曲线路径，此方法非常灵活，应该是最常用的方法之一。这个方法确实会以整个内容的大小，产生Alpha混合的消耗，并且因为Alpha通道，会比不透明的预合成增加多25％的内存消耗。但这些消耗对于现代设备来说已经很小了，并且这和启动`.cornerRadius`导致离屏渲染所产生的消耗来说根本不是一个数量级的。

预合成圆角的一个关键限制是，圆角只能接触一个节点，而不能与任何子节点相交。如果存在以上任何一种情况，则必须使用clip corner。

请注意，在`Texture`中节点对`.cornerRadius`有特殊的优化，只有当你使用了`.shouldRasterizeDescendants`后会自动实现预合成角。在启用栅格化之前，请务必仔细考虑，因此，在未完全了解该概念之前，请勿使用此选项。

> 如果你想要一个简单的，纯色的圆角矩形或圆形，`Texture`为你提供了一些便利方法。请参阅`UIImage + ASConveniences.h`，以了解使用预合成的角（支持Alpha和不透明）创建纯色、圆角可调整大小的图像的方法。这些非常适合用作ASButtonNode的背景或是图片节点的占位符。

### 切割角

该方法是将4个独立的不透明角放置在需要圆角的区域上。该方法灵活，且有很好的性能。4个独立的layer消耗较小的CPU功率，一个layer对应一个圆角。

![clip-corners](resources/clip-corners.png)

切割角主要运用于两种圆角情况：

* 圆角接触多个节点或与任何子节点相交的情况。
* 在固定的纹理或照片背景上的圆角。切割角方法很刁钻，但很有用！

### 可以使用`.cornerRadius`吗？

在很少数情况下，是适合使用`.cornerRadius`的，其中包括一个情况是一个圆角内和圆角下都需要移动的动态区域。对于某些动画，这是不可避免的。但是，在许多情况下，很容易通过调整设计来消除这样两种移动中的一种。在圆角移动一节中讨论了一种这样的情况。

当你屏幕上的内容不怎么移动时，使用`.cornerRadius`或是把它作为一个简易实现方式也没有那么糟糕。但是，当屏幕上出现了移动，即使这个移动的区域不包含圆角，也会导致额外的性能负担。例如，在导航栏中具有一个圆形元素，并在其下方有一个scroll view，即使它们不重叠，也会有影响。屏幕上的所有内容会进行动画处理，即使用户不进行交互。另外，任何形式的屏幕刷新都会消耗关于圆角切割的性能。

### 栅格化和图层支持

有人建议使用`CALayer`的`.shouldRasterize`可以提高`.cornerRadius`属性的性能。这是一个没有很好理解清楚的选择，是很危险的。当没有东西导致图层重新栅格化（没有移动，没有点击更改颜色，不在会移动的tableView上等等），就可以使用。通常，我们不鼓励这样做，因为这很容易导致性能更加下降。对于不具备出色应用程序架构并坚持使用`CALayer`的`.cornerRadius`（例如，他们的应用程序性能不佳）的用户，这可能可以带来有意义的变化。但是，如果您是从头开始构建你的app的话，我们强烈建议您选择上述更好的圆角策略之一。

`CALayer`的`.shouldRasterize`与`Texture`中节点的`.shouldRasterizeDescendents`无关。启用后，`.shouldRasterizeDescendents`将阻止子节点的实际视图和图层的创建。

### 圆角策略流程图

使用此流程图选择性能最佳的策略来解决圆角问题。

![corner-rounding-flowchart-v2](resources/corner-rounding-flowchart-v2.png)

### `Texture`的支持

以下代码举例说明了如何在`Texture`中使用圆角的不同方法：

使用`.cornerRadius`

```Swift
var cornerRadius: CGFloat = 20.0

photoImageNode.cornerRoundingType = ASCornerRoundingTypeDefaultSlowCALayer
photoImageNode.cornerRadius = cornerRadius
```

使用预合成圆角

```Swift
var cornerRadius: CGFloat = 20.0

// Use precomposition for rounding corners
photoImageNode.cornerRoundingType = ASCornerRoundingTypePrecomposited
photoImageNode.cornerRadius = cornerRadius
```

使用切割角

```Swift
var cornerRadius: CGFloat = 20.0

photoImageNode.cornerRoundingType = ASCornerRoundingTypeClipping
photoImageNode.backgroundColor = UIColor.white
photoImageNode.cornerRadius = cornerRadius
```

使用`willDisplayNodeContentWithRenderingContext`来设置某区域圆角的切割路径

```Swift
var cornerRadius: CGFloat = 20.0

// Use the screen scale for corner radius to respect content scale
var screenScale: CGFloat = UIScreen.main.scale
photoImageNode.willDisplayNodeContentWithRenderingContext = { context, drawParameters in
    var bounds: CGRect = context.boundingBoxOfClipPath()
    var radius: CGFloat = cornerRadius * screenScale
    var overlay = UIImage.as_resizableRoundedImage(withCornerRadius: radius, cornerColor: UIColor.clear, fill: UIColor.clear)
    overlay.draw(in: bounds)
    UIBezierPath(roundedRect: bounds, cornerRadius: radius).addClip()
}
```

使用`ASImageNode`来给图片加圆角和边框。这是一个给头像添加圆角的好例子。

```Swift
var cornerRadius: CGFloat = 20.0

photoImageNode.imageModificationBlock = ASImageNodeRoundBorderModificationBlock(5.0, UIColor.orange)
```















