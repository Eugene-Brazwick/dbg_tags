
# Usage:
# require 'dbg_tags'
# 		Tag.err 'text', short for Tag.err(:generic) 'text' 
# 		    # :err should be used for fail states and paranoia stuff
# 		Tag.log 'text' # prints very important messages only
# 		Tag.trc 'text' # default level, method entries, for example
# 		Tag.val 'text' # prints more details
# 		Tag.dtl 'text' # prints megabytes of details
# 		Tag.enable :log # enables log,trc,val,dtl tags for :generic
# 		Tag.enable :dtl # only enables :dtl calls
# 		Tag.enable :err # enable ALL :generic tags
# 		Tag.err :feature, 'FAILURE'
# 		Tag.log :feature, 'log me'
# 		Tag.trc :feature, 'called method'
# 		Tag.val(:feature) { "text#{expr}" }
# 		Tag.dtl(:feature) { "text#{very complicated expr}" }
#               Tag.err(:test) { raise 'aaaarg' if paranoia_failure }
#               Tag.err(:test) { raise 'CANTHAPPEN' if paranoia_failure }
# Tag.enable :feature1, :feature2..., featureN: :log, featureO: :val, ...
# Tag.enable feature1: :trc, feature2: :val
# Tag.enable feature: Tag::TRC
# Tag.enable :val   # for :generic only
# Tag.enable # sets :generic to :trc
# Tag.enable(...) do ... end
# Tag.enable feature: nil
# Tag.enable feature: :nil
# Tag.enable all: :err    # :all is a default for ALL systems, including :generic
# Tag.enable test: :err # switch on paranoia checking
module Tag

  TAG_DEFAULT_LEVEL = 3
  TAG_FEATURE_ALL = :all
  TAG_FEATURE_GENERIC = :generic
  NONE = 0
  ERR = 1
  LOG = 2
  TRC = 3 
  VAL = 4
  DTL = 5
  # nil and :nil will both map to NONE
  TAG_MAPPING =  { none: NONE, err: ERR, log: LOG, trc: TRC, val: VAL, dtl: DTL, 
                   nil: NONE,
                   nil => NONE
                 } # TAG_MAPPING

# @@enabled[:feature] => 0..5
  @@enabled = {} 
  @@stream = STDERR

  module InstanceMethods
    @@inside = false

    TAG_MAPPING.each do |meth, lev|
      next if lev == NONE
      define_method meth do |feature = TAG_FEATURE_GENERIC, msg = '', &msg_block|
	msg, feature = feature, TAG_FEATURE_GENERIC if String === feature
#STDERR.puts "DEBUGTAG #{meth}. feature=#{feature}, level=#{Tag.level(feature)}, lev=#{lev}"
	return if @@inside || (Tag.level(feature) || 0) < lev
	# either msg OR msg_block must be set
	if msg_block 
	  prev_inside = @@inside
	  begin
	    @@inside = true
	    msg = msg_block.call 
	  ensure
	    @@inside = prev_inside
	  end
	end
        if msg
          c = caller[0]
  #STDERR.puts "DEBUGTAG c[#{idx}] = #{c}, caller[1]=#{caller[1]}, caller[2]=#{caller[2]}"
          label = c[/\w+\.rb:\d+:in `[^']+'/]&.sub(/in `([^']+)'/, '\1:') ||
                  c[/\w+\.rb:\d+:/] ||
                  c[/[^:\/]+:\d+:/] || 
                  c
          Tag.stream.print "#{label} #{msg}\n"
        end
      end # Tag.err, Tag.log, Tag.trc, Tag.val, Tag.dtl
    end # each

    # inside? -> true if we are currently executing a block in err/log/trc/val or dtl.
    def inside?; @@inside; end

  end # module Tag::InstanceMethods

  public # class methods of Tag

    extend InstanceMethods
    include InstanceMethods

    # enable :feature, ...[, feature: level, ...] [block]
    # :generic is NO LONGER IMPLICETELY ENABLED as of version
    # Use :all to set a default for all features not mentioned otherwise
    # Integers in range 1..5 can be used as level or the constants ERR,LOG,TRC,VAL,DTL
    # or the symbols :err, :log, :trc, :val and :dtl
    # If no level is specified for a feature the default is :trc (== TRC == 3)
    # use nil or :none to disable all tags, even the ERR level ones.
    #
    # enable performs a merge with an existing enable.
    def self.enable *arg
      org_enabled = @@enabled.dup
      arg.each do |s|
	case s
        when Hash
          s.each do |t, level|
	    @@enabled[t] = Symbol === level ? TAG_MAPPING[level] : level
	  end
        when Integer
          @@enabled[TAG_FEATURE_GENERIC] = s
	else
          if TAG_MAPPING[s]
            @@enabled[TAG_FEATURE_GENERIC] = TAG_MAPPING[s]
          else
            @@enabled[s] = TAG_DEFAULT_LEVEL 
          end
	end # case
      end # each
      if arg.empty?
        @@enabled[TAG_FEATURE_GENERIC] = TAG_DEFAULT_LEVEL
      end
      if block_given?
#        STDERR.puts "TAG: block_given!"
        begin
#          STDERR.puts "TAG: yield!"
          yield
        ensure
          @@enabled = org_enabled
        end # ensure
      end # block_given?
    end # Tag.enable

    # enabled -> Hash
    def self.enabled; @@enabled; end
    def self.stream; @@stream; end

    # for testing purposes:
    def self.stream= val; @@stream = val; end

    # level(:feature) -> 0..5 or nil. Uses :all as a fallback-feature
    def self.level feature; @@enabled[feature] || @@enabled[TAG_FEATURE_ALL]; end

    # enabled?(:feature) -> bool. Could be :err up to :dtl. Ignores setting of :all!
    def self.enabled? feature; @@enabled[feature] && @@enabled[feature] > NONE; end
end # module Tag
