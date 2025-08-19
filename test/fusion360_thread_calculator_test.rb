# frozen_string_literal: true

require 'minitest/autorun'

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'fusion360_thread_calculator'

class Fusion360ThreadCalculatorTest < Minitest::Test
  def setup
    @internal_calc = Fusion360::ThreadCalculator.with_tpi(22, :internal, 3, significant_digits: 2)
    @external_calc = Fusion360::ThreadCalculator.with_tpi(22, :external, 3, significant_digits: 2)
  end

  def test_public_constructors_with_tpi
    calc = Fusion360::ThreadCalculator.with_tpi(22, :internal, 22)
    assert calc.valid?
  end

  def test_public_constructors_with_tpi_and_options
    significant_digits = 10
    calc = Fusion360::ThreadCalculator.with_tpi(22, :internal, 22, significant_digits: significant_digits)
    assert_equal significant_digits, calc.significant_digits
  end

  def test_public_constructors_with_pitch
    calc = Fusion360::ThreadCalculator.with_pitch(1.2, :internal, 22)
    assert calc.valid?
  end

  def test_public_constructors_with_pitch_and_options
    significant_digits = 10
    calc = Fusion360::ThreadCalculator.with_pitch(22, :internal, 22, significant_digits: significant_digits)
    assert_equal significant_digits, calc.significant_digits
  end

  def test_add_offsets_single
    @internal_calc.add_offsets(0.1)
    assert_equal [0.0, 0.1], @internal_calc.offsets
    assert @internal_calc.valid?
  end

  def test_add_offsets_multiple
    @internal_calc.add_offsets(0.1, 0.2, 0.4)
    assert_equal [0.0, 0.1, 0.2, 0.4], @internal_calc.offsets
    assert @internal_calc.valid?
  end

  def test_tpi_to_pitch
    assert_equal 5.08, @internal_calc.tpi_to_pitch(5)
  end

  def test_gender_setter_raises_error_for_invalid_gender
    assert_raises(Fusion360::GenderError) do
      @internal_calc.gender = :FAKE_GENDER
    end
  end

  def test_thread_designation
    assert_equal "3x1.15", @internal_calc.thread_designation
  end

  def test_calculate_for_offsets_returns_array_of_hashes
    @internal_calc.add_offsets(0.1)
    result = @internal_calc.calculate_for_offsets
    assert result.is_a?(Array)
    assert result.all?(Hash)
  end

  def test_calculate_values_with_offset_returns_hash
    assert @internal_calc.calculate_values_with_offset.is_a?(Hash)
  end

  def test_calculate_values_with_offset_internal_threads
    expected = {
      gender: :internal,
      minor_dia: 3,
      major_dia: 4.25,
      pitch_dia: 3.5,
      tap_drill: 3,
      class: 0
    }
    assert_equal expected, @internal_calc.calculate_values_with_offset
  end

  def test_calculate_values_with_offset_external_threads
    expected = {
      gender: :external,
      class: 0,
      major_dia: 3,
      pitch_dia: 2.25,
      minor_dia: 1.59
    }
    assert_equal expected, @external_calc.calculate_values_with_offset
  end

  def test_internal_major_diameter
    assert_equal 4.25, @internal_calc.internal_major_diameter
  end

  def test_internal_major_diameter_with_offset
    assert_equal 4.35, @internal_calc.internal_major_diameter(0.1)
  end

  def test_internal_pitch_diameter
    assert_equal 3.50, @internal_calc.internal_pitch_diameter
  end

  def test_internal_pitch_diameter_with_offset
    assert_equal 3.60, @internal_calc.internal_pitch_diameter(0.1)
  end

  def test_external_pitch_diameter
    assert_equal 2.25, @external_calc.external_pitch_diameter
  end

  def test_external_pitch_diameter_with_offset
    assert_equal 2.15, @external_calc.external_pitch_diameter(0.1)
  end

  def test_external_minor_diameter
    assert_equal 1.59, @external_calc.external_minor_diameter
  end

  def test_external_minor_diameter_with_offset
    assert_equal 1.49, @external_calc.external_minor_diameter(0.1)
  end

  def test_private_constructor_not_accessible
    assert_raises(NoMethodError) do
      Fusion360::ThreadCalculator.new(:internal, 10, {})
    end
  end

  def test_valid_with_all_valid_values
    assert @internal_calc.valid?
  end

  def test_valid_with_missing_pitch
    @internal_calc.pitch = nil
    refute @internal_calc.valid?
  end

  def test_valid_with_missing_diameter
    @internal_calc.diameter = nil
    refute @internal_calc.valid?
  end

  def test_valid_with_invalid_offsets
    @internal_calc.instance_variable_set(:@offsets, [0.0, "invalid"])
    refute @internal_calc.valid?
  end

  def test_valid_with_invalid_significant_digits
    @internal_calc.instance_variable_set(:@significant_digits, "invalid")
    refute @internal_calc.valid?
  end

  def test_valid_with_invalid_gender
    @internal_calc.instance_variable_set(:@gender, :invalid)
    refute @internal_calc.valid?
  end
end
