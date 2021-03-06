## [译] iOS | 官方文档 | 使用响应者和响应者链处理事件

### 前言

本文译自：[Using Responders and the Responder Chain to Handle Events](https://developer.apple.com/documentation/uikit/touches_presses_and_gestures/using_responders_and_the_responder_chain_to_handle_events)

### 概览

App 使用响应者对象接收和处理事件。一个响应者对象可以是`UIResponder`类的任何实例，常见的子类包括`UIView`，`UIViewController`和`UIApplication`。响应者接收原始事件数据，并且一定会处理事件或将其发送给另一个响应者对象。当 app 接收到事件时，`UIKit`会自动将该事件定向到最合适的响应者对象，即第一响应者（*the first responder*）。

未处理的事件会在一个活动的响应者链中，从一个响应者传递到另一个响应者，这是响应者对象的动态配置(?)。 下图显示了一个 app 中的响应者，该程序的界面包含一个`UILabel`，一个`UITextField`，一个`UIButton`和两个背景`UIView`。 该图还显示了事件如何沿着响应者链从一个响应者转移到下一个响应者。

![Responder chains in an app](resources/ResponderChainsInAnApp.png)

如果`UITextField`不处理事件，则`UIKit`会将事件发送到`UITextField`的父视图，然再接下来会发送到`UIWindow`的根视图。从根视图开始，响应程序链在将事件定向到`UIWindow`之前转移到当前持有的`UIViewController`。如果`UIWindow`无法处理事件，则`UIKit`会将事件传递给`UIApplication`对象，如果该对象是`UIResponder`的实例并且还不是响应者链的一部分，则可能传递给*app delegate*(?)。

### 确定一个事件的第一响应者

`UIKit`是根据事件的类型将对象指定为该事件的第一响应者。事件类型包括：

事件类型              | 第一响应者   
--------------------- | --------------------------
Touch events          | 发生触摸的视图
Press events          | 被 focus 的对象
Shake-motion events   | 你（或`UIKit`）指定的对象
Remote-control events | 你（或`UIKit`）指定的对象
Editing menu messages | 你（或`UIKit`）指定的对象

> **注意** 
>
> 与加速度计，陀螺仪和磁力计有关的运动事件不遵循响应程序链。 相反，Core Motion 会将这些事件直接传递到指定的对象。 有关更多信息，请参见 Core Motion 框架。

控件使用*action*信息直接与其关联的目标对象进行通信。当用户与控件交互时，控件会将*action*信息发送到其*target*对象。*action*消息不是事件，但是它们仍然可以利用响应者链。当控件的目标对象为`nil`时，`UIKit`从目标对象开始并遍历响应程序链，直到找到实现适当操作方法的对象为止。例如，`UIKit`编辑菜单使用此行为来搜索响应者对象，这些对象实现了诸如`cut（_ :)`，`copy（_ :)`或`paste（_ :)`之类的方法。

手势识别器（*Gesture recognizers*）会比相关视图先接收触摸和按下事件。如果视图的手势识别器无法识别一系列触摸，则`UIKit`会将触摸发送到视图。 如果视图无法处理触摸，`UIKit`会将它们向上传递到响应者链。 有关使用手势识别器处理事件的更多信息，请参见处理`UIKit`手势。

### 确定是哪个响应者包含了触摸事件

UIKit使用基于视图的命中测试（*hit-testing*）来确定触摸事件发生的位置。具体来说，UIKit将触摸位置与视图层次结构中视图对象的边界（*bounds of view objects*）进行比较。`UIView`的`hitTest（_：with :)`方法会遍历视图层次结构，查找包含指定触摸的最深子视图，该子视图成为触摸事件的第一响应者。

> **注意** 
>
> 如果触摸位置在视图范围（*a view’s bounds*）之外，则`hitTest（_：with :)`方法将忽略该视图及其所有子视图。因此，如果视图的`clipsToBounds`属性为`false`，即使该视图恰好包含触摸，也不会返回该视图范围之外的子视图。有关命中测试（*hit-testing*）行为的更多信息，请参见`UIView`中有关`hitTest（_：with :)`方法的讨论。

发生触摸时，`UIKit`将创建一个`UITouch`对象并将其与视图关联。 随着触摸位置或其他参数的更改，`UIKit`会使用新信息更新那个`UITouch`对象。 唯一不变的属性是那个关联的视图。 （即使触摸位置移到原始视图之外，触摸的视图属性中的值也不会更改。）触摸结束时，`UIKit`会释放`UITouch`对象。

### 改变响应者链

您可以通过覆盖响应者对象的`next`（指响应链中下一个响应者）属性来更改响应者链。

许多`UIKit`类已经重写此属性并返回特定的对象，包括：

* `UIView`，如果视图是`UIViewController`的根视图，则下一个响应者是`UIViewController`。否则，下一个响应者是视图的父视图。

* `UIViewController`

    * 如果`UIViewController`的视图是`UIWindow`的根视图，则下一个响应者是`UIWindow`对象。
    
    * 如果`UIViewController`是由另一个`UIViewController`呈现的，则下一个响应者是第二个视图控制器。
    
* `UIWindow`，窗口的下一个响应者是`UIApplication`对象。

* `UIApplication`，下一个响应者是`app delegate`。但仅当该`app delegate`是`UIResponder`的实例且不是视图、`UIViewController`或app对象本身时，才是下一个响应者。

### 后记

这篇文档讲得很浅，同时也讲的不怎么容易懂，想要更深入理解响应链及手势相关内容还是需要阅读更多其他优秀资料。