module Boilpot

  def Boilpot.step old_state, desc
    state = old_state.dup
    case state[0]
    when :facts
      state[1][:scene].set desc
    when :when
      c = Condition.new(desc)
      if state[1][:pending_cond]
        state[1][:pending_cond] = state[1][:pending_cond] & c
      else
        state[1][:pending_cond] = c
      end
    when :unless
      c = Condition.new(desc)
      if state[1][:pending_cond]
        state[1][:pending_cond] = state[1][:pending_cond] & (~c)
      else
        state[1][:pending_cond] = (~c)
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

end