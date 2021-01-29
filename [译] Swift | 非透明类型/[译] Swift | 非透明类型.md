# [译] Swift | 非透明类型

具有非透明返回类型的方法或者函数可以隐藏它返回值的类型信息，相较于提供一个确切的类型作为函数，它是提供一个所支持的协议来描述其返回类型。隐藏类型信息这个操作在模块和调用模块的代码之间的边界处很有用，因为返回值的基础类型可以保持私有。与返回一个协议类型不同的是，不透明类型可以保留类型标识--这样编译器可以访问类型信息，但模块的客户端不能访问。

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

你可以把非透明类型看作是范型的对立面，通用类型让调用函数的代码为该函数的参数选择类型，并以一种抽象于函数实现的方式返回某个值。例如，下面代码中的函数返回的类型取决于其调用者。

```swift
func max<T>(_ x: T, _ y: T) -> T where T: Comparable { ... }
```

调用 `max(_:_:)` 的代码为 x 和 y 选择了值，这些值的类型决定了 T 的具体类型，实际上调用的代码可以使用任何符合 `Comparable` 协议的类型。函数内部的代码是以通用的方式编写的，因此它可以处理调用者提供的任何类型，`max(_:_:)` 的实现中只使用了 `Comparable` 类型所共有的能力。

对于一个具有非透明返回类型的函数，情况是相反的。一个非透明类型能让函数实现以一种从调用函数的代码中抽象出来的方式为它返回的值选择类型。例如，下面例子中的函数返回一个梯形，但没有暴露该形状的基础类型。

```swift
struct Square: Shape {
    var size: Int
    func draw() -> String {
        let line = String(repeating: "*", count: size)
        let result = Array<String>(repeating: line, count: size)
        return result.joined(separator: "\n")
    }
}

func makeTrapezoid() -> some Shape {
    let top = Triangle(size: 2)
    let middle = Square(size: 2)
    let bottom = FlippedShape(shape: top)
    let trapezoid = JoinedShape(
        top: top,
        bottom: JoinedShape(top: middle, bottom: bottom)
    )
    return trapezoid
}
let trapezoid = makeTrapezoid()
print(trapezoid.draw())
// *
// **
// **
// **
// **
// *
```

在这个例子中 `makeTrapezoid()` 这个方法声明他的返回类型是 `some Shape`，意味着该方法会返回一个符合 `Shape` 协议的某个特定类型的值，同时又没具体指明是哪个的类型。这样写 `makeTrapezoid()` 可以让它表现其公有接口的基础信息----他的返回值是一个 `Shape`，而不需要将形状的具体类型作为其公有接口的一部分。这个方法的实现是用了两个三角形和一个正方形，但该函数也可以被重写成以各种不同方式画一个梯形，而且不会改变他的返回类型。

这个例子强调了非透明返回类型就像范型的对立面。`makeTrapezoid()` 里面的代码可以返回任何它需要的类型，只要符合 `Shape` 协议，就像调用带范型的函数代码一样。调用该函数的代码需要像实现一个带范型的函数一样，用较通用的方式来编写，这样它就可以和 `makeTrapezoid()` 返回的任何 `Shape` 值一起工作。

你也可以将非透明返回类型与范型相结合起来。以下代码中的函数都返回一个符合 `Shape` 协议的某种类型的值。

```swift
func flip<T: Shape>(_ shape: T) -> some Shape {
    return FlippedShape(shape: shape)
}
func join<T: Shape, U: Shape>(_ top: T, _ bottom: U) -> some Shape {
    JoinedShape(top: top, bottom: bottom)
}

let opaqueJoinedTriangles = join(smallTriangle, flip(smallTriangle))
print(opaqueJoinedTriangles.draw())
// *
// **
// ***
// ***
// **
// *
```

在这个例子中，`opaqueJoinedTriangles` 的值与本章前面「非透明类型解决了什么？」一节中的泛型例子的 `joinTriangles` 相同。然而，与那个示例中的不同的是，`flip(_:)` 和 `join(_:_:)` 将泛型操作返回的底层类型包裹在一个不透明的返回类型中，这就防止了这些类型的可见。这两个函数都是范用的，因为它们所依赖的类型是范型，函数的类型参数传递了 `FlippedShape` 和 `JoinShape` 所需要的类型信息。

如果一个具有非透明返回类型的函数从多个地方返回，所有可能的返回值必须具有相同的类型。对于一个范用函数，该返回类型可以使用函数的范型参数，但它仍然必须是单一具体类型。例如，这里是一个无效版本的形状翻转函数，它包含了一个翻转正方形的特殊情况：

```swift
func invalidFlip<T: Shape>(_ shape: T) -> some Shape {
    if shape is Square {
        return shape // Error: return types don't match
    }
    return FlippedShape(shape: shape) // Error: return types don't match
}
```

如果你用一个 `Square` 调用这个函数，它就返回一个 `Square`，否则，它就返回一个 `FlippedShape`。这违反了只返回一种类型的值的要求，并使 `invalidFlip(_:)` 成为无效代码。修正 `invalidFlip(_:)` 的一个方法是将正方形的特殊情况移到 `FlippedShape` 的实现中，让这个函数总是返回一个 `FlippedShape` 值：

```swift
struct FlippedShape<T: Shape>: Shape {
    var shape: T
    func draw() -> String {
        if shape is Square {
            return shape.draw()
        }
        let lines = shape.draw().split(separator: "\n")
        return lines.reversed().joined(separator: "\n")
    }
}
```

始终返回单一类型的要求并不妨碍你在非透明的返回类型中使用泛型。下面是一个函数的例子，它将其类型参数融入到返回值的基础类型中。

```swift
func `repeat`<T: Shape>(shape: T, count: Int) -> some Collection {
    return Array<T>(repeating: shape, count: count)
}
```

在这种情况下，返回值的底层类型因 `T` 而异：无论传递给它什么形状，`repeat(shape:count:)` 都会创建并返回该形状的数组。尽管如此，返回值总是具有相同的底层类型 `[T]`，因此它遵循了具有非透明返回类型的函数必须只返回单一类型的值的要求。



## 非透明类型和协议的区别















