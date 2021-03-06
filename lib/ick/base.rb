$:.unshift File.dirname(__FILE__)

require 'singleton'

module Ick
  
  class Base
    include Singleton
    
    def returns(value, result)
      raise 'implemented by subclass or by calling meta-method'
    end
    
    def evaluate(value, proc)
      raise 'implemented by subclass or by calling meta-method'
    end
    
    def invoke(value, &proc)
      result = evaluate(value, proc)
      returns(value, result)
    end
    
    def self.evaluates_in_calling_environment
      define_method :evaluate do |value, proc|
        proc.call(value)
      end
      true
    end
    
    def self.evaluates_in_value_environment
      define_method :evaluate do |value, proc|
        value.instance_eval(&proc)
      end
      true
    end
    
    def self.returns_value
      define_method :returns do |value, result|
        value
      end
      true
    end
    
    def self.returns_result
      define_method :returns do |value, result|
        result
      end
      true
    end
  
    #snarfed from Ruby On Rails
    def self.underscore(camel_cased_word)
      camel_cased_word.to_s.gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        tr("-", "_").
        downcase
    end
    
    def self.belongs_to clazz
      method_name = self.underscore(self.name.split('::')[-1])
      unless clazz.method_defined?(method_name)
        clazz.class_eval " 
          def #{method_name}(value=self,&proc)
            if block_given?
              #{self.name}.instance.invoke(value, &proc)
            else
              Invoker.new(value, #{self.name})
            end
          end"
      end
    end
    
  end
  
  class Invoker
    
    instance_methods.reject { |m| m =~ /^__|object_id/ }.each { |m| undef_method m }
  
    def initialize(value, clazz)
      @value = value
      @clazz = clazz
    end
    
    def method_missing(sym, *args, &block)
      @clazz.instance.invoke(@value) { |value|
        value.__send__(sym, *args, &block)
      }
    end
  
  end
    
  class Let < Base
    evaluates_in_calling_environment and returns_result
  end

  class Returning < Base
    evaluates_in_calling_environment and returns_value
  end

  class My < Base
    evaluates_in_value_environment and returns_result
  end

  class Inside < Base
    evaluates_in_value_environment and returns_value
  end
  
end