# frozen_string_literal: true

require 'logger'

##
# Calculates thread dimensions for Fusion 360 thread profiles.
#
# This class provides methods to calculate major, minor, and pitch diameters
# for both internal and external threads with configurable offsets.
#
module Fusion360
  ##
  # Raised when an invalid gender is specified for thread calculations.
  class GenderError < StandardError; end

  ##
  # Calculates thread dimensions based on pitch, gender, and diameter.
  #
  # @example Creating a calculator with pitch
  #   calc = Fusion360::ThreadCalculator.with_pitch(1.25, :internal, 10.0)
  #   calc.add_offsets(0.1, 0.2)
  #   values = calc.calculate_values_with_offset(0.1)
  #
  # @example Creating a calculator with TPI
  #   calc = Fusion360::ThreadCalculator.with_tpi(20, :external, 8.0)
  #   calc.add_offsets(0.0, 0.1, 0.2)
  #   results = calc.calculate_for_offsets
  #
  class ThreadCalculator
    MM_PER_INCH = 25.4
    ALLOWED_GENDERS = [:external, :internal].freeze

    attr_accessor :pitch, :diameter
    attr_reader :gender, :offsets, :significant_digits

    # Creates a calculator instance with TPI (threads per inch).
    #
    # @param tpi [Float] threads per inch
    # @param gender [Symbol] either :internal or :external
    # @param diameter [Float] nominal diameter in mm
    # @param opts [Hash{Symbol=>Object}] options
    # @option opts [Integer] :significant_digits (2) decimal places for results
    # @return [Fusion360::ThreadCalculator] configured calculator
    # @raise [GenderError] when gender is not :internal or :external
    def self.with_tpi(tpi, gender, diameter, opts = {})
      calc = new(gender, diameter, opts)
      calc.pitch = calc.tpi_to_pitch(tpi)
      calc
    end

    # Creates a calculator instance with pitch.
    #
    # @param pitch [Float] pitch in mm
    # @param gender [Symbol] either :internal or :external
    # @param diameter [Float] nominal diameter in mm
    # @param opts [Hash{Symbol=>Object}] options
    # @option opts [Integer] :significant_digits (2) decimal places for results
    # @return [Fusion360::ThreadCalculator] configured calculator
    # @raise [GenderError] when gender is not :internal or :external
    def self.with_pitch(pitch, gender, diameter, opts = {})
      calc = new(gender, diameter, opts)
      calc.pitch = pitch
      calc
    end

    # Do not use directly - use a class constructor method like
    # .with_tpi or .with_pitch instead.
    #
    # @param gender [Symbol] thread gender
    # @param diameter [Float] nominal diameter in mm
    # @param opts [Hash{Symbol=>Object}] options
    # @raise [GenderError] when gender is invalid
    def initialize(gender, diameter, opts)
      self.gender = gender
      @diameter = diameter
      @significant_digits = opts.fetch(:significant_digits, 2)
      @offsets = [0.0]
    end
    private_class_method :new

    # Adds offset values for thread class calculations.
    #
    # @param offsets [Float] one or more offset values in mm
    # @return [void]
    def add_offsets(*offsets)
      @offsets += offsets
    end

    # Checks if the calculator is in a valid state.
    #
    # @return [Boolean] true if all required values are set and valid
    def valid?
      return false unless @pitch.is_a?(Numeric)
      return false unless @diameter.is_a?(Numeric)
      return false unless @offsets.all?(Numeric)
      return false unless @significant_digits.is_a?(Integer)
      return false unless ALLOWED_GENDERS.include?(@gender)
      true
    end

    # Sets the thread gender.
    #
    # @param gender [Symbol] either :internal or :external
    # @raise [GenderError] when gender is not allowed
    def gender=(gender)
      unless ALLOWED_GENDERS.include?(gender)
        raise GenderError, "gender must be one of #{ALLOWED_GENDERS.map(&:to_s)}"
      end

      @gender = gender
    end

    # Returns the thread designation string.
    #
    # @return [String] format "diameterxpitch" (e.g., "10x1.25")
    def thread_designation
      "#{@diameter}x#{@pitch}"
    end

    # Calculates thread values for all configured offsets.
    #
    # @return [Array<Hash>] array of calculation results for each offset
    def calculate_for_offsets
      result = []
      @offsets.each do |offset|
        result << calculate_values_with_offset(offset)
      end

      result
    end

    # Calculates thread dimensions for a specific offset.
    #
    # @param offset [Float] axial offset in mm (default: 0.0)
    # @return [Hash{Symbol=>Object}] calculated thread dimensions
    def calculate_values_with_offset(offset = 0)
      values = {}
      values[:gender] = @gender
      values[:class] = offset
      case @gender
      when :internal
        values[:minor_dia] = (diameter + offset).round(@significant_digits)
        values[:major_dia] = internal_major_diameter(offset)
        values[:pitch_dia] = internal_pitch_diameter(offset)
        values[:tap_drill] = values[:minor_dia]
      when :external
        values[:major_dia] = (diameter - offset).round(@significant_digits)
        values[:pitch_dia] = external_pitch_diameter(offset)
        values[:minor_dia] = external_minor_diameter(offset)
      end

      values
    end

    # Calculates the major diameter for an internal thread.
    #
    # @param offset [Float] axial offset in mm (default: 0.0)
    # @return [Float] major diameter in mm
    def internal_major_diameter(offset = 0)
      minor_diameter = @diameter + offset
      result = 1.083 * @pitch + minor_diameter
      result.round(@significant_digits)
    end

    # Calculates the pitch diameter for an internal thread.
    #
    # @param offset [Float] axial offset in mm (default: 0.0)
    # @return [Float] pitch diameter in mm
    def internal_pitch_diameter(offset = 0)
      major_diameter = internal_major_diameter(offset)
      result = major_diameter - (0.650 * @pitch)
      result.round(@significant_digits)
    end

    # Calculates the pitch diameter for an external thread.
    #
    # @param offset [Float] axial offset in mm (default: 0.0)
    # @return [Float] pitch diameter in mm
    def external_pitch_diameter(offset = 0)
      major_diameter = @diameter - offset
      result = major_diameter - (0.650 * @pitch)
      result.round(@significant_digits)
    end

    # Calculates the minor diameter for an external thread.
    #
    # @param offset [Float] axial offset in mm (default: 0.0)
    # @return [Float] minor diameter in mm
    def external_minor_diameter(offset = 0)
      major_diameter = @diameter - offset
      result = major_diameter - (1.227 * @pitch)
      result.round(@significant_digits)
    end

    # Converts TPI to pitch in millimeters.
    #
    # @param tpi [Float] threads per inch
    # @return [Float] pitch in mm
    def tpi_to_pitch(tpi)
      result = MM_PER_INCH * 1.0 / tpi
      result.round(@significant_digits)
    end
  end
end
