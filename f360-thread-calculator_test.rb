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
            it 'passes along options to private constructor'
        end

        describe '.with_pitch' do
            it 'returns a valid ThreadCalculator object' do
                o = Fusion360::ThreadCalculator.with_pitch(1.2, :internal, 22)
                assert o.valid?
            end
            it 'passes along options to private constructor'
        end
    end

    describe 'private constructor' do
        it 'sets significant digits for calculations'
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