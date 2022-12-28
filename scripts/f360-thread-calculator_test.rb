require 'minitest/autorun'
require_relative './f360-thread-calculator'

describe Fusion360::ThreadCalculator do
    before do
        @i = Fusion360::ThreadCalculator.with_tpi(22, :internal, 3, {significant_digits: 2})
        @e = Fusion360::ThreadCalculator.with_tpi(22, :external, 3, {significant_digits: 2})
    end

    describe 'public constructors' do
        describe '.with_tpi' do
            it 'returns a valid ThreadCalculator object' do
                o = Fusion360::ThreadCalculator.with_tpi(22, :internal, 22)
                assert o.valid?
            end
            it 'sets options when passed' do
                significant_digits = 10
                o = Fusion360::ThreadCalculator.with_tpi(22, :internal, 22, {significant_digits: significant_digits})
                assert_equal significant_digits, o.significant_digits
            end
        end

        describe '.with_pitch' do
            it 'returns a valid ThreadCalculator object' do
                o = Fusion360::ThreadCalculator.with_pitch(1.2, :internal, 22)
                assert o.valid?
            end
            it 'passes along options to private constructor' do
                significant_digits = 10
                o = Fusion360::ThreadCalculator.with_pitch(22, :internal, 22, {significant_digits: significant_digits})
                assert_equal significant_digits, o.significant_digits
            end
        end
    end

    describe '#add_offsets' do
        it 'adds a single offset' do
            @i.add_offsets(0.1)
            assert_equal [0.0, 0.1], @i.offsets
            assert @i.valid?
        end

        it 'adds as many offsets as you provide in the arguments' do
            @i.add_offsets(0.1, 0.2, 0.4)
            assert_equal [0.0, 0.1, 0.2, 0.4], @i.offsets
            assert @i.valid?
        end
    end

    describe '#tpi_to_pitch' do
        it 'takes threads per inch and calculates pitch in mm' do
            assert_equal 5.08, @i.tpi_to_pitch(5)
        end
    end

    describe '#gender=' do
        it 'raises GenderError with diasllowed genders' do
            assert_raises(Fusion360::ThreadCalculator::GenderError) do
                 @i.gender = :FAKE_GENDER
            end
        end
    end

    describe '#thread_designation' do
        it 'returns a string representation of the F360 thread designation' do
            assert_equal "3x1.15", @i.thread_designation
        end
    end

    describe '#calculate_for_offsets' do
        it 'returns an array of hashes' do
            @i.add_offsets(0.1)
            result = @i.calculate_for_offsets
            assert result.is_a?(Array)
            assert result.all?(Hash)
        end
    end

    describe '#calculate_values_with_offset' do
        it 'returns a hash' do
            assert @i.calculate_values_with_offset.is_a?(Hash)
        end
        it 'internal threads: returns correct hash' do
            expected = {
                gender: :internal,
                minor_dia: 3,
                major_dia: 4.25,
                pitch_dia: 3.5,
                tap_drill: 3,
                class: 0
            }
            assert_equal expected, @i.calculate_values_with_offset
        end
        it 'external threads: returns correct hash' do
            expected = {
                gender: :external,
                class: 0,
                major_dia: 3,
                pitch_dia: 2.25,
                minor_dia:1.59
            }
            assert_equal expected, @e.calculate_values_with_offset
        end
    end

    describe '#internal_major_diameter' do
        it 'calculates the major diameter for an internal thread' do
            assert_equal 4.25, @i.internal_major_diameter
        end
        it 'applies an offset' do
            assert_equal 4.35, @i.internal_major_diameter(0.1)
        end
    end

    describe '#internal_pitch_diameter' do
        # FYI: This calls out to #internal_major_diameter
        it 'calculates the pitch diameter for an internal thread' do
            assert_equal 3.50, @i.internal_pitch_diameter
        end

        it 'applies an offset' do
            assert_equal 3.60, @i.internal_pitch_diameter(0.1)
        end
    end

    describe '#external_pitch_diameter' do
        it 'calculates the pitch diameter for an external thread' do
            assert_equal 2.25, @e.external_pitch_diameter
        end
        it 'applies an offset' do
            assert_equal 2.15, @e.external_pitch_diameter(0.1)
        end
    end

    describe '#external_minor_diameter' do
        it 'calculates the minor diameter for an external thread' do
            assert_equal 1.59, @e.external_minor_diameter
        end
        it 'applies an offset' do
            assert_equal 1.49, @e.external_minor_diameter(0.1)
        end
    end
end