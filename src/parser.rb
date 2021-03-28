
  Boilpot::StateFunction = {
    :facts => true,
    :when => true,
    :unless => true,
    :then => true,
    :report => true,
    :until => true
  }

  def Boilpot.parse doc
    scene = Scenario.new
    state = [:start, Hash.new]
    state[1][:scene] = scene
    
    doc.lines.each_with_index do |line,index|
      state = Boilpot.parse_line line, index, state
    end
    
    return scene
  end
  
  def Boilpot.parse_line line_raw, index, state
    line = line_raw.strip
    if(line[-1] == ":" && line[-2] != "\\")

      new_state = line.strip[0..-2].downcase.to_sym

      if StateFunction[new_state]
        state[0] = new_state
        return state
      else
        raise "Unknown state at line #{index}: #{new_state.to_s}"
      end

    elsif line == ""
      if state[1][:close]
        if state[1][:pending_precondition]
          state[1][:scene].until(state[1][:pending_cond],state[1][:pending_act])
        else
          state[1][:scene].when(state[1][:pending_cond],state[1][:pending_act])
        end
        state[1][:pending_cond] = false
        state[1][:pending_precondition] = false
        state[1][:pending_act] = false
        state[1][:close] = false
      end
      
      return state
    elsif StateFunction[state[0]]

      phrase = line.strip
      
    elsif state[0] == :start
      raise "Boilpot programs must start with a section heading"
    else
      raise "somehow got into an invalid state at line #{index}: #{state[0]}"
    end

    descriptor = phrase.split(" ").map do |word|
      if word[0] == ":"
        word[1..-1].to_sym
      elsif word[0] == "~" && state[0] == :then
        state[1][:pending_deny] = true
        w = word[1..-1]
        if w[0] == ":"
          w[1..-1].to_sym
        else
          w
        end
      else
        word
      end
    end

    Boilpot.step state, descriptor, index
  end
  
  def Boilpot.step old_state, desc, lineno
    state = old_state.dup
    case state[0]
    when :facts
      if(desc[0][0,2] == "<>")
        desc[0] = desc[0][2..-1]
        state[1][:scene].set desc
        state[1][:scene].set desc.reverse
      else
        state[1][:scene].set desc
      end
    when :until
      state[1][:pending_precondition] = true
      c = Condition.new(desc)
      if state[1][:pending_cond]
        state[1][:pending_cond] = state[1][:pending_cond] & c
      else
        state[1][:pending_cond] = c
      end
    when :when
      c = Condition.new(desc)
      if state[1][:pending_cond]
        state[1][:pending_cond] = state[1][:pending_cond] & c
      else
        state[1][:pending_cond] = c
      end
    when :unless
      if(desc[0].to_s[0] == "=")
        k = desc[0][1..-1].to_sym
        v = desc[1]
        if state[1][:pending_cond]
          state[1][:pending_cond].forbid(k, v)
        end
      else
        c = Condition.new(desc)
        if state[1][:pending_cond]
          state[1][:pending_cond] = state[1][:pending_cond] & (~c)
        else
          state[1][:pending_cond] = (~c)
        end
      end
    when :then
      if !state[1][:pending_act]
        state[1][:pending_act] = Action.new
      end
      if state[1][:pending_deny]
        state[1][:pending_deny] = false
        state[1][:pending_act] = state[1][:pending_act].deny(desc)
      else
        state[1][:pending_act] = state[1][:pending_act].assert(desc)
      end
    when :report
      state[1][:pending_act].announce(desc)
      state[1][:close] = true
    end
    
    return state
  end

