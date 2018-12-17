# Ruby Metaprogramming Gist

## What is Metaprogramming in Ruby
* In many programming languages, language constructs behave more like
ghosts than fleshed-out citizens: you can see them in your source code, but
they disappear before the program runs. Take C++, for example. Once the
compiler has finished its job, things like variables and methods have lost their
concreteness; they are just locations in memory. You can’t ask a class for its
instance methods, because by the time you ask the question, the class has
faded away. In languages such as C++, runtime is an eerily quiet place—a
ghost town.
* In other languages, such as Ruby, runtime is more like a busy marketplace.
Most language constructs are still there, buzzing all around. You can even
walk up to a language construct and ask it questions about itself. This is
called introspection.

## Introspection: Get Instance Variables and Methods:
```ruby
class Greeting
  def initialize(text)
    @text = text
  end

  def welcome
    @text
  end
end

my_object = Greeting.new("Hello")

my_object.class # => Greeting

# The false argument means: 
# List only instance methods you defined yourself,
not those ones you inherited.
my_object.class.instance_methods(false) # => [:welcome]

# All class methods
my_object.methods

my_object.instance_variables # => [:@text]

Greeting.ancestors # => [Greeting, Object, Kernel, BasicObject]

```

## Open Class
Reopen an existing class and add methods to it.

```ruby
class D
  def x; 'x'; end
end
class D
  def y; 'y'; end
end

obj = D.new
obj.x # => "x"
obj.y # => "y"

# Ruby steps in and defines the class—and the x method. At the second mention, class D already exists so Ruby doesn’t need to define it. Instead, it reopens the existing class and defines a method named y there.
```


```ruby
# Money Gem
# object_model/money_example.rb

# Before
require "money"
bargain_price = Money.from_numeric(99, "USD")
bargain_price.format # => "$99.00"

# After
require "money"
standard_price = 100.to_money("USD")
standard_price.format # => "$100.00"
```

## Monkey Patch

```ruby
# This is the dark side to Open Classes: if you casually add bits and pieces of functionality to classes, you can end up with bugs like overriding. Some people would frown upon this kind of reckless patching of classes, and they would refer to the previous code with a derogatory name: they’d call it a Monkeypatch.

class Array
  def replace(original, replacement)
    self.map {|e| e == original ? replacement : e }
  end
end

# Method Lookup
[].methods.grep /^re/ # => [:reverse_each, :reverse, ..., :replace, ...]
```

## Instance Variables and Objects
An object’s instance variables live in the object itself, and an object’s methods live in the object’s class. That’s why objects of the same class share methods but don’t share instance variables.

## Ruby Classes
A class is a module with three additional instance methods ( new , allocate , and superclass ) that allow you to create objects or arrange classes into hierarchies.
* Every Class in Ruby is object ```Array.class #=> Class```
* Every Class is also a module ```Class.superclass #=> Module```

## Modules and Lookup

```ruby
# object_model/modules_include.rb

module M1
  def my_method
    'M1#my_method()'
  end
end

class C
  include M1
end

class D < C; end

D.ancestors # => [D, C, M1, Object, Kernel, BasicObject]
```

## Ruby Refinements
```ruby
# object_model/refinements_in_file.rb

module StringExtensions
  refine String do
    def to_alphanumeric
      gsub(/[^\w\s]/, '')
    end
  end
end
```

To activate the changes, you have to do so explicitly, with the using method:
```using StringExtensions```

```ruby
# Starting from Ruby 2.1, you can even call using inside a module definition

module StringStuff
  using StringExtensions
  "my *1st* refinement!".to_alphanumeric # => "my 1st refinement"
end
```
Points to note:
* You can call refine in a regular module, but you cannot call it in a class, even if a class is itself a module.
* Metaprogramming methods such as methods and ancestors ignore Refinements altogether
* Introducted in Ruby 2
* Refinements have the potential to eliminate dangerous Monkeypatches, but it will take some time for the Ruby community to understand how to use them best.

Include/Prepend - Order of execution
```ruby
module Printable
  def print
    puts 'print from Printable'
  end

  def prepare_cover
    # puts 'prepare_cover'
  end
end

module Document
  def print_to_screen
    prepare_cover
    format_for_screen
    print
  end

  def format_for_screen
    # puts 'format_for_screen'
  end

  def print
    puts 'print from Document'
  end
end

class Book_1
  prepend Printable
  prepend Document
end

class Book_2
  prepend Printable
  prepend Document

  def print 
    puts 'print from Book_2'
  end
end

class Book_3
  include Printable
  include Document

  def print 
    puts 'print from Book_3'
  end
end

class Book_4
  include Printable
  include Document
end

class Book_5
  include Document
  include Printable
end

Book_1.new.print_to_screen # => print from Document
Book_2.new.print_to_screen # => print from Document
Book_3.new.print_to_screen # => print from Book_3
Book_4.new.print_to_screen # => print from Document
Book_5.new.print_to_screen # => print from Printable

# use ancestors method to find the hierarchy or order of execution. The first find method will be called in all the cases
# e.g: Book_1.ancestors
```

## Dynamic Dispatch - technique