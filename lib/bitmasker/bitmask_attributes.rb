module Bitmasker
  class BitmaskAttributes
    include ActiveModel::AttributeMethods
    attribute_method_suffix '?'
    attribute_method_suffix '='
    attribute_method_suffix '_was'

    class_attribute :bitmask_attributes
    class_attribute :defaults
    class_attribute :model_class
    class_attribute :field_name

    def self.make(model_class, field_name, attrs, prefix = "", defaults = {})
      klass = Class.new(self) do
        define_attribute_methods attrs.keys

        if prefix.present?
          attrs.keys.each do |key|
            alias_attribute "#{prefix}#{key}", key
          end
        end
      end

      klass.model_class = model_class
      klass.bitmask_attributes = attrs.stringify_keys
      klass.defaults = defaults.stringify_keys
      klass.field_name = field_name

      def klass.to_s
        "#{superclass}(#{model_class}##{field_name})"
      end

      klass
    end

    def self.value_to_boolean(value)
      model_class.value_to_boolean(value)
    end

    attr_reader :model, :bitmask
    def initialize(model)
      @model = model
      @bitmask = Bitmask.new(bitmask_attributes, read || defaults)
    end

    def attribute(attribute)
      bitmask.get attribute
    end
    alias_method :attribute?, :attribute

    def attribute=(attribute, value)
      bitmask.set attribute, self.class.value_to_boolean(value)
      write
    end

    def attribute_was(attribute)
      Bitmask.new(bitmask_attributes, was).get attribute
    end

    def from_array(array)
      bitmask.set_array(Array(array).map(&:to_s).map(&:presence).compact)
      write
    end

    def to_a
      bitmask.to_a
    end

    def <<(attr)
      send(:attribute=, attr.to_s, true)
    end

    # Methods for the model

    def read
      model[field_name]
    end

    def write
      model[field_name] = bitmask.to_i
    end

    def was
      model.attribute_was field_name
    end
  end
end
