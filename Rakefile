
require 'rubygems/package_task'
require 'rake'

RUBY = 'ruby -w -I lib'
PACKAGE = 'dbg_tags'

spec = Gem::Specification.new do |s|
  s.name = PACKAGE
  s.summary = 'a versatile dynamic debug tracing system'
  s.description = <<~END
      tags in your code can be switched on using features and levels.
      Examples:
      Tag.trc 'a message' # a :generic tag
        # All tags print sourcefile, current method and linenumber automatically
      Tag.trc # prints file, method and linenumber
      Tag.trc :feature, 'a message' # only called if :feature enabled.
      Tag.err 'msg' # Triggered when :generic feature is set to at 
                    # least :err level.
                    # The levels are :err, :log, :trc, :val and :dtl, 
                    # in that order
      Tag.dtl :complex do "val = \#{expensive.method.call}" end
      Tag.dtl(:complex) { "val = \#{expensive.method.call}" }
	  # use lazy evaluation with a block.
          # The block expression is printed using to_s.
      Tag.dtl(:complex) {} # same as Tag.dtl :complex 
# At the start of your application enable the desired dump-level.
      Tag.enable	# Same as Tag.enable generic: :trc
                        # That is enables levels <=:trc
      Tag.enable :val   # enable :generic tags at <=:val levels
      Tag.enable :feature1, :feat2, ... # enables given features on <=:trc
      Tag.enable :feature1, :feat2, feat3: :dtl, all: :err
	# Set :feature1, :feat2, and :generic to <=:trc, :feat3 to :dtl
	# and ANY OTHER feature to only :err. 
      Tag.enable feature: :err 
      Tag.enable feature: :dtl # so ALL tags with feature :feature
      Tag.err(:feature) { raise 'aaaarg' if expensive_check_fails? }
END
  s.version = '1.0.0'
  s.author = 'Eugene Brazwick'
  s.email = 'eugenebrazwick@gmail.com'
  s.homepage = 'https://github.com/Eugene-Brazwick/dbg_tags'
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = '>=2.7'
  s.add_development_dependency 'rspec', '~>3.4'
  s.add_development_dependency 'rake', '~>10.4'
  s.add_development_dependency 'simplecov', '~>0.18'
  s.files = Dir['lib/*.rb']
  s.license = 'GPL-3.0'
  s.test_files = Dir['spec/*_spec.rb']
end # new

GEM = "#{spec.name}-#{spec.version}.gem"
Gem::PackageTask.new(spec).define

# 'rake gem' shows it seems to use 'ln' to put these files there.
# So why is it borked?
#
# So the problem is the 'gem install' command.
# It does NOT install stuff from the pkg dir if already present?
# Indeed, but it DOES 'touch' the installed file.
# WTF??
# Need to increase version?
# Yes, but that just makes a new directory, which seems stupid.

task default: :gem 

# LOCALLY only, altough it seems to try to connect to rubygems.org...
task :install do
  `sudo gem uninstall ./pkg/#{GEM}`
  `sudo gem install ./pkg/#{GEM}`
end

# publish it...
task :push do
  `gem push ./pkg/#{GEM}`
end
__END__

sudo gem install rake	  # to install rake. This file needs it...
rake gem  # or
rake	  # to build
sudo rake install  # to install it locally. OR:
rake push  # to publish it on the internet

