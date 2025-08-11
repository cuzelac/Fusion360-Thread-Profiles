require 'minitest/autorun'
require 'fileutils'

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'generate_threads'
require_relative '../scripts/f360-thread-calculator'

class GenerateThreadsTest < Minitest::Test
  def setup
    @logger = Logger.new(StringIO.new)
    @app = GenerateThreads::App.new(logger: @logger)
  end

  def test_new_document_generation_internal
    xml = @app.run(angle: 60.0, pitch: 0.90, diameter: 9.45, gender: :internal, offsets: [0.0, 0.1])
    assert_includes xml, '<ThreadType>'
    assert_includes xml, '<Unit>mm</Unit>'
    assert_includes xml, '<Angle>60.0</Angle>'
    assert_includes xml, '<Size>10.42</Size>' # internal nominal uses major at 0.0
    assert_includes xml, '<Pitch>0.90</Pitch>'
    assert_includes xml, '<ThreadDesignation>10.42x0.90</ThreadDesignation>'
    assert_includes xml, '<Gender>internal</Gender>'
    assert_includes xml, '<Class>O.0</Class>'
    assert_includes xml, '<Class>O.0</Class>'
    assert_includes xml, '<Class>O.1</Class>'
  end

  def test_tpi_path_calculates_pitch
    xml = @app.run(angle: 60.0, tpi: 25.4, diameter: 4.0, gender: :external, offsets: [0.0])
    assert_includes xml, '<Pitch>1.00</Pitch>'
    assert_includes xml, '<ThreadDesignation>4.00x1.00</ThreadDesignation>'
  end

  def test_merge_into_existing_enforces_angle_and_unit
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'base.xml')
      File.write(path, <<~XML)
        <ThreadType>
          <Name>X</Name>
          <CustomName>X</CustomName>
          <Unit>mm</Unit>
          <Angle>60.0</Angle>
          <SortOrder>3</SortOrder>
        </ThreadType>
      XML

      xml = @app.run(angle: 60.0, pitch: 0.9, diameter: 4.0, gender: :external, offsets: [0.0], xml: path)
      assert_includes xml, '<ThreadDesignation>4.00x0.90</ThreadDesignation>'
    end
  end

  def test_merge_rejects_angle_mismatch
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'base.xml')
      File.write(path, <<~XML)
        <ThreadType>
          <Name>X</Name>
          <CustomName>X</CustomName>
          <Unit>mm</Unit>
          <Angle>55.0</Angle>
          <SortOrder>3</SortOrder>
        </ThreadType>
      XML

      assert_raises(GenerateThreads::AngleMismatchError) do
        @app.run(angle: 60.0, pitch: 0.9, diameter: 4.0, gender: :external, offsets: [0.0], xml: path)
      end
    end
  end
end


