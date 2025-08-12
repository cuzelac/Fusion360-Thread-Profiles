# frozen_string_literal: true

require 'logger'
require 'stringio'
require 'rexml/document'
require 'rexml/formatters/pretty'
require_relative '../scripts/f360-thread-calculator'

module GenerateThreads
  class ConfigurationError < StandardError; end
  class ValidationError < StandardError; end
  class AngleMismatchError < StandardError; end
  class XmlParseError < StandardError; end
  class IoError < StandardError; end

  module ExitCodes
    USAGE = 64
    DATA = 65
    XML_PARSE = 66
    ANGLE_MISMATCH = 67
    IO = 74
  end

  class App
    DEFAULT_OFFSETS = [0.0, 0.1, 0.2, 0.3, 0.4].freeze

    def initialize(logger: Logger.new($stderr))
      @logger = logger
    end

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
          result = merge_into_doc(doc, calculator, angle)
          return pretty_print(result)
        else
          doc = build_new_doc(options, angle)
          result = merge_into_doc(doc, calculator, angle)
          return pretty_print(result)
        end
      else
        doc = build_new_doc(options, angle)
        result = merge_into_doc(doc, calculator, angle)
        return pretty_print(result)
      end
    end

    private

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

    def build_new_doc(options, angle)
      doc = REXML::Document.new
      root = doc.add_element('ThreadType')
      root.add_element('Name').text = options[:name] || 'Generated Threads'
      root.add_element('CustomName').text = options[:custom_name] || 'Generated Threads'
      root.add_element('Unit').text = 'mm'
      root.add_element('Angle').text = format('%.1f', angle.to_f)
      root.add_element('SortOrder').text = (options[:sort_order] || 3).to_s
      doc
    end

    def derive_pitch!(options)
      got_pitch = options.key?(:pitch)
      got_tpi = options.key?(:tpi)
      raise ConfigurationError, 'Exactly one of --pitch or --tpi is required' if got_pitch == got_tpi

      if got_pitch
        pitch = options[:pitch].to_f
        raise ValidationError, '--pitch must be > 0' unless pitch.positive?
        pitch
      else
        tpi = options[:tpi].to_f
        raise ValidationError, '--tpi must be > 0' unless tpi.positive?
        (25.4 / tpi).round(2)
      end
    end

    def validate_required_flags!(options)
      raise ConfigurationError, '--angle is required' unless options[:angle].is_a?(Numeric)
      raise ConfigurationError, '--diameter is required' unless options[:diameter].is_a?(Numeric)
      raise ConfigurationError, 'Exactly one of --internal or --external is required' unless [:internal, :external].include?(options[:gender])

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
    end

    def build_calculator(pitch, gender, diameter)
      Fusion360::ThreadCalculator.with_pitch(pitch, gender, diameter)
    end

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

    def merge_into_doc(doc, calculator, angle)
      size_value = format('%.2f', nominal_size_for(calculator))
      pitch_value = format('%.2f', calculator.pitch)
      designation_text = "#{size_value}x#{pitch_value}"

      root = doc.root
      size_node = find_or_create_child_with_text(root, 'ThreadSize', 'Size', size_value)
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

    def pretty_print(doc)
      formatter = REXML::Formatters::Pretty.new(2)
      formatter.compact = true
      out = StringIO.new
      formatter.write(doc, out)
      out.string + "\n"
    end

    # XML helpers
    def read_xml!(path)
      content = File.read(path)
      REXML::Document.new(content)
    rescue Errno::ENOENT, Errno::EACCES => e
      raise IoError, e.message
    rescue REXML::ParseException => e
      raise XmlParseError, e.message
    end

    def find_or_create_child(parent, name)
      parent.elements[name] || parent.add_element(name)
    end

    def find_or_create_child_with_text(parent, container_name, child_name, text)
      parent.each_element(container_name) do |node|
        return node if text_of(node, child_name) == text
      end
      node = parent.add_element(container_name)
      node.add_element(child_name).text = text
      node
    end

    def set_or_update_text(parent, name, text)
      if (el = parent.elements[name])
        el.text = text
      else
        parent.add_element(name).text = text
      end
    end

    def text_of(parent, name)
      el = parent.elements[name]
      el&.text&.strip
    end

    def normalize_angle(value)
      ('%.1f' % value.to_f)
    end

    def find_thread(designation_node, gender_text, class_label)
      designation_node.each_element('Thread') do |thr|
        if text_of(thr, 'Gender') == gender_text && text_of(thr, 'Class') == class_label
          return thr
        end
      end
      nil
    end

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


