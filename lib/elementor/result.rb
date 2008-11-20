module Elementor
  class Result
    attr_reader :context, :opts
    
    def initialize(context, opts={}, &block)
      @opts = opts
      @context = context
      block.call(naming_context)
    end
    
    def naming_context
      @naming_context ||= blank_context(:this => self) do
        def method_missing(sym, *args)
          @this.element_names[sym] = *args
        end
      end
    end

    def dispatcher
      @dispatcher ||= blank_context(:this => self, :doc => doc) do
        def method_missing(sym, *args, &block)
          @this.try(sym, *args, &block) || @doc.try(sym, *args, &block) || super
        end
      end
    end
  
    def define_elements!
      element_names.each do |name, selector|
        meta_def(name) do |*mutators|
          set = ElementSet.new(doc.search(selector).to_ary)
          mutators.empty? ? set : mutators.inject(set) { |result, fn| fn[result] }
        end
      end
    end
    
    def element_names
      @element_names ||= { }
    end
    
    private
    
    def doc
      @doc ||= Nokogiri(context.send(opts[:from] || :body)) rescue nil
    end
  end
end