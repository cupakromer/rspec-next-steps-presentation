RSpec Next Steps
----------------

Aaron Kromer

[Twitter](https://twitter.com/cupakromer) &
[GitHub](https://github.com/cupakromer): @cupakromer

[http://aaronkromer.com](http://aaronkromer.com)

Slides: [http://gentle-ocean-3130.herokuapp.com/](http://gentle-ocean-3130.herokuapp.com/)

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

Use Metadata for Conditionally Including Modules
------------------------------------------------

    # spec/spec_helper.rb
    RSpec.configure do |c|
      # Can also call config.extend
      config.include FakeFS::SpecHelpers, fakefs: true
    end

    # spec file
    describe FilePurger, fakefs: true do
      # Now FileUtil, File, and Dir are stubbed by FakeFS
    end

!

Use Metadata For Environment Dependencies
-----------------------------------------

    # spec/spec_helper.rb
    RSpec.configure do |c|
      c.filter = {
        if: lambda { |check|
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

Command Line Fu
---------------

* TODO: Talk about using metadata as tags

!

Writing Specs
-------------

### Write the test long form then refactor

* Write all tests in one spec if you really have to.
* Break tests so they **each test only one thing**
* Break out common actions into methods
* Break out common variables into `let` blocks
* Add common setup code to `before` block

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
        policy_manager = stub 'delete_all', filter: []
        purger = Purger.new policy_manager

        purger.purge 'adirectory', '/tmp/test'

        File.exist?('/tmp/test/adirectory/file1.log').should be_false
        File.exist?('adirectory/file1.log').should be_true
      end
    end

!

Example: After refactor steps
-----------------------------

### Move to upper level of spec

    PRECONDITION_FAILED = 'Pre-condition failed.'

    subject(:purger) { Purger.new policy_manager }

    def setup_fs(directory, file_names)
      FileUtils.mkdir_p directory
      file_names.each do |name|
        FileUtils.touch "#{directory}/#{name}"
      end
    end

!

Example: After refactor steps
-----------------------------

### Tests now look like

    describe '#purge' do
      let(:policy_manager) { stub 'delete_all', filter: [] }

      before do
        setup_fs '/tmp/test/adirectory', 'file1.log'
        setup_fs 'adirectory', 'file1.log'

        assert File.exist?('adirectory/file1.log'),
               PRECONDITION_FAILED
        assert File.exist?('/tmp/test/adirectory/file1.log'),
               PRECONDITION_FAILED

        purger.purge 'adirectory', '/tmp/test'
      end

      # ...

!

Example: After refactor steps
-----------------------------

### Tests now look like

      # ...

      it 'deletes relative to the directory' do
        File.exist?('/tmp/test/adirectory/file1.log').should be_false
      end

      it 'does not delete from other directories' do
        File.exist?('adirectory/file1.log').should be_true
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
