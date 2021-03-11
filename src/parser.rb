module Boilpot

  Boilpot::StateFunction = {
    :facts => true,
    :when => true,
    :unless => true,
    :then => true,
    :report => true
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
        state[1][:scene].when(state[1][:pending_cond],state[1][:pending_act])
        state[1][:pending_cond] = false
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

    Boilpot.step state, descriptor
  end
end