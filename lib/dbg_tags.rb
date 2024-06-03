
# @example Usage:
#
#   # enabling
#   # -----------
#   require 'dbg_tags'
#
#   Tag.enable :feature1, :feature2..., featureN: :log, featureO: :val, ...
#   Tag.enable feature1: :trc, feature2: :val
#   Tag.enable feature: Tag::TRC
#   Tag.enable :dtl # enables ALL logging for :generic 
#   Tag.enable :val # enables val+trc+log+err for :generic only
#   Tag.enable :trc # enables trc+log+err for :generic only
#   Tag.enable :log # enables log+err tags for :generic
#   Tag.enable :err # enables err tags for :generic
#   Tag.enable # sets :generic to :trc
#   Tag.enable(...) do ... end
#   Tag.enable feature: nil
#   Tag.enable feature: :nil
#   Tag.enable all: :err    # :all is a default for ALL systems, including :generic
#   Tag.enable test: :err # switch on paranoia checking
#   Tag.enable feature: '>=trc'  # make sure at least level trc
#
#   # logging 
#   # -----------
#   Tag.err 'text', short for Tag.err(:generic) 'text' 
# 		    # :err should be used for fail states and paranoia stuff
#   Tag.log 'text' # prints very important messages only
#   Tag.trc 'text' # default level, method entries, for example
#   Tag.val 'text' # prints more details
#   Tag.dtl 'text' # likely prints megabytes of details
#   Tag.err :feature, 'FAILURE'
#   Tag.log :feature, 'log me'
#   Tag.trc :feature, 'called method'
#   Tag.val(:feature) { "text#{expr}" }
#   Tag.dtl(:feature) { "text#{very complicated expr}" }
#   Tag.err(:test) { raise 'aaaarg' if complex_paranoia_failure }
#   Tag.err(:test) { raise 'CANTHAPPEN' if complex_paranoia_failure }

module Tag
  # :all overrides the minimum level on ALL tags in the system
  TAG_FEATURE_ALL = :all

  # :generic is the default feature, if left unspecified
  TAG_FEATURE_GENERIC = :generic

  # lowest level. No output
  NONE = 0

  # level 1. Only error situation should use this
  ERR = 1

  # level 2. Only very important information
  LOG = 2

  # level 3. Mostly used for method entries
  TRC = 3 

  # level 4. Mostly used dumping of attribute values
  VAL = 4

  # level 5. Mostly used for exhaustive dumping of attribute values and minor details
  DTL = 5

  # the default is :trc
  TAG_DEFAULT_LEVEL = TRC 

  # nil and :nil will both map to NONE
  TAG_MAPPING =  { none: NONE, err: ERR, log: LOG, trc: TRC, val: VAL, dtl: DTL, 
                   nil: NONE,
                   nil => NONE
                 } # TAG_MAPPING

  # This class stores an instance of the global state of the Tag system
  class GlobalState
    private
    def initialize
      # @enabled[:feature] => 0..5
      @enabled = {}
      @inside = false
      @stream = STDERR
    end # GlobalState.initialize

    # @param level_spec [Integer,Symbol,String,nil]
    # @param feature [Symbol]
    # @return [0..5]
    def debunk_level level_spec, feature
      #      raise 'AARG' unless Symbol === feature
# OK    STDERR.puts "DEBUNK: level_spec=#{level_spec.inspect}, feature=#{feature.inspect}"
      case level_spec
      when 0..5 then return level_spec 
      when nil then return NONE
      when Symbol
        r = TAG_MAPPING[level_spec] and return r 
      when /\A(err|log|trc|val|dtl)\z/
        return TAG_MAPPING[level_spec.to_sym] 
      when /\A>=(err|log|trc|val|dtl)\z/
        eff_lev = level feature
        new_lev = TAG_MAPPING[level_spec[2..].to_sym]
