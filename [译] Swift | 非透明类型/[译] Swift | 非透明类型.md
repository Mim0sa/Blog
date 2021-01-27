# [译] Swift | 非透明类型

具有非透明返回类型的方法或者函数可以隐藏它返回值的类型信息，相较于提供一个确切的类型作为函数，它是提供一个所支持的协议来描述其返回类型。隐藏类型信息这个操作在模块和调用模块的代码之间的边界处很有用，因为返回值的底层类型可以保持私有。与返回一个协议类型不同的是，不透明类型可以保留类型标识--这样编译器可以访问类型信息，但模块的客户端不能访问。

<!--more-->

> 本文译自 [Swift 官方文档](https://docs.swift.org/swift-book/LanguageGuide/OpaqueTypes.html)，解答了我在 SwiftUI 中遇到的 `some View` 时产生的疑惑，并阐述了非透明类型与范型、协议的联系和区别。



## 非透明类型解决了什么？

举个例子，假设你正在编写一个绘制 ASCII 艺术形状的模块，ASCII 艺术形状的基本特征可以用一个 `draw()` 函数来表示，这个函数会返回该艺术形状的 string 表现。你可以用这个函数作为 `Shape` 协议的一个要求：

```swift
protocol Shape {
    func draw() -> String
}

struct Triangle: Shape {
    var size: Int
    func draw() -> String {
        var result = [String]()
        for length in 1...size {
            result.append(String(repeating: "*", count: length))
        }
        return result.joined(separator: "\n")
    }
}
let smallTriangle = Triangle(size: 3)
print(smallTriangle.draw())
// *
// **
// ***
```

你可以使用泛型来实现像垂直翻转这样的操作，如下面的代码所示。然而，这种方法有一个重要的限制：翻转结果会暴露用于创建它的确切的泛型类型。

```swift
struct FlippedShape<T: Shape>: Shape {
    var shape: T
    func draw() -> String {
        let lines = shape.draw().split(separator: "\n")
        return lines.reversed().joined(separator: "\n")
    }
}
let flippedTriangle = FlippedShape(shape: smallTriangle)
print(flippedTriangle.draw())
// ***
// **
// *
```

像这样定义 `JoinShape<T: Shape, U: Shape>` 结构体，可以将两个形状垂直连接在一起，就像下面的代码所示，结果是将一个翻转的三角形与另一个三角形连接在一起的 `JoinShape<FlippedShape<Triangle>, Triangle>` 这样的类型。

```swift
struct JoinedShape<T: Shape, U: Shape>: Shape {
    var top: T
    var bottom: U
    func draw() -> String {
        return top.draw() + "\n" + bottom.draw()
    }
}
let joinedTriangles = JoinedShape(top: smallTriangle, bottom: flippedTriangle)
print(joinedTriangles.draw())
// *
// **
// ***
// ***
// **
// *
```

暴露创建形状的详细信息，会使那些本不属于 ASCII 艺术形状模块公共接口的类型，因为函数需要说明完整的返回类型而泄露出来。模块内部的代码可以用各种方式建立同一个形状，模块外部使用该形状的其他代码不应该需要说明关于变换列表的实现细节。像 `JoinShape` 和 `FlippedShape` 这样的包装类型对模块的使用者来说并不重要，它们不应该是可见的。该模块的公共接口包括加入和翻转形状等操作，这些操作应该会返回另一个 `Shape` 值。



## 返回一个非透明类型



















