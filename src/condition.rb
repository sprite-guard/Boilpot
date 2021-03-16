
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
      return true
    else
      return false
    end
  end
  
  def parent=(scene)
    @parent = scene
    if(@tail)
      @tail.parent = scene
    end
  end

end

