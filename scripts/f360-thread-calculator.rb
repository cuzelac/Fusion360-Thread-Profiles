require 'logger'
require 'rexml'
require 'stringio'

$logger = Logger.new(STDERR)
$logger.level = Logger::DEBUG

# This is very preliminary and I don't recommend anybody use it yet

# TODO: good xml output
class Fusion360
    class ThreadCalculator
        class GenderError < StandardError
        end

        MM_PER_INCH = 25.4
        ALLOWED_GENDERS = [:external, :internal]

        attr_accessor :pitch, :diameter
        attr_reader :gender, :offsets, :significant_digits

        def self.with_tpi(tpi, gender, diameter, opts = {})
            calc = new(gender, diameter, opts)
            calc.pitch = calc.tpi_to_pitch(tpi)
            return calc
        end

        def self.with_pitch(pitch, gender, diameter, opts = {})
            calc = new(gender, diameter, opts)
            calc.pitch = pitch
            return calc
        end

        # do not use directly - use a class constructor method like
        # .with_tpi or .with_pitch instead
        def initialize(gender, diameter, opts)
            self.gender = gender
            @diameter = diameter
            @significant_digits = opts.fetch(:significant_digits, 2)
            @offsets = [0.0]
        end
        private_class_method :new

        def add_offsets(*offsets)
            @offsets += offsets
        end

        def valid?
            return false unless @pitch.is_a?(Numeric)
            return false unless @diameter.is_a?(Numeric)
            return false unless @offsets.all?(Numeric)
            return false unless @significant_digits.is_a?(Integer)
            return false unless ALLOWED_GENDERS.include?(@gender)
            return true
        end

        def gender=(gender)
            if !ALLOWED_GENDERS.include?(gender)
                raise GenderError.new("gender must be one of #{ALLOWED_GENDERS.map &:to_s}")
            end

            @gender = gender
        end

        def thread_designation
            return "#{@diameter}x#{@pitch}"
        end

        def calculate_for_offsets
            result = []
            @offsets.each do |offset|
                result << calculate_values_with_offset(offset)
            end

            return result
        end

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

            return values
        end

        def internal_major_diameter(offset = 0)
            minor_diameter = @diameter + offset
            result = 1.083 * @pitch + minor_diameter
            return result.round(@significant_digits)
        end

        def internal_pitch_diameter(offset = 0)
            major_diameter = internal_major_diameter(offset)
            result =  major_diameter - (0.650 * @pitch)
            return result.round(@significant_digits)
        end

        def external_pitch_diameter(offset = 0)
            major_diameter = @diameter - offset
            result = major_diameter - (0.650 * @pitch)
            return result.round(@significant_digits)
        end

        def external_minor_diameter(offset = 0)
            major_diameter = @diameter - offset
            result = major_diameter - (1.227 * @pitch)
            return result.round(@significant_digits)
        end

        def tpi_to_pitch(tpi)
            result = MM_PER_INCH * 1/tpi
            return result.round(@significant_digits)
        end
    end
end

def simple_print_hash(hash)
    puts "{"
    hash.each do |k,v|
        puts "    #{k} => #{v}"
    end
    puts "}"
end

# TODO: this is a POC of using REXML, needs work
def hash_to_xml(hash)
    xml = REXML::Document.new
    root = REXML::Element.new('Thread')
    xml.add(root)

    hash.each do |k,v|
        e = REXML::Element.new(k.to_s)
        e.push(REXML::Text.new(v.to_s))
        xml.root.add(e)
    end

    buf = StringIO.new

    formatter = REXML::Formatters::Pretty.new(4)
    formatter.compact = true
    formatter.write(xml, buf)

    return buf.string
end

# TODO: cli options instead of stdin input
if __FILE__ == $PROGRAM_NAME
    input = {}

#    print "tpi: "
#    input[:tpi] = gets.chomp.to_f
    print "pitch in mm: "
    input[:pitch] = gets.chomp.to_f

    print "internal / external: "
    input[:gender] = gets.chomp.to_sym 

    print "diameter: "
    input[:diameter] = gets.chomp.to_f

    $logger.debug(input)

#    t = Fusion360::ThreadCalculator.with_tpi(input[:tpi], input[:gender], input[:diameter])
    t = Fusion360::ThreadCalculator.with_pitch(input[:pitch], input[:gender], input[:diameter])
    t.add_offsets(0.1, 0.2, 0.3, 0.4)

    t.calculate_for_offsets.each do |result|
        simple_print_hash result
    end

end
