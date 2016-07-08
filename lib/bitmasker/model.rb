module Bitmasker
  module Model
    def has_bitmask_attributes(name, attribute_prefix = "")
      raise ArgumentError, "You must pass has_bitmask_attributes a block and define attributes." unless block_given?
      config = Generator.new(name, self, attribute_prefix)
      yield config
      config.generate
    end

    def value_to_boolean(value)
      if defined? ::ActiveRecord::ConnectionAdapters::Column::TRUE_VALUES
        ::ActiveRecord::ConnectionAdapters::Column::TRUE_VALUES.include? value
      else
        ['1', 1, 't', 'true', true].include? value
      end
    end
  end
end
