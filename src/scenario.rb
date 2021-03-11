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

