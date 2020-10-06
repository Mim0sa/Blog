## [译] Swift | 内存安全

一般来说，Swift 会阻止代码中的不安全行为。例如，Swift 会保证变量在被使用前已经初始化，在释放某变量后其内存也会变得不可访问，以及检查数组索引是否存在越界错误。

## 前言

译自 [Swift 官方文档](https://docs.swift.org/swift-book/LanguageGuide/MemorySafety.html)，是从 [老司机周报 #130](https://juejin.im/post/6877746452706099214) 中看到的这一篇，着实解答了我的一些疑惑🎯。

