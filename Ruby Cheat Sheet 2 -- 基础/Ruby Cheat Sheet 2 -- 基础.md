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



















