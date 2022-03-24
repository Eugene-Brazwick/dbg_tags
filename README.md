
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

Tag.enable main: :trc, printing: :val, admin: :nil
# enable can be passed a block for which it is active.

Tag.err :module_name, 'text' 

# Using :generic module:
Tag.trc 'here!'

# You can use blocks to avoid expensive method calls:
Tag.dtl(:main) { "complicated calculation -> #{call_expensive_method}" }
```

PRO: very simple, robust, and versatile
CON: if takes a methodcall, even if tags are disabled. Unlike using C macros.

