require 'test_helper'

class IntegrationModel

  attr_accessor :dummy_mask
  attr_accessor :another_dummy_mask
  attr_accessor :something_mask

  extend Bitmasker::Model

  def []=(sym, value)
    send "#{ sym }=", value
  end

  def [](sym)
    send sym
  end

  def self.accessible_attrs
    @@accessible_attrs
  end

  def accessible_attrs
    @@accessible_attrs
  end

  def self.attr_accessible(*args)
    @@accessible_attrs ||= []
    @@accessible_attrs += args
  end


  has_bitmask_attributes :dummy do |config|
    config.attribute :does_stuff, 0b0001
    config.attribute :with_default, 0b0010, true
  end

  has_bitmask_attributes :another_dummy do |config|
    config.attribute :an_accessible_attribute, 0b001
    config.accessible
  end

  has_bitmask_attributes :something, "with_prefix_" do |config|
    config.attribute :is_cool, 1 << 0
  end
end


class BitmaskAttributesTest < MiniTest::Unit::TestCase

  def test_does_stuff_attribute
    mock = IntegrationModel.new
    assert mock.dummy
    assert !mock.does_stuff?
    mock.does_stuff = true
    assert mock.does_stuff?
  end

  def test_default
    mock = IntegrationModel.new
    assert mock.with_default?, "should have a default: mock.dummy_mask is #{ mock.dummy_mask.inspect } mock.dummy is #{ mock.dummy.inspect }"
    mock.with_default = false
    assert !mock.with_default?, 'setting method after default failed'
  end

  def test_predicate_without_?
    mock = IntegrationModel.new
    mock.does_stuff = true
    assert mock.does_stuff
  end

  def test_accessible
    mock = IntegrationModel.new
    assert_equal [:an_accessible_attribute], mock.accessible_attrs
  end

  def test_prefix_accessors
    model = IntegrationModel.new
    assert !model.respond_to?(:is_cool)
    assert !model.respond_to?(:is_cool?)
    assert !model.respond_to?(:is_cool=)
    assert !model.respond_to?(:is_cool_was)

    assert model.respond_to?(:with_prefix_is_cool)
    assert model.respond_to?(:with_prefix_is_cool?)
    assert model.respond_to?(:with_prefix_is_cool=)
    assert model.respond_to?(:with_prefix_is_cool_was)
  end

  def test_assignment_with_push
    model = IntegrationModel.new

    assert !model.with_prefix_is_cool?

    model.something << :is_cool

    assert model.with_prefix_is_cool?
  end

  def test_array_assignment
    mock = IntegrationModel.new
    mock.dummy = ["does_stuff"]
    assert mock.does_stuff
    assert !mock.with_default
    mock.dummy = ["does_stuff", "with_default"] # should accept strings
    assert mock.does_stuff
    assert mock.with_default
  end

  def test_array_assignment_with_symbols
    mock = IntegrationModel.new
    mock.dummy = [:does_stuff]
    assert mock.does_stuff
    assert !mock.with_default
    mock.dummy = [:does_stuff, :with_default] # should accept strings
    assert mock.does_stuff
    assert mock.with_default
  end

  def test_empty_array_assignment
    mock = IntegrationModel.new
    mock.dummy = ["does_stuff"]
    assert mock.does_stuff
    mock.dummy = []
    assert !mock.does_stuff
    assert !mock.with_default
  end

  def test_array_assignment_with_empty_strings
    mock = IntegrationModel.new
    mock.dummy = ["", "does_stuff"]
    assert mock.does_stuff
    assert !mock.with_default
  end

  # not throwing exception because you can't run migrations when it does
  # def test_raises_without_field
  #   assert_raise ArgumentError do
  #     eval '
  #     class IntegrationModel
  #       extend ::BitmaskAttributes
  #
  #       has_bitmask_attributes :without_field do |config|
  #         config.attribute :none, 0b001
  #       end
  #     end
  #     '
  #   end
  # end
end
