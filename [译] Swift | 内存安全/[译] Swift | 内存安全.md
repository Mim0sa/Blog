# [译] Swift | 内存安全

一般来说，Swift 会阻止代码中的不安全行为。例如，Swift 会保证变量在被使用前已经初始化，在释放某变量后其内存也会变得不可访问，以及检查数组索引是否存在越界错误。

Swift 还通过要求修改内存中位置的代码具有对该内存的独占访问权，来确保对同一内存区域的多重访问不会产生冲突。由于 Swift 会自动管理内存，因此大多数时候你根本不需要考虑内存访问的问题。然而，了解什么地方会有潜在的内存冲突发生也是很重要的，这样你就可以避免写出对内存访问有冲突的代码。如果你的代码中确实包含冲突，则会出现编译时错误或运行时错误。

<!--more-->

> 译自 [Swift 官方文档](https://docs.swift.org/swift-book/LanguageGuide/MemorySafety.html)，是从 [老司机周报 #130](https://juejin.im/post/6877746452706099214) 中看到的这一篇，着实解答了我的一些疑惑🎯。



## 理解关于内存的访问冲突

当你执行设置变量的值、将参数传递给函数之类的代码时，访问内存这件事情会就发生。举个例子，以下代码包含了一个读取操作和一个访问操作：

```swift
// A write access to the memory where one is stored.
var one = 1

// A read access from the memory where one is stored.
print("We're number \(one)!")
```

当不同部分的代码试图同时访问同一块内存时，可能会发生内存冲突访问。 同时访问同一块内存可能会导致不可预测或不一致的行为。 在 Swift 中，有多种方法可以实现在跨越好几行代码的过程下修改某个值，这导致可以实现在修改自身的过程中去尝试访问自己的值。

现在通过一个相似的问题来更好地帮助你理解这种冲突，例如你现在要在一张纸上更新你的购物预算清单。更新这张预算清单分为两个步骤：1.你需要添加商品的名称和价格，2.你需要更改总价来匹配你更新后的账单。在这个更新步骤的前后，你都可以从账单中正确的读取任何数据，如下图所示。

![memory_shopping](resources/memory_shopping.png)

当你往清单中添加商品时，清单处于一个临时的、无效的状态，因为这时总价还没有被更新、还不能反映那些新加的商品。所以当你在添加商品的过程中，读取总价格的话，会给你一个错误的答案。

这个例子同样也展示了在解决冲突访问时你可能会遇到的问题：不一样解决冲突方式会带来不一样的答案，要知道哪个答案是正确的通常来说没有那么显而易见。在这个例子中，主要看你是想要原来的总价格还是更新后的总价格，$5 和 $320 都可能是正确答案。也就是说，在你解决冲突访问之前，你得先要搞清楚你要的是什么。

> 注意
>
> 如果你是在编写有关并发或多线程的代码，那么内存访问冲突可能是一个常见的问题。但要注意的是，我们在这讨论的冲突访问是可能发生在单线程上，并且不涉及并发或多线程代码。
>
> 如果你在单线程中对内存的访问存在冲突，Swift 会确保在编译时或运行时报错。对于多线程代码，请使用  Thread Sanitizer 来检测多线程的冲突访问。



## 冲突访问的特征

在冲突访问的时候，有三个访问的特征值得注意：1.这个访问操作是读还是写，2.访问的时常，3.具体访问的位置。具体来说，如果你有两个满足了以下所有条件的访问操作，那么他们是会发生冲突的：

* 他们之中至少一个是写入操作或非原子（nonatomic）操作。
* 他们访问了内存中的相同位置。
* 它们的持续时间是有重叠的。

通常来说，一个读取访问和一个写入访问的区别是很明显的：一个写入访问会改变内存中的位置，但读取访问不会。内存中的位置是指要访问的内容，例如：变量、常量或属性。内存访问可以是瞬时的，也可以是维持一段时间的。

如果你的一个操作仅使用了 C 原子（atomic）操作，则该操作是原子操作，否则就是非原子的。有关这些功能，详见 stdatomic（3）手册页。

如果你的某个访问在开始之后和结束之前都无法运行其他代码，那么这个访问就是一个瞬时访问。从本质上来说，两个瞬时访问是不能在同一时间发生的。并且，大多数内存访问操作都是瞬时的。举个例子，以下代码中读取和写入访问都是瞬时的：

```swift
func oneMore(than number: Int) -> Int {
    return number + 1
}

var myNumber = 1
myNumber = oneMore(than: myNumber)
print(myNumber)
// Prints "2"
```

然而，还有那么几种访问内存的方式，被称作长期访问（long-term accesses），这种访问方式会涵盖其他代码的执行时机。瞬时访问和长期访问之间的区别在于，其他代码可以在一个长期访问期间（开始之后至结束之前）运行，这就叫重叠（overlap）。长期访问可以与其他长期访问重叠，也可以和瞬时访问重叠。

重叠访问主要出现在用了 in-out 参数的函数和方法中、或是出现在结构体的 mutating 方法中。在下面的几个部分中会讨论使用长期访问的特定类型 Swift 代码。



## In-Out 参数的访问冲突

一个函数对其所有 in-out 参数具有长期写入访问（long-term write access）的能力。In-out 参数的写入访问是等所有非 in-out 参数被评估(?)之后才开始，并且将持续该函数调用的整个过程。如果有多个 in-out 参数，则写入访问的开始顺序与参数出现的顺序相同。

使用这种长期写入访问的一个后果是，你不可以访问以 in-out 形式传递的原始变量（即使从范围规则和访问控制的角度来说这样是允许的），任何对原始变量的访问都会导致冲突的发生。下面举个例子：

```swift
var stepSize = 1

func increment(_ number: inout Int) {
    number += stepSize
}

increment(&stepSize)
// Error: conflicting accesses to stepSize
```

在上面的代码中，`stepSize` 是一个全局变量，正常来说我们可以在 `increment(_:)` 内访问他。然而，对 `stepSize` 的读取访问和对 `number` 的写入访问重叠了。如下图所示，`number` 和 `stepSize` 都指向内存中的同一位置， 读取和写入访问引用相同的内存，并且它们重叠，从而产生了冲突。

![memory_increment](resources/memory_increment.png)

解决这种冲突的一个办法是显式复制 `stepSize`：

```swift
// Make an explicit copy.
var copyOfStepSize = stepSize
increment(&copyOfStepSize)

// Update the original.
stepSize = copyOfStepSize
// stepSize is now 2
```

当你在调用 `increment(_:)` 之前就复制 `stepSize` 的话，很明显 `copyOfStepSize` 会在当前基础上增加。读取访问在写入访问开始之前结束，因此没有冲突。

另一个对 in-out 函数使用长期访问会产生的问题是，当你将单个变量作为同一函数的多个 in-out 参数来传递时，会产生冲突。举个例子：

```swift
func balance(_ x: inout Int, _ y: inout Int) {
    let sum = x + y
    x = sum / 2
    y = sum - x
}
var playerOneScore = 42
var playerTwoScore = 30
balance(&playerOneScore, &playerTwoScore)  // OK
balance(&playerOneScore, &playerOneScore)
// Error: conflicting accesses to playerOneScore
```

上述 `balance(_:_:)` 函数的作用是修改两个参数的值以让他们平均分配，使用 `playerOneScore` 和 `playerTwoScore` 作为参数时不会产生冲突（虽然它们有两个时间重叠的写入访问，但是他们访问的是内存中的不同位置）。相反，将 `playerOneScore` 作为两个参数的值传递会产生冲突，因为它试图同时对内存中的同一位置执行两次写入访问。

> 注意
>
> 因为运算符也是函数，所以他们也可以进行带有 in-out 参数的长期访问。 例如，如果 `balance(_:_:)` 是名为 <^> 的运算符，则编写 `playerOneScore <^> playerOneScore` 将产生与 `balance(&playerOneScore, &playerOneScore)`一样的冲突错误。



## 在函数中访问自身导致的冲突

一个结构体中的 `mutating` 方法被调用期间，他是可以对它的 `self` 进行写入访问的。例如，有一个游戏中，每个玩家受伤时健康值会减少，在用技能时能量值会减少。

```swift
struct Player {
    var name: String
    var health: Int
    var energy: Int

    static let maxHealth = 10
    mutating func restoreHealth() {
        health = Player.maxHealth
    }
}
```

在上面的 `restoreHealth()` 方法中，对 `self` 的写入访问从该方法的开头开始，一直持续到该方法返回为止。在这种情况下，`restoreHealth()` 中没有其他代码可以重叠访问 `Player` 实例的属性。而下面的 `shareHealth(with:)` 方法将另一个 `Player` 实例用作 in-out 参数，从而可能导致访问重叠。

```swift
extension Player {
    mutating func shareHealth(with teammate: inout Player) {
        balance(&teammate.health, &health)
    }
}

var oscar = Player(name: "Oscar", health: 10, energy: 10)
var maria = Player(name: "Maria", health: 5, energy: 10)
oscar.shareHealth(with: &maria)  // OK
```

在上面的示例中，调用 `Oscar` 与 `Maria` 共享生命值的 `shareHealth(with:)` 方法不会引起冲突。 在方法调用过程中，对 `oscar` 有写入访问，因为 `oscar` 是 mutating 方法中 `self` 的值，并且与 `maria` 的写入访问的持续时间是一致的，因为 `maria` 是作为 in-out 参数传递的。 如下图所示，你可以看到它们访问内存中的不同位置。 所以即使两个写访问在时间上重叠，也不会冲突。

![memory_share_health_maria](resources/memory_share_health_maria.png)

但是，如果你传递一个 `oscar` 作为 `shareHealth(with:)` 的参数，就会产生冲突：

```swift
oscar.shareHealth(with: &oscar)
// Error: conflicting accesses to oscar
```

这个 mutating 方法需要在方法持续时间内对 `self` 进行写入访问，而 in-out 参数需要在相同持续时间内对 `teammate` 进行写入访问。 在该方法中，自己和队友都指向内存中的同一位置--如下图所示。 这两个写入访问引用相同的内存，并且它们重叠，从而产生了冲突。

![memory_share_health_oscar](resources/memory_share_health_oscar.png)



## 访问属性时的冲突

类似于结构体、枚举和元组这些类型都是由堵路的组合值组成的，例如结构体的属性，或者是元组的元素。因为这些都是值类型，所以对值类型的任何部分的修改都会使整个值发生更改，这意味着对某一个属性的读取或者写入操作是需要去对整个值读取或者写入。例如，对元组元素的重叠写入访问会产生冲突：

```swift
var playerInformation = (health: 10, energy: 20)
balance(&playerInformation.health, &playerInformation.energy)
// Error: conflicting access to properties of playerInformation
```

在上述的例子中，对元组的元素调用 `blance(_:_:)` 会产生冲突，这是因为他们在对 `playerInformation` 的写入访问存在重叠。`playerInformation.health` 和 `playerInformation.energy` 都是作为 in-out 参数被传入的，这意味着 `balance(_:_:)` 需要在函数调用期间对其进行写入访问。在这两种情况下，对元组元素的写入访问都需要对整个元组区进行写入访问。那就是说有两个对 `playerInformation` 的写入访问，并且持续时间重叠，从而导致冲突。

下面的代码展示了一个类似的错误，出现在对一个全局变量结构体的属性进行重叠写入访问。

```swift
var holly = Player(name: "Holly", health: 10, energy: 10)
balance(&holly.health, &holly.energy)  // Error
```

事实上，对结构属性的大多数重叠访问都是安全的。 例如，如果在上面的示例中将变量 `holly` 更改为局部变量而不是全局变量，则编译器是正常工作的，证明了对结构体的存储属性的重叠访问是安全的：

```swift
func someFunction() {
    var oscar = Player(name: "Oscar", health: 10, energy: 10)
    balance(&oscar.health, &oscar.energy)  // OK
}
```

在上面的示例中，`Oscar` 的 `health` 和 `energy` 作为两个 in-out 参数传递给了 `balance(_:_:)`。编译器可以证明这样是内存安全的，这两个存储的属性不会以任何方式交互。

在保护内存安全时，限制结构体属性的重复访问并非是必须的。内存安全是理想的保证，但是独占访问是一个比内存安全更严格的要求--这意味着即使有一些代码违反了独占访问的要求，它也可以是符合内存安全的要求的。如果编译器可以证明对内存的非独占访问仍然是安全的，则 Swift 允许使用这种仅做到了内存安全的代码。特别指出，如果满足以下条件，那就可以证明重叠访问某结构体的属性是安全的：

* 你只访问了实例的存储属性，而不是计算属性或类属性。
* 这个结构体是局部变量而不是全局变量。
* 这个结构体要么没有被任何闭包捕获，要么只被非逃逸闭包捕获。

如果编译器无法证明这个访问是安全的，则它是不被允许进行访问的。



