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
<br><br>

### Introspection: Get Instance Variables and Methods:
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
<br>

### Open Class
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
<br>

### Monkey Patch

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
<br>


### Instance Variables and Objects
An object’s instance variables live in the object itself, and an object’s methods live in the object’s class. That’s why objects of the same class share methods but don’t share instance variables.
<br>


### Ruby Classes
A class is a module with three additional instance methods ( new , allocate , and superclass ) that allow you to create objects or arrange classes into hierarchies.
* Every Class in Ruby is object ```Array.class #=> Class```
* Every Class is also a module ```Class.superclass #=> Module```
<br><br>

### Modules and Lookup

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
<br>

### Ruby Refinements
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
<br>

### Static Type Checking/Static Languages:
In languages like Java and C, for every method call, the compiler checks to see that the receiving object has a matching method. This is called static type checking, and the languages that adopt it are called static languages.

Dynamic languages—such as Python and Ruby—don’t have a compiler policing method calls.

Static languages often require you to write lots of tedious, repetitive methods—the so-called boilerplate methods—just to make the compiler happy. (For example, get and set methods to access an object’s properties, or scores of methods that do nothing but delegate to some other object.)
<br><br><br><br><br>

## Dynamic Methods

```ruby
class MyClass
  def my_method(my_arg)
    my_arg * 2
  end
end
obj = MyClass.new
obj.my_method(3) # => 6


obj.send(:my_method, 3) # => 6
```
<br>

### Dynamic Dispatch Technique: ```send```
With ```send```, the name of the method that you want to call becomes just a regular argument. You can wait literally until the very last moment to decide which method to call, while the code is running. This technique is called <b>Dynamic Dispatch</b>, and you’ll find it wildly useful.

```ruby
# gems/pry-0.9.12.2/lib/pry/pry_instance.rb

def refresh(options={})
  defaults = {}
  attributes = [ :input, :output, :commands, :print, :quiet, :exception_handler, :hooks, :custom_completions, :prompt, :memory_size, :extra_sticky_locals ]

  attributes.each do |attribute|
    defaults[attribute] = Pry.send attribute
  end
  
  defaults.merge!(options).each do |key, value|
    send("#{key}=", value) if respond_to?("#{key}=")
  end
  true
end

# The Kernel#respond_to? method returns true if methods such as Pry#memory_size= actually exist, so that any key in options that doesn’t match an existing attribute will be ignored.
```

The Object#send method is very powerful—perhaps too powerful. In particular, you can call any method with send, including <b>private</b> methods.
<br><br>

### Defining Methods Dynamically: ```define_method```
```ruby
# methods/dynamic_definition.rb

class MyClass
  define_method :my_method do |my_arg|
    my_arg * 3
  end
end

obj = MyClass.new
obj.my_method(2) # => 6

require_relative '../test/assertions'
assert_equals 6, obj.my_method(2)
```
There is one important reason to use ```define_method``` over the more familiar ```def``` keyword: ```define_method``` allows you to decide the name of the defined method at runtime.

```ruby
# methods/computer/more_dynamic_methods.rb

class Computer
  def initialize(computer_id, data_source)
    @id = computer_id
    @data_source = data_source
  ➤ data_source.methods.grep(/^get_(.*)_info$/) { Computer.define_component $1 }
  end

  def self.define_component(name)
    define_method(name) do
      # ...
    end
  end
end

```
<br/>

### ```BasicObject#method_missing```
It is a private instance method of ```BasicObject``` that every object inherits

```ruby
# Calling private method method_missing manually using send

nick.send :method_missing, :my_method # => NoMethodError: undefined method `my_method' for ...

# BasicObject#method_missing responded by raising a NoMethodError
```

#### Overriding ```method_missing```
Overriding ```method_missing``` allows you to call methods that don’t really exist.

```ruby
# methods/more_method_missing.rb

class Lawyer
  def method_missing(method, *args)
    puts "You called: #{method}(#{args.join(', ')})"
    puts "(You also passed it a block)" if block_given?
  end
end

bob = Lawyer.new
bob.talk_simple('a', 'b') do
  # a block
end

# => You called: talk_simple(a, b)
# => (You also passed it a block)
```
<br>

### Ghost Methods
Dynamic methods defined under ```method_missing``` can be called as Ghost Methods. Methods that don't have a static definition

```ruby
# gems/hashie-1.2.0/lib/hashie/mash.rb

module Hashie
  class Mash < Hashie::Hash
    def method_missing(method_name, *args, &blk)
      return self.[](method_name, &blk) if key?(method_name)
      match = method_name.to_s.match(/(.*?)([?=!]?)$/)
      case match[2]
        when "="
          self[match[1]] = args.first
          # ...
        else
          default(method_name, *args, &blk)
      end
    end
    # ...
  end
end

