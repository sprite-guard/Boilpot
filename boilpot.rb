class Scenario

  attr_reader :facts, :log, :conditions

  def initialize
    @facts = Hash.new(false)
    @conditions = []
    @log = []
  end
  
  def set fact
    if fact.is_a? String
      fact_id = fact
    else
      fact_id = fact.join(" ")
    end
    
    if(@facts[fact_id])
      return true
    else
      @facts[fact_id] = Fact.new(fact)
    end
  end
  
  def clear fact
    if fact.is_a? String
      fact_id = fact
    else
      fact_id = fact.join(" ")
    end
    if @facts[fact_id]
      @facts.delete(fact_id)
    end
  end
  
  def each_fact &f
    @facts.map &f
  end
  
  def bulk_set fact_length, word_list
    word_list.each_slice(fact_length).each do |chunk|
      set chunk
    end
  end
  
  def when condition, consequence
    @conditions << (Condition.wrap(condition,self) >> consequence)
  end
  
  def shuffle
    @conditions.shuffle
    @facts.shuffle
  end
  
  def seek
    @conditions.each do |c|
      c << facts
    end
  end
  
  def serialize
    {
      :facts => @facts.serialize,
      :conditions => @conditions.serialize,
      :log => @log.serialize
    }
  end
  
  def to_s
    serialize.to_s
  end
  
  def inspect
    to_s
  end

end


class Pattern
  def self.wrap a
    if a.is_a? Array
      return Pattern.new(a)
    elsif a.is_a? Pattern
      return a
    else
      raise "Pattern::wrap does not apply to #{a.class}"
    end
  end
  def initialize words
    if words.is_a? String
      @words = words.split(" ")
    elsif words.is_a? Array
      @words = words
    else
      raise "Pattern must be a string or array"
    end
  end
  
  def each_with_index &block
    @words.each_with_index &block
  end
  
  def serialize
    @words
  end
  def to_s
    serialize.to_s
  end
end

class Condition

  @@id = 0

  attr_reader :test, :tail, :action, :parent, :id
  attr_writer :parent
  
  def self.wrap descriptor, parent=false, tail=false, complement=false
    if !descriptor
        return descriptor
    end
    if descriptor.is_a? Array
      return Condition.new(Pattern.new(descriptor), parent, tail, complement)
    elsif descriptor.is_a? Pattern
      return Condition.new(descriptor, parent, tail, complement)
    elsif descriptor.is_a? Condition
      res = descriptor.dup
      res.parent = parent
      return res
    else
      raise "Condition::wrap does not apply to #{descriptor.class}"
    end
  end

  def initialize pattern, parent=false, tail=false, complement = false
    @test = Pattern.wrap(pattern)
    @tail = Condition.wrap(tail, parent, false, false)
    @parent = parent
    @complement = complement
    @id = "C" + @@id.to_s
    @@id += 1
  end
  
  def serialize
    {
      :test => @test.to_s,
      :tail => @tail,
      :parent => @parent,
      :complement => @complement
    }
  end
  
  def to_s
    serialize.to_s
  end
      
  
  def match facts, bindings={}
    facts.each do |id,fact|
      next_match = fact.match @test, bindings
      if next_match
        if @tail
          # recursive case:
          # we have matched at this level, but there is a tail.
          # next_match must contain our new bindings.
          res = @tail.match facts, next_match
          if res
            return res
          else
            next
          end
        else
          # base case A:
          # we have hit the end of the conditional
          # and we have found a set of bindings that work.
          # This *should* be a tail-call that goes straight up
          # the stack, so whatever we pass should be what comes
          # out the other end.
          if(!@complement)
            return next_match
          else
            return false
          end
        end
      end
    end # each fact
    # base case B:
    # We should only get here if the head does not have a match
    # which is success for complement and failure for normal.
    # If complement succeeds, don't change the bindings,
    # just pass them to tail or return them as necessary
    if(@complement)
      return bindings
    else
      return false
    end
  end # match
  
  def &(other)
    new_tail = Condition.wrap(other, @parent, false, false)
    if(new_tail.tail)
      raise "Only tailless conditions can be added to the tail."
    end
    
    # if we don't have a tail, make new_tail our tail.
    # this is the intended use case.
    
    if !@tail
      @tail = new_tail
    else
      # if we already have a tail, we want to insert this into it.
      # you shouldn't be doing this, but :shrug_emoji: I'm sure someone will.
      # we can pass it recursively down the chain until it finds someone
      # who doesn't have a tail.
      # if you dodged around the exceptions and made a cyclic tail
      # that's your own damn fault.
      @tail & other
    end
    return self
  end # &
  
  def ~()
    @complement = true
    return self
  end
  
  def >> consequence
    @action = consequence.dup
    return self
  end
  
  def << facts
    context = match(facts)
    if(context)
      @action.bind_assertions(context).apply(parent)
    end
  end
  
  def parent=(scene)
    @parent = scene
    if(@tail)
      @tail.parent = scene
    end
  end

