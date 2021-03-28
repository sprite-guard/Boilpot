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