require 'hashie'

icecream = Hashie::Mash.new
icecream.flavor = "strawberry"

icecream.flavor # => "strawberry"

# This works because Hashie::Mash is a subclass of Ruby’s Hash, and its attributes are actually Ghost Methods, as a quick look at Hashie::Mash.method_missing
```
<br>

### Dynamic Proxies
An object such as ```Ghee::ResourceProxy```, which catches Ghost Methods and forwards them to another object, is called a Dynamic Proxy.

```ruby
# The Ghee Example

# methods/ghee_example.rb
require "ghee"
gh = Ghee.basic_auth("usr", "pwd") # Your GitHub username and password
all_gists = gh.users("nusco").gists
a_gist = all_gists[20]
a_gist.url # => "https://api.github.com/gists/535077"
a_gist.description # => "Spell: Dynamic Proxy"
a_gist.star

# The code above connects to GitHub, looks up a specific user ( "nusco" ), and accesses that user’s list of gists. Then it selects one specific gist and reads that gist’s url and description . Finally, it “stars” the gist, to be notified of any future changes.
```

```ruby
# gems/ghee-0.9.8/lib/ghee/resource_proxy.rb
class Ghee
  class ResourceProxy
    # ...
    def method_missing(message, *args, &block)
      subject.send(message, *args, &block)
    end
    
    def subject
      @subject ||= connection.get(path_prefix){|req| req.params.merge!params }.body
    end
  end
end
# For each type of GitHub object, such as gists or users, Ghee defines one subclass of Ghee::ResourceProxy
```

```ruby
# gems/ghee-0.9.8/lib/ghee/api/gists.rb
class Ghee
  module API
    module Gists
      class Proxy < ::Ghee::ResourceProxy
        def star
          connection.put("#{path_prefix}/star").status == 204
        end
        # ...
      end
    end
end
```
A proxy does two things. 
* First, it implements methods that require specific code, such as star. 
* Second, it forwards methods that just read data, such as url , to the wrapped hash.
<br>

### ```respond_to?``` and ```respond_to_missing? methods```
```respond_to?``` is used to know the existance of static instance methods. Where as ```respond_to_missing?``` is used to get the Ghost Methods.
<br>

#### Overriding ```respond_to_missing?```
Overriding ```respond_to?``` is considered somewhat dirty. Instead, the rule is now this: remember to override ```respond_to_missing?``` every time you override ```method_missing```.

```ruby
cmp = Computer.new(0, DS.new)
cmp.respond_to?(:mouse) # => false
```

```ruby
class Computer
  # ...
  def respond_to_missing?(method, include_private = false)
    @data_source.respond_to?("get_#{method}_info") || super
  end
end

cmp.respond_to?(:mouse) # => true
```
<br>

### Module#const_missing
Just like ```BasicObject#method_missing``` we've a method ```const_missing``` in ```Module```.
<br>

### Blank Slate
A skinny class with a minimal number of methods is called a Blank Slate. e.g: ```BasicObject```
```ruby
# The root of Ruby’s class hierarchy, BasicObject , has only a handful of instance methods:
im = BasicObject.instance_methods
im # => [:==, :equal?, :!, :!=, :instance_eval, :instance_exec, :__send__, :__id__]
```

To avoid method clashes with the Object hierarchy, we can inherit BasicObject directly
```ruby
# The Builder Example

# methods/builder_example_1.rb
require 'builder'
xml = Builder::XmlMarkup.new(:target=>STDOUT, :indent=>2)
xml.coder {
  xml.name 'Matsumoto', :nickname => 'Matz'
  xml.language 'Ruby'
}

```
This code produces the following snippet of XML:
```xml
<coder>
  <name nickname="Matz">Matsumoto</name>
  <language>Ruby</language>
</coder>
```

Method name clashes resolved with BlankSlate
```ruby
# methods/builder_example_2.rb
xml.semester {
  xml.class 'Egyptology'
  xml.class 'Ornithology'
}
```
If ```XmlMarkup``` were a subclass of ```Object```, then the calls to class would clash with Object’s ```class``` . To avoid that clash, ```XmlMarkup``` inherits from a Blank Slate that removes class and most other methods from ```Object``` .
```xml
<semester>
  <class>Egyptology</class>
< class>Ornithology</class>
</semester>
```
<br>

### Dynamic Methods vs. Ghost Methods
* <b>Dynamic Methods</b> are just regular methods that happened to be defined with ```define_method``` instead of ```def``` , and they behave the same as any other method
* <b>Ghost Methods</b> are not really methods; instead, they’re just a way to intercept method calls. They don’t appear in the list of names returned by ```Object#methods```

Rule of thumb when in doubt:
<b>Use Dynamic Methods if you can and Ghost Methods if you have to.</b>
<br><br><br><br><br>

## Blocks