# Guard::OCUnit [![Build Status](https://secure.travis-ci.org/ap4y/guard-ocunit.png?branch=master)](http://travis-ci.org/ap4y/guard-ocunit)

OCUnit guard allows to automatically launch tests when files are modified.

* Compatible with XCode 4.x
* Tested with XCode 4.5.

## Install

Please be sure to have [Guard](https://github.com/guard/guard) and [ios-sim](https://github.com/phonegap/ios-sim) installed before continue. `guard-ocunit` uses `ios-sim` for running `application` tests from command line, for more info refer to the [SO](http://stackoverflow.com/questions/12557935/xcode-4-5-command-line-unit-testing) question.

* Install the gem:

```bash
$ gem install guard-ocunit
```

* Add guard definition to your Guardfile by running this command:

```bash
$ guard init ocunit
```

* Enable `Run` in the `Build` section of your test bundle’s scheme.

## Usage

Please read [Guard usage doc](https://github.com/guard/guard#readme)

## Guardfile

OCUnit guard can be adapted to your projects.

### Standard Cocoapods project

``` ruby
guard :ocunit,
      :derived_data  => '/tmp/tests',
      :workspace     => 'SampleApp.xcworkspace',
      :scheme        => 'SampleApp',
      :test_bundle   => 'SampleAppTests' do

  watch(%r{^SampleAppTests/.+Tests\.m})
  watch(%r{^SampleApp/Models/(.+)\.[m,h]$}) { |m| "SampleAppTests/#{m[1]}Tests.m" }
end
```

Please read [Guard doc](https://github.com/guard/guard#readme) for more information about the Guardfile DSL.

## Options

By default, Guard::OCUnit will only look for test files within `Tests` in your project root. You can configure Guard::OCUnit to look in additional paths by using the `:test_paths` option:

``` ruby
guard 'ocunit', :test_paths => ["Tests", "/Models/Tests"],:test_bundle => 'SampleAppTests' do
  # ...
end
```

### List of available options:

``` ruby
:test_bundle  => '',            # test ocunit bundle with provided name, mandatory parameter
:derived_data => ''/tmp/tests/, # build into provided path, default: current folder
:workspace    => nil,           # build provided workspace, default: nil, use with :scheme
:scheme       => nil,           # build provided scheme, default: nil, use with :workspace
:project      => nil,           # path to the project to test, defaults to current folder
:sdk          => '',            # link and test against provided device sdk, default: 'iphonesimulator'
:verbose      => false          # dump all tests information in console
:notification => false          # display notification after the tests are done running, default: true
:all_after_pass => false        # run all tests after changed tests pass, default: true
:all_on_start => false          # run all tests at startup, default: true
:keep_failed  => false          # keep failed tests until they pass, default: true
:tests_paths  => ["Tests"]      # specify an array of paths that contain test files
:focus_on_failed => false       # focus on the first 10 failed tests first, rerun till they pass
:clean        => false          # defines all builds as clean. By default run all command doing clean build
:build_variables => ''          # passes provided parameters to the xcodebuild
:ios_sim_opts => ''             # passes provided options to the ios-sim
```

## Credits

* [guard-rspec](https://github.com/guard/guard-rspec) by [Thibaud Guillaume-Gentil](https://github.com/thibaudgg)
* [https://gist.github.com/alloy/3011214](https://gist.github.com/alloy/3011214) by
[Eloy Durán](https://github.com/alloy)
