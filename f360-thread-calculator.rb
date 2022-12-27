require 'logger'

$logger = Logger.new(STDERR)
$logger.level = Logger::INFO

class Fusion360
    class ThreadCalculator
        #TODO: this should probably be two classes: InternalThread & ExternalThread
        #      so I don't need to do case statements

        class GenderError < StandardError
        end

        MM_PER_INCH = 25.4
        ALLOWED_GENDERS = [:external, :internal]

        attr_accessor :pitch
        attr_accessor :gender
        attr_accessor :diameter

        def initialize(tpi, gender, diameter)
            @gender = gender
            @pitch = tpi_to_pitch(tpi)
            @diameter = diameter
             
            validate!
        end

        def validate!
            if !ALLOWED_GENDERS.include?(@gender)
                raise GenderError.new("gender must be one of #{ALLOWED_GENDERS}")
            end
        end

        def thread_designation
            return "#{@diameter}x#{@pitch}"
        end

        # TODO: Split to testable subroutines
        def calculate_values_with_offset(offset = 0)
            values = {}
            values[:pitch] = @pitch
            case @gender
            when :internal
                values[:minor_dia] = diameter + offset
                values[:major_dia] = (1.083 * values[:pitch]) + values[:minor_dia]
                values[:pitch_dia] = values[:major_dia] - (0.650 * values[:pitch])
                values[:tap_drill] = values[:minor_dia]
            when :external 
                values[:major_dia] = diameter - offset
                values[:pitch_dia] = values[:major_dia] - (0.650 * values[:pitch])
                values[:minor_dia] = values[:major_dia] - (1.227 * values[:pitch])
            end

            return values
        end

        def tpi_to_pitch(tpi)
            return MM_PER_INCH * 1/tpi
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

if __FILE__ == $PROGRAM_NAME
    input = {}

    print "tpi: "
    input[:tpi] = gets.chomp.to_f

    print "internal / external: "
    input[:gender] = gets.chomp.to_sym 

    print "diameter: "
    input[:diameter] = gets.chomp.to_f

    $logger.debug(input)

    t = Fusion360::ThreadCalculator.new(input[:tpi], input[:gender], input[:diameter])

    [0.0, 0.1, 0.2, 0.3].each do |offset|
        puts "offset #{offset}"
        simple_print_hash t.calculate_values_with_offset(offset)
    end
end