# OK STDERR.puts "level_spec=#{level_spec}, feature=#{feature.inspect},eff_lev=#{eff_lev},new_lev=#{new_lev}"
        return [eff_lev, new_lev].max
      end # case
      raise ArgumentError, "bad level #{level_spec.inspect}"
    end # Tag::debunk_level

    public # methods of GlobalState

    # @return [{Symbol} => 0..5]
    attr :enabled

    # @return [Bool] True if a Tag.err..dtl is currently active
    attr_accessor :inside
    alias inside? inside

    # @return [IO] Current output stream
    attr_accessor :stream

    # @param features [<Symbol>] To enable on :trc level
    # @param opts [{Symbol => Symbol}] Keys are features, values levels.
    # A block can be given to restore the original state afterwards
    # enable :feature, ...[, feature: level, ...] [block]
    # :generic is NO LONGER IMPLICETELY ENABLED as of version 1.0.0
    # Use :all to set a default for all features not mentioned otherwise
    # Integers in range 1..5 can be used as level or the constants ERR,LOG,TRC,VAL,DTL
    # or the symbols :err, :log, :trc, :val and :dtl
    # Strings can be used in the shape of 'err' or '>=err' etc.
    # If '>=LVL' is used the level will not lower, if already set in an outer block.
    # If no level is specified for a feature the default is :trc (== TRC == 3)
    # use nil, :nil, :none or Tag::NONE to disable all tags, even the ERR level ones.
    #
    # enable performs a merge with an existing enable.
    def enable *features, **opts
      org_enabled = @enabled.clone # to restore the state at the end (unused unless block_given)
      features.each do |feature|
        case feature
        when 0..5 # not a feature, apply to :generic
          @enabled[TAG_FEATURE_GENERIC] = feature 
        when Symbol
          if TAG_MAPPING[feature] # not a feature 
            @enabled[TAG_FEATURE_GENERIC] = TAG_MAPPING[feature]
          else
            @enabled[feature] = TAG_DEFAULT_LEVEL
          end
        when String
          @enabled[TAG_FEATURE_GENERIC] = debunk_level feature, TAG_FEATURE_GENERIC
        else
          raise ArgumentError "bad level #{feature.inspect}"
        end # case
      end # each
      opts.each do |feature, level|
        # OK        STDERR.puts "OPTION!!!!!!!!!!!!!!!!!, calling debunk_level"
        @enabled[feature] = debunk_level level, feature
      end
      if features.empty? && opts.empty?
        @enabled[TAG_FEATURE_GENERIC] = TAG_DEFAULT_LEVEL
      end
      if block_given?
        begin
          yield
        ensure
          @enabled = org_enabled
        end # ensure
      end # block_given?
    end # GlobalState.enable

    # @param state [{Symbol=>0..5}] As returned by Tag.state (aka Tag.enabled)
    # A block can be given to restore the original state afterwards.
    # restore_state overwrites any existing enabled feature.
    def restore_state state
      org_enabled = @enabled.clone # to restore the state at the end (unused unless block_given)
      @enabled = state.dup
      if block_given?
        begin
          yield
        ensure
          @enabled = org_enabled
        end # ensure
      end # block_given?
    end # GlobalState.restore_state

    # @param feature [Symbol]
    # @return [0..5] Current effective level for feature.
    def level feature
      @enabled[feature] || @enabled[TAG_FEATURE_ALL] || Tag::NONE 
    end # GlobalState.level
  end # GlobalState

  class << self

    public # class methods of Tag

    # @return [GlobalState] Thread local data 
    def global_state
      if gs = Thread.current[:dbg_tags_global_state]
        gs
      else
        Thread.current[:dbg_tags_global_state] = GlobalState.new
      end
    end # Tag::global_state

    # @param feature [Symbol,nil] Subsystem to print logging for. Fully dynamic/free
    # @param msg [String,nil] 
    # @note feature and msg can be switched
    # @param block [Proc,nil] If set the result overrides and msg passed.
    # The call is silently ignored if called from inside another Tag block (likely
    # a sign of a stack overflow in process).
    # The call is silently ignored if the current tag level is too low.
    # For trc it should be trc or val or dtl to actually print something.
    # @!method trc feature = TAG_FEATURE_GENERIC, msg = '', &block

    # @!method err feature = TAG_FEATURE_GENERIC, msg = '', &block
    # @see trc 
   
    # @!method log feature = TAG_FEATURE_GENERIC, msg = '', &block
    # @see trc 
   
    # @!method val feature = TAG_FEATURE_GENERIC, msg = '', &block
    # @see trc 
 
    # @!method dtl feature = TAG_FEATURE_GENERIC, msg = '', &block
    # @see trc 
  
    TAG_MAPPING.each do |meth, lev|
      next if lev == NONE
      define_method meth do |feature = TAG_FEATURE_GENERIC, msg = '', &msg_block|
        state = global_state
	msg, feature = feature, TAG_FEATURE_GENERIC if String === feature
#STDERR.puts "DEBUGTAG #{meth}. feature=#{feature}, level=#{Tag.level(feature)}, lev=#{lev}"
        return if state.inside? || (state.level(feature) || Tag::NONE) < lev
	# either msg OR msg_block must be set
	if msg_block
          prev_inside = state.inside?
	  begin
            state.inside = true
	    msg = msg_block.call 
	  ensure
            state.inside = prev_inside
	  end
	end
        if msg
          c = caller[0]
  #STDERR.puts "DEBUGTAG c[#{idx}] = #{c}, caller[1]=#{caller[1]}, caller[2]=#{caller[2]}"
          label = c[/\w+\.rb:\d+:in `[^']+'/]&.sub(/in `([^']+)'/, '\1:') ||
                  c[/\w+\.rb:\d+:/] ||
                  c[/[^:\/]+:\d+:/] || 
                  c
          state.stream.print "#{label} #{msg}\n"
        end
      end # Tag.err, Tag.log, Tag.trc, Tag.val, Tag.dtl
    end # each

    # inside? -> true if we are currently executing a block in err/log/trc/val or dtl.
    def inside?; global_state.inside?; end

    # @see GlobalState.enable
    def enable(...); global_state.enable(...); end

    # @see GlobalState.restore_state
    def restore_state(...); global_state.restore_state(...); end

    # @return [{Symbol=>0..5}] Keys are the features
    def enabled; global_state.enabled; end
    alias state enabled

    # @return [IO] By default this is STDERR
    def stream; global_state.stream; end

    # @param val [IO] 
    # Override the output stream.
    def stream= val; global_state.stream = val; end

    # @param feature [Symbol]
    # @return [0..5] Current effective level for feature.
    # 2023-08-14 no longer returns nil
    def level feature; global_state.level feature; end

    # @param feature [Symbol]
    # @return [bool] Reflects explicit enable calls only. The :all feature is IGNORED
    def enabled? feature; (global_state.enabled[feature] || NONE) > NONE; end

  end # singleton class Tag
end # module Tag
