class Parser
  def initialize(io)
    @io = io
  end
  def result
    @result ||= _execute(@io)
  end
  class State
    attr_reader :timestamp
    attr_reader :keys
    attr_reader :values

    def report
      _report = {
        timestamp: timestamp,
        attributes: {}
      }
      keys.each_with_index {|e, i|
	      _report[:attributes][e] = values[i]
      }
      _report
    end

    def report_restart
      @keys = []
      @values = []
      @timestamp = ""
    end

    def lstart1
      @lstart = 1
      tstart0
      tcomplete0
      keyvalue0
      tcomplete0
    end

    def lstart0
      @lstart = 0
    end

    def lstart
      @lstart ||= 0
    end 

    def timestamp_append(t)
      @current_timestamp ||= []
      @current_timestamp << t
    end

    def tstart1 
      @tstart = 1
    end

    def tstart0
      @tstart = 0
    end

    def tcomplete1
      @tcomplete = 1
      @timestamp = @current_timestamp.join()
      @current_timestamp = []
    end 

    def tcomplete0
      @tcomplete = 0
    end

    def tcomplete
      @tcomplete ||= 0
    end

    def keyvalue
      @keyvalue ||= 0 
    end

    def keyvalue1
      @keyvalue = 1
    end

    def keyvalue0
      @keyvalue = 0
      keyvalue_complete_key0
      keyvalue_complete_value0
    end

    def keyvalue_key_append(k)
      @current_key ||= []
      @current_key << k
    end
    def keyvalue_complete_key
      @completed_key ||= 0
    end

    def keyvalue_complete_key0
      @completed_key = 0
    end

    def keyvalue_complete_key1
      @completed_key = 1
      @keys ||= []
      @keys << @current_key.join()
      @current_key = []
    end

    def keyvalue_value_in_string
	    @kv_v_ss == 1
    end

    def keyvalue_value_string_start1
	    @kv_v_ss = 1
    end
    def keyvalue_value_string_start0
	    @kv_v_ss = 0
    end
    def keyvalue_value_append(v)
      @current_value ||= []
      @current_value << v
    end

    def keyvalue_complete_value
      @completed_value || 0
    end

    def keyvalue_complete_value0
      @completed_value = 0
    end

    def keyvalue_complete_value1
      @completed_value = 1
      @values ||= []
      @values << @current_value.join()
      @current_value =[]
    end
  end

  def _execute(io)
    state = State.new
    state.lstart1

    while	c = io.getc do
      if c == "\n" # assumes no multiline string support
        if state.keyvalue_complete_value.zero?
	        # newline signals completion of last line's value
          state.keyvalue_complete_value1
        end
        p state.report
        p state.report_restart


        state.lstart1 # expect new start
        next # skip to next
      end

      # assume reading new timestamp and nothing else
      if (!state.lstart.zero? && state.tcomplete.zero?)
        if c != " " # we haven't reached end of timestamp
          state.timestamp_append(c)
          next
        else
          # finished reading timestamp
          state.tcomplete1 # read the timestamp for the line	
          next # skip to next character
        end
      end

      if (!state.lstart.zero? && 
	        !state.tcomplete.zero? && 
	        state.keyvalue.zero?)
        if c != " "
     	    state.keyvalue1
     	    state.keyvalue_key_append(c)
	        next
        else
          # eating up whitespace
          next
        end
      end

      if (!state.lstart.zero? &&
	        !state.tcomplete.zero? &&
	        !state.keyvalue.zero? &&
          state.keyvalue_complete_key.zero?)
        if c == "="
    	    state.keyvalue_complete_key1
          next
        else
     	    state.keyvalue_key_append(c)
          next
        end	
      end
      if (!state.lstart.zero? &&
          !state.tcomplete.zero? &&
          !state.keyvalue.zero? &&
          !state.keyvalue_complete_key.zero? &&
          state.keyvalue_complete_value.zero?)
        if c == "\""  && !state.keyvalue_value_in_string
          state.keyvalue_value_string_start1
          next
        elsif c =="\"" && state.keyvalue_value_in_string
          state.keyvalue_value_string_start0
          next
        end
        
        if c == "," && !state.keyvalue_value_in_string
          state.keyvalue_complete_value1
          state.keyvalue0
        else
          state.keyvalue_value_append(c)
          next
        end
      end
    end
  end

end

if $0 == __FILE__
  Parser.new(STDIN).result
end

