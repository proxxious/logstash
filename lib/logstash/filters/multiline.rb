# multiline filter
#
# This filter will collapse multiline messages into a single event.
# 

require "logstash/filters/base"

class LogStash::Filters::Multiline < LogStash::Filters::Base
  # The 'date' filter will take a value from your event and use it as the
  # event timestamp. This is useful for parsing logs generated on remote
  # servers or for importing old logs.
  #
  # The config looks like this:
  #
  # filters:
  # - multiline:
  #     <type>:
  #       pattern: <regexp>
  #       what: next
  #     <type>
  #        pattern: <regexp>
  #        what: previous
  # 
  # The 'regexp' should match what you believe to be an indicator that
  # the field is part of a multi-line event
  #
  # The 'what' must be "previous" or "next" and indicates the relation
  # to the multi-line event.
  #
  # For example, java stack traces are multiline and usually have the message
  # starting at the far-left, then each subsequent line indented. Do this:
  # 
  # filters:
  # - multiline:
  #     somefiletype:
  #       pattern: /^\s/
  #       what: previous
  #
  # This says that any line starting with whitespace belongs to the previous line.
  #
  # Another example is C line continuations (backslash). Here's how to do that:
  #
  # filters:
  # - multiline:
  #     somefiletype:
  #       pattern: /\\$/
  #       what: next
  #
  def initialize(config = {})
    super

    @types = Hash.new { |h,k| h[k] = [] }
    @pending = Hash.new
  end # def initialize

  def register
    @config.each do |type, typeconfig|
      # typeconfig will be a hash containing 'pattern' and 'what'
      @logger.debug "Setting type #{type.inspect} to the config #{typeconfig.inspect}"
      raise "type \"#{type}\" defined more than once" unless @types[type].empty?
      @types[type] = typeconfig

      if !typeconfig.include?("pattern")
        @logger.fatal("'multiline' filter config for type #{type} is missing 'pattern' setting", typeconfig)
      end
      if !typeconfig.include?("what")
        @logger.fatal("'multiline' filter config for type #{type} is missing 'what' setting", typeconfig)
      end
      if !["next", "previous"].include?(typeconfig["what"])
        @logger.fatal("'multiline' filter config for type #{type} has invalid 'what' value. Must be 'next' or 'previous'", typeconfig)
      end

      begin
        typeconfig["pattern"] = Regexp.new(typeconfig["pattern"])
      rescue RegexpError => e
        @logger.fatal(["Invalid pattern for multiline filter on type '#{type}'",
                      typeconfig, e])
      end
    end # @config.each
  end # def register

  def filter(event)
    return unless @types.member?(event.type)
    @types[event.type].each do |typeconfig|
      match = typeconfig["pattern"].match(event.message)
      pending = @pending[event.source]

      case typeconfig["what"]
      when "prev"
        if match
          # previous previous line is part of this event.
          # append it to the event and cancel it
        else
          # this line is not part of the previous event
          # if we have a pending event, it's done, send it.
          # put the current event into pending
        end
      when "next"
        if match
          # this line is part of a multiline event, the next
          # line will be part, too, put it into pending.
        else
          # if we have something in pending, join it with this message
          # and send it. otherwise, this is a new message and not part of
          # multiline, send it.
        end
      end
          


    end # @types[event.type].each
  end # def filter
end # class LogStash::Filters::Date
