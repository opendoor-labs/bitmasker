module Bitmasker
  class Generator
    def initialize(mask_name, model, attribute_prefix = "")
      @bitmask_attributes = {}
      @bitmask_defaults = {}

      @model = model
      @mask_name = mask_name
      @field_name = mask_name.to_s + '_mask'

      @attribute_prefix = attribute_prefix

      @scope_name = mask_name.to_s + '_scope'

      @use_attr_accessible = false
    end


    attr_writer :method_format
    # makes the config dsl more consistent, allowing `config.method_format '%s'`
    # instead of `config.method_format = '%s'`
    alias_method :method_format, :method_format=


    attr_writer :field_name
    # makes the config dsl more consistent
    alias_method :field_name, :field_name=

    def attribute(name, mask, default = nil)
      @bitmask_attributes[name] = mask
      @bitmask_defaults[name] = default unless default.nil?
    end

    def accessible
      @use_attr_accessible = true
    end

    def generate
      klass = BitmaskAttributes.make(
        @model,
        @field_name,
        @bitmask_attributes,
        @attribute_prefix,
        @bitmask_defaults
      )
      scope_klass = BitmaskScope.make(@model, @field_name, @mask_name, @bitmask_attributes)

      @model.send :define_method, @mask_name do
        klass.new(self)
      end

      mask_name = @mask_name
      field_name = @field_name

      @model.singleton_class.send :define_method, @field_name do |*names|
        names = names.each_with_object({}) { |name, hsh| hsh[name.to_s] = true }
        Bitmask.new(klass.bitmask_attributes, names)
      end

      @model.send :define_method, :"has_#{@mask_name}?" do |*names|
        other = self.class.send(field_name, *names).to_i
        (send(field_name).to_i & other.to_i) == other.to_i
      end

      @model.send :define_method, :"has_any_#{@mask_name}?" do |*names|
        other = self.class.send(field_name, *names).to_i
        (send(field_name).to_i & other.to_i) > 0
      end

      @model.send :define_method, :"#{@mask_name}=" do |attrs|
        send(mask_name).from_array(attrs)
      end

      @model.singleton_class.send :define_method, @scope_name do
        scope_klass.new
      end

      @model.singleton_class.delegate "with_#{@mask_name}",
        "without_#{@mask_name}", "with_any_#{@mask_name}",
        to: @scope_name

      @bitmask_attributes.each do |attribute, mask|
        meth = "#{@attribute_prefix}#{attribute}".to_sym
        @model.delegate meth, :"#{meth}?", :"#{meth}=", :"#{meth}_was",
          to: @mask_name

        @model.attr_accessible meth if @use_attr_accessible
      end
    end

  end
end
