# frozen_string_literal: true

require 'logger'
require 'stringio'
require 'rexml/document'
require 'rexml/formatters/pretty'
require_relative 'fusion360_thread_calculator'

##
# Generates and merges Fusion 360 thread profile XML files.
#
# Public API is provided via `GenerateThreads::App#run`. Errors are surfaced as
# custom exceptions under the `GenerateThreads` namespace for the CLI to map to
# exit codes.
#
# This library targets Ruby 2.5 compatibility and uses stdlib only.
#
module GenerateThreads
  ##
  # Raised when configuration is invalid or mutually exclusive flags are used.
  class ConfigurationError < StandardError; end
  ##
  # Raised when provided values fail validation (e.g., non-positive pitch).
  class ValidationError < StandardError; end
  ##
  # Raised when the provided angle does not match an existing XML file's angle.
  class AngleMismatchError < StandardError; end
  ##
  # Raised when XML cannot be parsed.
  class XmlParseError < StandardError; end
  ##
  # Raised when file I/O fails (permissions, missing files, etc.).
  class IoError < StandardError; end

  module ExitCodes
    # Exit status for usage/argument errors
    USAGE = 64
    # Exit status for data/validation errors
    DATA = 65
    # Exit status for XML parse errors
    XML_PARSE = 66
    # Exit status for angle mismatches
    ANGLE_MISMATCH = 67
    # Exit status for I/O failures
    IO = 74
  end

  ##
  # Orchestrates thread calculations and XML read/merge/generation.
  #
  # Typical usage from a CLI:
  #   app = GenerateThreads::App.new(logger: Logger.new($stderr))
  #   xml = app.run(options)
  #   puts xml
  #
  class App
    DEFAULT_OFFSETS = [0.0, 0.1, 0.2, 0.3, 0.4].freeze

    # Creates a new application instance.
    #
    # @param logger [Logger] destination for diagnostic messages
    def initialize(logger: Logger.new($stderr))
      @logger = logger
    end

    # Computes thread values and returns pretty-printed XML.
    #
    # Expects an options hash with symbol keys, typically produced by `OptionParser`:
    # - :angle [Float] thread angle in degrees (required)
    # - :pitch [Float] pitch in mm (mutually exclusive with :tpi)
    # - :tpi [Float] threads per inch (mutually exclusive with :pitch)
    # - :diameter [Float] nominal diameter in mm (required)
    # - :gender [Symbol] either :internal or :external (required)
    # - :offsets [Array<Float>] non-negative axial offsets in mm
    # - :xml [String] path to an existing XML file to merge into, or a new file
    # - :name [String] root <Name> when creating a new XML file
    # - :custom_name [String] root <CustomName> when creating a new XML file
    # - :sort_order [Integer] root <SortOrder> when creating a new XML file
    # - :xml_comment [String] XML comment to insert in newly created ThreadSize elements
    #
    # @param options [Hash{Symbol=>Object}] configuration from the CLI
    # @return [String] pretty-printed XML document
    # @raise [ConfigurationError] when required/exclusive flags are invalid
    # @raise [ValidationError] when option values are invalid
    # @raise [AngleMismatchError] when merging into an XML with a different angle
    # @raise [XmlParseError] when XML parsing fails
    # @raise [IoError] when reading an XML file fails
    def run(options)
      validate_required_flags!(options)

      pitch = derive_pitch!(options)

      gender = options[:gender]
      diameter = options[:diameter]
      angle = options[:angle]
      offsets = (options[:offsets] && options[:offsets].any?) ? options[:offsets] : DEFAULT_OFFSETS

      calculator = build_calculator(pitch, gender, diameter)
      calculator.add_offsets(*offsets)

      # Determine XML behavior
      if options[:xml]
        if File.exist?(options[:xml])
          doc = read_xml!(options[:xml])
          validate_existing_doc!(doc, angle)
          result = merge_into_doc(doc, calculator, angle, options)
          return pretty_print(result)
        else
          doc = build_new_doc(options, angle)
          result = merge_into_doc(doc, calculator, angle, options)
          return pretty_print(result)
        end
      else
        doc = build_new_doc(options, angle)
        result = merge_into_doc(doc, calculator, angle, options)
        return pretty_print(result)
      end
    end

    private

    # Validates invariants of an existing document before merging.
    #
    # @param doc [REXML::Document] parsed XML document
    # @param angle [Numeric] expected angle in degrees
    # @return [void]
    # @raise [XmlParseError] when the root element is not ThreadType
    # @raise [ValidationError] when required fields are missing/invalid
    # @raise [AngleMismatchError] when angle differs from provided value
    def validate_existing_doc!(doc, angle)
      root = doc.root
      raise XmlParseError, 'Root element must be <ThreadType>' unless root && root.name == 'ThreadType'

      unit = text_of(root, 'Unit')
      raise ValidationError, 'Existing XML must have <Unit>mm</Unit>' unless unit == 'mm'

      existing_angle = text_of(root, 'Angle').to_f
      if normalize_angle(existing_angle) != normalize_angle(angle)
        raise AngleMismatchError, "Angle mismatch: file=#{existing_angle} vs provided=#{angle}"
      end
    end

    # Builds a new XML document using provided options.
    #
    # @param options [Hash{Symbol=>Object}] creation options
    # @param angle [Numeric] angle in degrees
    # @return [REXML::Document]
    def build_new_doc(options, angle)
      doc = REXML::Document.new
      root = doc.add_element('ThreadType')
      root.add_element('Name').text = options[:name] || 'Generated Threads'
      root.add_element('CustomName').text = options[:custom_name] || options[:name] || 'Generated Threads'
      root.add_element('Unit').text = 'mm'
      root.add_element('Angle').text = format('%.1f', angle.to_f)
      root.add_element('SortOrder').text = (options[:sort_order] || 3).to_s
      doc
    end

    # Computes pitch from either :pitch or :tpi (mutually exclusive).
    #
    # @param options [Hash{Symbol=>Object}]
    # @return [Float] pitch in millimeters
    # @raise [ConfigurationError] when both or neither are provided
    # @raise [ValidationError] when provided values are non-positive
    def derive_pitch!(options)
      got_pitch = options.key?(:pitch)
      got_tpi = options.key?(:tpi)
      raise ConfigurationError, 'Exactly one of --pitch or --tpi is required' if got_pitch == got_tpi

      if got_pitch
        pitch = options[:pitch].to_f
        raise ValidationError, '--pitch must be > 0' unless pitch > 0
        pitch
      else
        tpi = options[:tpi].to_f
        raise ValidationError, '--tpi must be > 0' unless tpi > 0
        (25.4 / tpi).round(2)
      end
    end

    # Performs validation on the full options set.
    #
    # @param options [Hash{Symbol=>Object}]
    # @return [void]
    # @raise [ConfigurationError, ValidationError]
    def validate_required_flags!(options)
      raise ConfigurationError, '--angle is required' unless options[:angle].is_a?(Numeric)
      raise ConfigurationError, '--diameter is required' unless options[:diameter].is_a?(Numeric)
      raise ConfigurationError, 'Exactly one of --internal or --external is required' unless [:internal, :external].include?(options[:gender])

      # Validate numeric values are positive
      if options[:diameter].is_a?(Numeric) && options[:diameter] <= 0
        raise ValidationError, '--diameter must be > 0'
      end

      if options[:offsets]
        unless options[:offsets].is_a?(Array) && options[:offsets].all? { |o| o.is_a?(Numeric) && o >= 0 }
          raise ValidationError, '--offsets must be a comma-separated list of non-negative numbers'
        end
      end

      if options[:xml] && File.exist?(options[:xml])
        if options[:name] || options[:custom_name]
          raise ValidationError, '--name/--custom-name not allowed when merging into existing --xml file'
        end
      end

      if options[:xml_comment]
        if options[:xml_comment].include?('--')
          raise ValidationError, '--xml-comment text must not contain "--" (invalid in XML comments)'
        end
      end
    end

    # Creates a configured calculator instance.
    #
    # @param pitch [Float]
    # @param gender [Symbol]
    # @param diameter [Float]
    # @return [Fusion360::ThreadCalculator]
    def build_calculator(pitch, gender, diameter)
      Fusion360::ThreadCalculator.with_pitch(pitch, gender, diameter)
    end

    # Computes the nominal size used for the ThreadSize/Size value.
    #
    # @param calculator [Fusion360::ThreadCalculator]
    # @return [Float]
    def nominal_size_for(calculator)
      case calculator.gender
      when :internal
        # Use computed major diameter at offset 0
        calculator.internal_major_diameter(0)
      else
        # external: use input diameter
        calculator.diameter
      end.round(2)
    end

    # Merges computed values into the provided XML document.
    #
    # @param doc [REXML::Document]
    # @param calculator [Fusion360::ThreadCalculator]
    # @param angle [Numeric]
    # @return [REXML::Document]
    def merge_into_doc(doc, calculator, angle, options = {})
      size_value = format('%.2f', nominal_size_for(calculator))
      pitch_value = format('%.2f', calculator.pitch)
      designation_text = "#{size_value}x#{pitch_value}"

      root = doc.root
      size_node, was_created = find_or_create_child_with_text(root, 'ThreadSize', 'Size', size_value)
      
      # Add XML comment if this is a newly created ThreadSize and comment is provided
      if options[:xml_comment] && was_created
        comment = REXML::Comment.new(options[:xml_comment])
        size_node.insert_before(size_node.elements['Size'], comment)
        @logger.debug("Added XML comment to newly created ThreadSize: #{options[:xml_comment]}") if @logger
      end
      
      designation_node = find_or_create_child(size_node, 'Designation')
      set_or_update_text(designation_node, 'ThreadDesignation', designation_text)
      set_or_update_text(designation_node, 'CTD', designation_text)
      set_or_update_text(designation_node, 'Pitch', pitch_value)

      calculator.offsets.each do |offset|
        values = calculator.calculate_values_with_offset(offset)
        class_label = class_label_for(offset)
        gender_text = values[:gender].to_s

        thread_node = find_thread(designation_node, gender_text, class_label) || designation_node.add_element('Thread')
        set_or_update_text(thread_node, 'Gender', gender_text)
        set_or_update_text(thread_node, 'Class', class_label)
        set_or_update_text(thread_node, 'MajorDia', format('%.2f', values[:major_dia]))
        set_or_update_text(thread_node, 'PitchDia', format('%.2f', values[:pitch_dia]))
        set_or_update_text(thread_node, 'MinorDia', format('%.2f', values[:minor_dia]))
        if values[:gender] == :internal
          set_or_update_text(thread_node, 'TapDrill', format('%.2f', values[:tap_drill]))
        end
      end

      doc
    end

    # Produces a compact, pretty-printed XML string.
    #
    # @param doc [REXML::Document]
    # @return [String]
    def pretty_print(doc)
      formatter = REXML::Formatters::Pretty.new(2)
      formatter.compact = true
      out = StringIO.new
      formatter.write(doc, out)
      out.string + "\n"
    end

    # XML helpers
    # Reads and parses XML from disk.
    #
    # @param path [String]
    # @return [REXML::Document]
    # @raise [IoError] when file read fails
    # @raise [XmlParseError] when XML is invalid
    def read_xml!(path)
      content = File.read(path)
      REXML::Document.new(content)
    rescue Errno::ENOENT, Errno::EACCES => e
      raise IoError, e.message
    rescue REXML::ParseException => e
      raise XmlParseError, e.message
    end

    # Finds an existing child node or creates it.
    #
    # @param parent [REXML::Element]
    # @param name [String]
    # @return [REXML::Element]
    def find_or_create_child(parent, name)
      parent.elements[name] || parent.add_element(name)
    end

    # Finds a container element with a specific child text, or creates one.
    #
    # @param parent [REXML::Element]
    # @param container_name [String]
    # @param child_name [String]
    # @param text [String]
    # @return [Array<REXML::Element, Boolean>] [element, was_created]
    def find_or_create_child_with_text(parent, container_name, child_name, text)
      parent.each_element(container_name) do |node|
        return [node, false] if text_of(node, child_name) == text
      end
      node = parent.add_element(container_name)
      node.add_element(child_name).text = text
      [node, true]
    end

    # Sets text of a child element, creating the element when needed.
    #
    # @param parent [REXML::Element]
    # @param name [String]
    # @param text [String]
    # @return [void]
    def set_or_update_text(parent, name, text)
      if (el = parent.elements[name])
        el.text = text
      else
        parent.add_element(name).text = text
      end
    end

    # Returns stripped text content of a child element, if present.
    #
    # @param parent [REXML::Element]
    # @param name [String]
    # @return [String, nil]
    def text_of(parent, name)
      el = parent.elements[name]
      el&.text&.strip
    end

    # Normalizes an angle value to one decimal-place string.
    #
    # @param value [Numeric, String]
    # @return [String]
    def normalize_angle(value)
      ('%.1f' % value.to_f)
    end

    # Locates a thread node that matches gender and class label.
    #
    # @param designation_node [REXML::Element]
    # @param gender_text [String]
    # @param class_label [String]
    # @return [REXML::Element, nil]
    def find_thread(designation_node, gender_text, class_label)
      designation_node.each_element('Thread') do |thr|
        if text_of(thr, 'Gender') == gender_text && text_of(thr, 'Class') == class_label
          return thr
        end
      end
      nil
    end

    # Formats a class label like "O0.1" or "O.1" for zero-leading decimals.
    #
    # @param offset [Numeric]
    # @return [String]
    def class_label_for(offset)
      formatted = format('%.1f', offset.to_f)
      if formatted.start_with?('0.')
        "O.#{formatted[2..-1]}"
      else
        "O#{formatted}"
      end
    end
  end
end