end

class Action

  attr_reader :id

  @@id = 0

  def self.wrap descriptor, parent
    if descriptor.is_a? Action
      return descriptor
    elsif descriptor.is_a? Hash
      return Action.new(descriptor, parent)
    else
      return Action.new(Hash.new,parent)
    end
  end
  
  def initialize
    @assertions = []
    @denials = []
    @announcement = nil
    @bound = Hash.new
    @id = "A" + @@id.to_s
    @@id += 1
  end
  
  def assert fact
    @assertions << fact
    return self
  end
  
  def deny fact
    @denials << fact
    return self
  end
  
  def announce message
    @announcement = SubText.new(message)
  end
  
  def bind_assertions bindings
    @bound = Hash.new
    @bound[:assertions] = []
    @assertions.each do |statement|
      @bound[:assertions] << SubText.new(statement).bind(bindings)
    end
    @bound[:denials] = []
    @denials.each do |statement|
      @bound[:denials] << SubText.new(statement).bind(bindings)
    end
    @bound[:announcement] = @announcement.bind(bindings)
    return self
  end
  
  def apply context
    @bound[:assertions].each do |fact|
      context.set fact
    end
    @bound[:denials].each do |falsehood|
      context.clear falsehood
    end
    context.log << @bound[:announcement]
  end
  
  def serialize
    {
      :bound => @bound,
      :assertions => @assertions,
      :denials => @denials,
      :announcement => @announcement,
      :parent => @parent
    }
  end
  def to_s
    @announcement.to_s
  end
      
end

class SubText

  def initialize words
    @words = words
  end
  
  def bind bindings
    res = []
    @words.each do |w|
      if w.is_a? Symbol
        if bindings[w]
          res << bindings[w]
        else
          raise "Could not find #{w} in given bindings #{bindings}"
        end
      elsif w.is_a? String
        res << w
      else
        raise "Words must be strings or symbols, but instead got #{w}"
      end
    end
    return res.join(" ")
  end
  
  def serialize
    @words
  end
  def to_s
    serialize.to_s
  end
end

class Fact

  attr_reader :words, :id
  
  @@id = 0

  def initialize(words)
    if words.is_a? String
      @words = words.split(" ")
    elsif words.is_a? Array
      @words = words
    else
      raise "Facts must be an array or string."
    end
    @id = "F" + @@id.to_s
    @@id += 1
  end
  
  def match(pattern,bindings=Hash.new(false))
    new_bindings = bindings.dup
    pattern.each_with_index do |item, index|
      # every element of the fact is a string,
      # and every element of the pattern is a symbol or literal.
      # literals must match both value and position.
      # symbols represent free or bound variables.
      # bound variables must match the word at its position.
      # free variables become bound.
      if(item.is_a? Symbol)
      
        if !new_bindings[item]
          # don't bind the same word to multiple variables
          if new_bindings.key(@words[index])
            return false
          else
            # the variable at [index] is free
            # so we bind it and move on
            new_bindings[item] = @words[index]
            next
          end
        end
        
        if new_bindings[item] == @words[index]
          next
        else
          return false
        end
      
      elsif item.is_a? String
        if item != @words[index]
          return false
        end
      else
        raise "Patterns must consist of symbols or strings"
      end

    end # pattern.each_with_index
    # if we made it here, the pattern was a match.
    return new_bindings
  end
end

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

