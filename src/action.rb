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

