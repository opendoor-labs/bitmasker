require 'test_helper'

class Bitmasker::BitmaskAttributesTest < MiniTest::Unit::TestCase

  LiveModel = Class.new do
    def self.value_to_boolean(value)
      !!value
    end

    def initialize(*)
      @attrs = {}
      @old_attrs = {}
    end

    def [](attr)
      @attrs.fetch(attr, 0)
    end

    def []=(name, value)
      @old_attrs[name] = @attrs[name] unless @old_attrs.present?
      @attrs[name] = value
    end

    def attribute_was(attr)
      @old_attrs.fetch(attr, 0)
    end
  end

  MockModel = Class.new do
    def self.value_to_boolean(value)
      !!value
    end

    def [](attribute)
      0
    end
  end

  def model_instance
    @model_instance ||= MockModel.new
  end

  def setup
    @klass = Bitmasker::BitmaskAttributes.make(
      MockModel, 'email_mask',
      send_weekly_email: 0b0001,
      send_monthly_newsletter: 0b0010,
    )
  end

  def subject
    @subject ||= @klass.new(model_instance)
  end

  def test_klass_to_s
    assert_equal "Bitmasker::BitmaskAttributes(Bitmasker::BitmaskAttributesTest::MockModel#email_mask)", @klass.to_s
  end

  def test_set_attribute
    model_instance.expects(:[]=).with('email_mask', 1)
    subject.send_weekly_email = true
    assert_equal true, subject.send_weekly_email
  end

  def test_read_attribute
    model_instance.expects(:[]).with('email_mask').returns(0)
    assert_equal false, subject.send_weekly_email
  end

  def test_read_attribute_with_true_value
    model_instance.expects(:[]).with('email_mask').returns(2)
    assert_equal true, subject.send_monthly_newsletter
  end

  def test_predicate
    model_instance.expects(:[]).with('email_mask').returns(2)
    assert_equal true, subject.send_monthly_newsletter?
  end

  def test_was
    model_instance.expects(:attribute_was).twice.with('email_mask').returns(1)
    assert_equal false, subject.send_monthly_newsletter_was
    assert_equal true, subject.send_weekly_email_was
  end

  def test_to_a
    model_instance.expects(:[]).with('email_mask').returns(2)
    assert_equal ['send_monthly_newsletter'], subject.to_a
  end

  def test_prefix_accessors
    @klass = Bitmasker::BitmaskAttributes.make(
      LiveModel, "role_mask",
      {
        manager: 0b0001,
        admin: 0b0010,
      },
      "has_role_"
    )

    subject = @klass.new(LiveModel.new)

    assert_equal false, subject.has_role_manager
    assert_equal false, subject.has_role_manager?

    subject.has_role_manager = true

    assert_equal true, subject.has_role_manager
    assert_equal true, subject.has_role_manager?
    assert_equal false, subject.has_role_manager_was

    assert_equal false, subject.has_role_admin
    assert_equal false, subject.has_role_admin?

    subject.has_role_admin = true

    assert_equal true, subject.has_role_admin
    assert_equal true, subject.has_role_admin?
    assert_equal false, subject.has_role_admin_was
  end
end
