# Ruby Cheat Sheet 2 -- 基础

## Ruby 的基础

### 「4」对象、变量和常量

常量、局部变量与全局变量：

```ruby
T = 1   # 常量
x = 0   # 局部变量
$x = 0  # 全局变量
```

多重赋值的使用：

```ruby
a, b, c = 1, 2, 3
a, *b, c = 1, 2, 3, 4, 5 
#=> 1, [2, 3, 4], 5

a, b = b, a  # swap

ary = [1, 2]
a, b = ary  #=> a = 1, b = 2
a, = ary    #=> a = 1
```

### 「5」条件判断

Ruby 中可以作为条件判断的方法：

```ruby
p "".empty?   #=> true
p "A".empty?  #=> false
p /Ruby/ =~ "HiRuby"   #=> 2
p /Ruby/ =~ "Diamond"  #=> nil
```

> 在 Ruby 中除了 `false` 和 `nil` 以外的值都是代表「真」。

> 在 Ruby 中有个约定俗成的规则，返回真假值的方法都要以 `?` 结尾。

`if` 语句的简单使用：

```ruby
a, b = 10, 20
if a > b
  puts "a > b"
elsif a < b
  puts "a < b"
else
  puts "a = b"
end
```

`unless` 语句的简单使用：

```ruby
a, b = 10, 20
unless a > b
  puts "a <= b"
end
```

`case` 语句的简单使用：

```ruby
tags = ["A", "B", "C"]
tags.each do |tag|
	case tag
	when "A"
		puts "A"
	when "B"
		puts "B"
	else
		puts "C"
	end
end
		

ary = ["a", 1, nil]
ary.each do |item|
	case item
	when String
		puts "String"
	when Numeric
		puts "Numeric"
	else
		puts "Somrthing"
	end
end

text = ""
text.each_line do |line|
	case line
	when /^From:/i
		puts "From"
	when /^To:/i
		puts "To"
	when /^Subject:/i
		puts "Subject"
	when /^$/
		puts "Finshed"
		exit
	else
		## jump out
	end
end
```

> `case` 语句实际上是用 `===` 来进行判断的，其比 `==` 的判断内容要更宽泛一些。

> Ruby 中的对象都有一个 `object_id`，可以使用 `equal?` 来比较两个对象是否相等。

### 「6」循环

times 方法

```ruby
5.times do |i|
  puts "第#{i + 1}次循环"
end
```

for 语句

```ruby
name = ["M", "i", "m", "0", "s", "a"]
for char in name do 
  puts char
end
```

while 语句

```ruby
i = 1
while i < 3 do
  puts i
  i += 1
end
```

until 语句

```ruby
i = 1
until i > 3 do
  puts i
  i += 1
end
```

each 方法

```ruby
(1...5).each do |i|
  puts i
end
```

loop 方法

```ruby
loop do
  puts "Ruby"
end
```

循环控制

```ruby
break next redo
```

### 「7」方法

按接收者的种类不同，Ruby 的方法可以分为三类：

* 实例方法
* 类方法
* 函数式方法

>  调用类方法时，可以使用 `::` 代替 `.`

```ruby
def hello(name)
  puts "Hello, #{name}"
end
```

定义带块的方法：

```ruby
def myLoop
  while true
    yield
  end
end

num = 1
myLoop do 
  puts "num is #{num}"
  break if num > 10
  num *= 2
end
```

带关键字参数的方法：

 ```ruby
def meth(x: 0, y: 0, z: 0, **args)
  [x, y, z, args]
end

p meth(x: 3, y: 4, z: 5, v: 6, w: 7)
#=> [3, 4, 5, {:v=>6, :w=>7}]
 ```

### 「8」类和模块

判断某个对象是否属于某个类时：

```ruby
ary = []
p ary.instance_of?(String)
#=> false
p ary.is_a?(Object)
#=> true
```

创建一个类：

```ruby
class HelloWorld
  def initialize(myname = "Ruby")
    @name = myname
  end
  
  def hello
    puts "Hello, world. I am #{@name}."
  end
end

bob = HelloWorld.new("Bob")
ruby = HelloWorld.new("Alice")
bob.hello
```

Ruby 中的存取器：

```ruby
def name
  @name
end

def name=(value)
    @name = value
end
```

为了方便，我们可以用以下来代替存取方法的实现：

| 定义                | 意义                     |
| :------------------ | :----------------------- |
| attr_reader :name   | 只读（定义 name 方法）   |
| attr_writer :name   | 只写（定义 name= 方法）  |
| attr_accessor :name | 读写（定义以上两个方法） |

```ruby
class HelloWorld
  attr_accessor :name
end
```

类方法：

```ruby
class << HelloWorld
  def hello(name)
    puts "#{name} said hello."
  end
end
# 单例类定义
HelloWorld.hello("John") #=> John said hello.

# 也可以这样写
class HelloWorld
  class << self
    def hello(name)
      puts "#{name} said hello."
    end
  end
end

# 或这样
def HelloWorld.hello(name)
  puts "#{name} said hello."
end

# 或这样
class HelloWorld
  def self.hello(name)
    puts "#{name} said hello."
  end
end
```

类中的常量：

```ruby
class Hello
  Version = "1.0"
end

p Hello::Version  #=> "1.0"
```

类变量：

```ruby
class HelloCount
  @@count = 0
  
  def HelloCount.count
    @@count
  end
  
  def initialize(myname = "Ruby")
    @name = myname
  end
  
  def hello
    @@count += 1
    puts "Hello, world. I am #{@name}."
  end
end

p HelloCount.count           #=> 0
bob = HelloCount.new("Bob")
ruby = HelloCount.new()
bob.hello
ruby.hello
p HelloCount.count           #=> 2
```

 限制方法的调用：

```ruby
public private protected
# private 和 protected 的区别很有意思
```















