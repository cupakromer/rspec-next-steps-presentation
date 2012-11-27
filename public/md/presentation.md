RSpec Next Steps
----------------

Aaron Kromer

[Twitter](https://twitter.com/cupakromer) &
[GitHub](https://github.com/cupakromer): @cupakromer

[http://aaronkromer.com](http://aaronkromer.com)

Slides: [http://rspec-next-steps.herokuapp.com/](http://rspec-next-steps.herokuapp.com/)

!

Use Contexts
------------

Use `context` to add meaning to sections of test

    describe '#new' do
      context 'default parameters' do
        # ...
      end

      context 'set name parameter' do
        # ...
      end
    end

Do not nest them too deeply

!

Use Contexts
------------

Add them directly to `describe` definitions

    describe '#create', 'with valid form' do
      # ...
    end

!

Use Metadata
------------

All `describe`, `context`, and `it` definitions take an options `hash`.

    describe 'metadata is inherited', outer: true, foo: 2 do
      it 'has access' do
        example.metadata[:foo].should eq 2
      end

      it 'has priority', outer: false do
        example.metadata[:outer].should be_false
      end
    end

!

Allow Short Hand Metadata
-------------------------

Very useful as flags (i.e. `:slow`, `:current`, `:integration`):

    # spec/spec_helper.rb
    RSpec.configure do |c|
      c.treat_symbols_as_metadata_keys_with_true_values = true
    end

    # spec file
    describe 'short hand metadata', :outer do
      it 'short hand will be true'
        example.metadata[:outer].should be_true
      end
    end

!

Metadata for Conditional Module Includes
----------------------------------------

    # spec/spec_helper.rb
    RSpec.configure do |c|
      # Can also call config.extend
      config.include FakeFS::SpecHelpers, fakefs: true
    end

    # spec file
    describe FilePurger, fakefs: true do
      # Now FileUtil, File, and Dir are stubbed by FakeFS
    end

    # or with short hand
    describe FilePurger, :fakefs do
    end

!

Metadata For External Dependencies
----------------------------------

    # spec/spec_helper.rb
    RSpec.configure do |c|
      c.filter = {
        if: ->(check) {
          case check
          when :redis_running; # ...
          when :oauth_online; check_oauth_is_online
          end
        }
      }
    end

    # spec file
    describe 'oauth login', if: :oauth_online do
      # ...
    end

!

`before(:each)`
-------------

* **Use this one!**
* `:each` is the default scope so you can just use `before do`
* A failure in any `before` block will fail the example
* Safe for use with factories
  * Rails will automatically clean up the database after each test
  * This is not true for MongoDB (use a database cleaner or roll your own)
* Mocks are only supported in `before(:each)`
* Good place to put pre-condition checks

!

`before(:all)` and `before(:suite)`
-----------------------------------

* **Do NOT use this**
* No seriously, you really almost never need this, ever
* Setting instance variables are not supported in `before(:suite)`
* Failures in `after` blocks will not affect the example status
* In Rails this is non-transactional, so any database setup done is _**NOT**_
  rolled back after the tests
* See [RSpec Rails Transactions](https://www.relishapp.com/rspec/rspec-rails/docs/transactions)
  for more details

!

`around`
--------

* Receives the example as an argument to be run with `run`
* Do not share state with the example or other hooks
* Have no access to mocks
* For more details see [Around Hooks](https://www.relishapp.com/rspec/rspec-core/v/2-12/docs/hooks/around-hooks)

!

Hook Call Order
---------------

`before` blocks are called in the order they are defined

1. `before suite`
1. `before all`
1. `before each`
1. `after each`
1. `after all`
1. `after suite`

`after` blocks are called in the reverse order they were defined

!

Hook Call Order Example
-----------------------

    # spec/spec_helper
    RSpec.configure do |config|
      config.before(:suite) do
        puts "Config: :before suite"
      end

      config.before(:all) do
        puts "Config: :before all"
      end

      config.before(:each) do
        puts "Config: :before #{example.description}"
      end

      config.around(:each) do |example|
        puts "Config: Around: :before"
        example.run
        puts "Config: Around: :after"
      end

      config.before(:all) do
        puts "Config: :before all (another)"
      end

      config.after(:all) do
        puts "Config: :after all"
      end

      config.after(:each) do
        puts "Config: :after #{example.description}"
      end

      config.after(:suite) do
        puts "Config: :before suite"
      end
    end


!

Hook Call Order Example
-----------------------

    # spec file
    require "spec_helper"

    describe "Outer Example" do
      before(:all) { puts "Outer: :before all" }
      before(:each) { puts "Outer: :before #{example.description}" }
      after(:each) { puts "Outer: :after #{example.description}" }


      describe "Inner Example" do
        before(:all) { puts "Inner: :before all" }
        before(:each) { puts "Inner: :before #{example.description}" }
        after(:each) { puts "Inner: :after #{example.description}" }
        after(:all) { puts "Inner: :after all"}

        it "example 1" do
          puts "Example: in example one"
        end

        it "example 2" do
          puts "Example: in example two"
        end
      end

      after(:each) { puts "Outer: :after #{example.description} (another)" }
      before(:each) { puts "Outer: :before #{example.description} (another)" }
    end


!

Hook Call Order Example
-----------------------

    Config: :before suite
    Config: :before all
    Config: :before all (another)
      Outer: :before all
        Inner: :before all
    Config: Around: :before
    Config: :before example 1
      Outer: :before example 1
      Outer: :before example 1 (another)
        Inner: :before example 1
          Example: in example one
        Inner: :after example 1
      Outer: :after example 1 (another)
      Outer: :after example 1
    Config: :after example 1
    Config: Around: :after
    Config: Around: :before
    Config: :before example 2
      Outer: :before example 2
      Outer: :before example 2 (another)
        Inner: :before example 2
          Example: in example two
        Inner: :after example 2
      Outer: :after example 2 (another)
      Outer: :after example 2
    Config: :after example 2
    Config: Around: :after
        Inner: :after all
    Config: :after all
    Config: :before suite

!

`before`, `after`, and `around` as Filters
-----------------------------------------

This only applies when used in `RSpec.configure`:

    # spec/spec_helper.rb
    RSpec.configure do |config|
      config.before(:each, type: :model) do
        # if on mongo clean collections
      end

      config.before(:each, :fakefs) do
        # clear file system cache
      end
    end

Metadata needs to be an exact match

!

`subject`
---------

* The source of much controversy
* Every `describe` block has an implicitly defined subject
* The implicit subject will always be the outer most `describe` object
* If the object under test is a class then the subject will be:

  > `Class.new`

!

`subject`
---------

    module Const1
      p self.object_id            #=> 70167384741720
    end

    describe Const1 do
      it { p subject.object_id }  #=> 70167384741720
      it { p subject.inspect }    #=> "Const1"
      it { p subject.class }      #=> Module
    end

    class Const2
      p self.object_id            #=> 70167384647720
    end

    describe Const2 do
      it { p subject.object_id }  #=> 70122086811940
      it { p subject.inspect }    #=> "#<Const2:0x007f8d2414a290>"
      it { p subject.class }      #=> Const2
    end

!

`subject`
---------

    Const3 = [1,2,3]

    p Const3.object_id            #=> 70122086544300

    describe Const3 do
      it { p subject.object_id }  #=> 70122086544300
      it { p subject.inspect }    #=> "[1, 2, 3]"
      it { p subject.class }      #=> Array
    end

    describe 'a string' do
      it { p subject.object_id }  #=> 70122086541960
      it { p subject.inspect }    #=> "a string"
      it { p subject.class }      #=> String
    end

!

`subject`
---------

Can be overwritten. Will be set to the return value of the block.

    describe User do
      subject { [1,2,3] }

      it { p subject.inspect }          #=> "[1,2,3]"

      context 'will stomp subject' do
        subject { 'testing' }

        it { p subject.inspect }        #=> "testing"
      end
    end

The `subject` block closest to the `it` block will take affect

!

`subject`
---------

It is lazy loaded

    describe 'lazy loading' do
      subject { puts "In subject"; 42 }

      it "doesn't use subject" do
        true.should be_true
      end

      it "uses subject" do
        subject.should eq 42            #=> "In subject"
      end
    end

!

`subject`
---------

It is memoized

    describe User do              #=> subject will be User.new
      it {
        p subject.object_id  #=> 70277304835320
        p subject.object_id  #=> 70277304835320
      }

      it {
        p subject.object_id  #=> 70277305513540
        p subject.object_id  #=> 70277305513540
      }
    end

But is re-created for each test.

!

`subject`
---------

Should be used implicitly

    describe User do
      # these are equivalent
      it { should validate_presence_of :name }
      it { subject.should validate_presence_of :name }  # Don't do this
    end

!

Named `subject`
---------------

Just a cross between `let` and `subject`.

    describe User do
      subject(:beta_user) { User.new{|u| u.flags[:beta] = true} }

      it 'allows access to new awesome feature' do
        beta_user.can_view?(:jolly_roger).should be_true
      end
    end

Use these all the time.

!

`let`
-----

    describe User do
      let(:fred) { User.new name: 'Fred' }

      it 'has name fred' do
        fred.name.should eql 'Fred'
      end
    end

* Similar to named `subject`, but cannot be implicitly called
* Is memoized
* Is lazy loaded
* Is re-created each test

!

The Case For/Against `let` and `subject`
----------------------------------------

### Against

* Over used
* It's confusing with special rules and behavior
* Harder to read code that uses it
* _Yeah couldn't come up with anything good_

### For

* Less brittle code
* Follows DRY (in the sense of one authoritative source)
* More intent revealing when used correctly

!

Shared Examples Caveat
----------------------

Lets, methods, etc are defined in the context: see tweet with
Lauren

https://gist.github.com/4125789

!

Command Line Fu
---------------

* TODO: Talk about using metadata as tags

!

`.rspec` file
-------------

    # .rspec
    --format <%= ENV['FORMAT'] || 'doc' %>

    # command line
    rake spec                     # Will use 'doc' format
    FORMAT=progress autotest      # Will use 'progress' format
!

Writing Specs
-------------

### Write the test long form then refactor

* Write all tests in one spec if you really have to.
* Break tests so they **each test only one thing**
* Add common setup code to `before` block
* Break out common actions into methods
* Break out common variables into `let` blocks

!

Example: All in one
--------------------

    describe '#purge' do
      it 'deletes relative to the directory' do
        FileUtils.mkdir_p '/tmp/test/adirectory'
        FileUtils.touch '/tmp/test/adirectory/file1.log'
        FileUtils.mkdir_p 'adirectory'
        FileUtils.touch 'adirectory/file1.log'
        File.exist?('adirectory/file1.log').should be_true
        File.exist?('/tmp/test/adirectory/file1.log').should be_true
        policy = stub 'delete_all', filter: []
        purger = Purger.new policy

        purger.purge 'adirectory', '/tmp/test'

        File.exist?('/tmp/test/adirectory/file1.log').should be_false
        File.exist?('adirectory/file1.log').should be_true
      end
    end

!

Example: After refactor steps
-----------------------------

### Move to support helper, custom matcher, upper level of spec...

    PRECONDITION_FAILED = 'Pre-condition failed.'

    def setup_fs(directory, file_names = [])
      FileUtils.mkdir_p directory
      Array(file_names).each do |name|
        FileUtils.touch "#{directory}/#{name}"
      end
    end

    subject(:purger) { Purger.new policy }

!

Example: After refactor steps
-----------------------------

    describe '#purge' do
      let(:policy) { stub 'delete_all', filter: [] }

      def expect_purge!
        expect{ purger.purge 'adirectory', '/tmp/test' }
      end

      before do
        setup_fs '/tmp/test/adirectory', 'file1.log'
        setup_fs 'adirectory', 'file1.log'

        assert File.exist?('adirectory/file1.log'), PRECONDITION_FAILED
        assert File.exist?('/tmp/test/adirectory/file1.log'), PRECONDITION_FAILED
      end
      # ...

!

Example: After refactor steps
-----------------------------

### Tests now look like

      # ...

      it 'deletes relative to the base directory' do
        expect_purge!.to have_deleted '/tmp/test/adirectory/file1.log'
      end

      it 'does not delete from other directories' do
        expect_purge!.to have_kept 'adirectory/file1.log'
      end
    end

!

References
----------

### RSpec-Core
* [https://www.relishapp.com/rspec/rspec-core/docs](https://www.relishapp.com/rspec/rspec-core/docs)
* [http://rubydoc.info/gems/rspec-core/frames](http://rubydoc.info/gems/rspec-core/frames)

### RSpec-Expectations
* [http://rubydoc.info/gems/rspec-expectations/frames](http://rubydoc.info/gems/rspec-expectations/frames)
* [https://www.relishapp.com/rspec/rspec-expectations/docs](https://www.relishapp.com/rspec/rspec-expectations/docs)


### RSpec-Mocks
* [http://rubydoc.info/gems/rspec-mocks/frames](http://rubydoc.info/gems/rspec-mocks/frames)
* [https://www.relishapp.com/rspec/rspec-mocks/docs](https://www.relishapp.com/rspec/rspec-mocks/docs)


### RSpec-Rails
* [https://www.relishapp.com/rspec/rspec-rails/docs](https://www.relishapp.com/rspec/rspec-rails/docs)
* [http://rubydoc.info/gems/rspec-rails/frames](http://rubydoc.info/gems/rspec-rails/frames)


### thoughtbot Shoulda-Matchers
* [http://rubydoc.info/github/thoughtbot/shoulda-matchers/master/frames](http://rubydoc.info/github/thoughtbot/shoulda-matchers/master/frames)

!

Whats stopping you?
-------------------

Any questions?
