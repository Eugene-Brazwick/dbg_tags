
Examples/Usage
----------------

there are 6 levels for tags. In order:
  - :nil, never prints
  - :err, for obvious error conditions, and 'canthappens' and the like
  - :log, for basic logging
  - :trc, for function entry
  - :val, for printing values
  - :dtl, for printing everything in great detail

'enable' sets up levels for the available modules. A module is 
an arbitrary identifier used with tags, to make it easier to
select which tags will print.
Tags with no module will use :generic as id.

```ruby
require 'dbg_tags'

  Tag.trc 'a message' # a :generic tag on 'trc' level or higher (so val/dtl too).

# All tags print sourcefile, current method and linenumber automatically
  Tag.trc # still prints file, method and linenumber

  Tag.trc :feature, 'a message' # only called if :feature enabled.
  Tag.err 'msg' # Triggered when :generic feature is set to any level other than :nil

# use lazy evaluation with a block.
# The block expression is printed using to_s.
  Tag.dtl :complex do "val = \#{expensive.method.call}" end
  Tag.dtl(:complex) { "val = \#{expensive.method.call}" }
  Tag.dtl(:complex) {} # same as Tag.dtl :complex 

# At the start of your application enable the desired dump-level.
  Tag.enable	# Same as Tag.enable generic: :trc
                # That is enables levels <=:trc, so trc,log and err
  Tag.enable :val   # enable :generic tags at <=:val levels
  Tag.enable :feature1, :feat2, ... # enables given features on <=:trc

# Set :feature1, :feat2, and :generic to <=:trc, :feat3 to :dtl
# and ANY OTHER feature to only :err. 
  Tag.enable :feature1, :feat2, feat3: :dtl, all: :err

  Tag.enable feature: :err 
  Tag.enable feature: :dtl # so ALL tags with feature :feature

# Tags can be used to create lazy 'canthappen' constructs:
  Tag.err(:feature) { raise 'aaaarg' if expensive_check_fails? }

# Tag.enable can be passed a block for which it is active.
# Afterwards the previous config is restored.
  Tag.enable main: :trc, printing: :val, admin: :nil do
    # ....
  end # enable

```

PRO: very simple, robust, and versatile
CON: it takes a methodcall, even if tags are disabled. Unlike using C macros.

