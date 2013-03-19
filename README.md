# redis-collections

This gem allows you to associate collections of models (currently only ActiveRecord or Mongoid models) with a Ruby object through Redis.

It uses redis-objects behind the scenes to associate a list of model ids with an object.

~~~
class Foo
  include Redis::Collections
  
  collection :bars
  
  def id
    1
  end
end

class Bar < ActiveRecord::Base
end

foo = Foo.new
bar = Bar.create
bar2 = Bar.create

foo.bars << bar << bar2
foo.bars.all
=> [#<Bar id: 2>, #<Bar id: 1>

foo.bars.ids = [1, 2]
foo.bars.all
=> [#<Bar id: 1>, #<Bar id: 2>]

foo.bars.move(bar, 1)
foo.bars.all
=> [#<Bar id: 2>, #<Bar id: 1>]

foo.bars.increment_counter(bar)
foo.counters
=> {"1" => "1"}

foo.bars.delete(bar)
foo.bars.all
=> [#<Bar id: 2>]
~~~

## Contributing to redis-collections
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2013 Evan Whalen. See LICENSE.txt for
further details.