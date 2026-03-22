# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe Philiprehberger::EnvLoader do
  let(:tmpdir) { Dir.mktmpdir }

  after do
    FileUtils.rm_rf(tmpdir)
    %w[TEST_KEY TEST_HOST TEST_PORT TEST_DEBUG TEST_OTHER REQUIRED_KEY
       TEST_FLOAT TEST_BOOL_YES TEST_BOOL_ON TEST_BOOL_NO
       FIRST_KEY SECOND_KEY DEFAULT_ONLY].each { |k| ENV.delete(k) }
  end

  describe 'VERSION' do
    it 'has a version number' do
      expect(Philiprehberger::EnvLoader::VERSION).not_to be_nil
    end
  end

  describe '.load' do
    it 'loads variables from a .env file' do
      env_file = File.join(tmpdir, '.env')
      File.write(env_file, "TEST_KEY=hello\n")
      described_class.load(env_file)
      expect(ENV['TEST_KEY']).to eq('hello')
    end

    it 'handles quoted values' do
      env_file = File.join(tmpdir, '.env')
      File.write(env_file, "TEST_KEY=\"quoted value\"\n")
      described_class.load(env_file)
      expect(ENV['TEST_KEY']).to eq('quoted value')
    end

    it 'handles single-quoted values' do
      env_file = File.join(tmpdir, '.env')
      File.write(env_file, "TEST_KEY='single quoted'\n")
      described_class.load(env_file)
      expect(ENV['TEST_KEY']).to eq('single quoted')
    end

    it 'skips comments and blank lines' do
      env_file = File.join(tmpdir, '.env')
      File.write(env_file, "# comment\n\nTEST_KEY=value\n")
      described_class.load(env_file)
      expect(ENV['TEST_KEY']).to eq('value')
    end

    it 'later files take precedence' do
      file1 = File.join(tmpdir, '.env')
      file2 = File.join(tmpdir, '.env.local')
      File.write(file1, "TEST_KEY=first\n")
      File.write(file2, "TEST_KEY=second\n")
      described_class.load(file1, file2)
      expect(ENV['TEST_KEY']).to eq('second')
    end

    it 'does not override existing ENV values' do
      ENV['TEST_KEY'] = 'existing'
      env_file = File.join(tmpdir, '.env')
      File.write(env_file, "TEST_KEY=from_file\n")
      described_class.load(env_file)
      expect(ENV['TEST_KEY']).to eq('existing')
    end

    it 'applies default values' do
      env_file = File.join(tmpdir, '.env')
      File.write(env_file, "TEST_HOST=localhost\n")
      described_class.load(env_file, defaults: { 'TEST_PORT' => '3000' })
      expect(ENV['TEST_PORT']).to eq('3000')
    end

    it 'raises on missing required keys' do
      env_file = File.join(tmpdir, '.env')
      File.write(env_file, "TEST_KEY=value\n")
      expect {
        described_class.load(env_file, required: ['REQUIRED_KEY'])
      }.to raise_error(Philiprehberger::EnvLoader::ValidationError, /REQUIRED_KEY/)
    end

    it 'skips non-existent files' do
      result = described_class.load(File.join(tmpdir, 'nope.env'))
      expect(result).to eq({})
    end

    it 'applies type coercions' do
      env_file = File.join(tmpdir, '.env')
      File.write(env_file, "TEST_PORT=8080\nTEST_DEBUG=true\n")
      described_class.load(env_file, types: { 'TEST_PORT' => :integer, 'TEST_DEBUG' => :boolean })
      expect(ENV['TEST_PORT']).to eq('8080')
      expect(ENV['TEST_DEBUG']).to eq('true')
    end

    # --- Expanded tests ---

    it 'returns hash of loaded key-value pairs' do
      env_file = File.join(tmpdir, '.env')
      File.write(env_file, "TEST_KEY=hello\nTEST_HOST=localhost\n")
      result = described_class.load(env_file)
      expect(result).to include('TEST_KEY' => 'hello', 'TEST_HOST' => 'localhost')
    end

    it 'handles values containing equals signs' do
      env_file = File.join(tmpdir, '.env')
      File.write(env_file, "TEST_KEY=base64==encoded\n")
      described_class.load(env_file)
      expect(ENV['TEST_KEY']).to eq('base64==encoded')
    end

    it 'handles empty value after equals' do
      env_file = File.join(tmpdir, '.env')
      File.write(env_file, "TEST_KEY=\n")
      result = described_class.load(env_file)
      expect(result['TEST_KEY']).to eq('')
    end

    it 'handles lines with only a key and no equals sign' do
      env_file = File.join(tmpdir, '.env')
      File.write(env_file, "INVALID_LINE\nTEST_KEY=valid\n")
      described_class.load(env_file)
      expect(ENV['TEST_KEY']).to eq('valid')
    end

    it 'strips whitespace around keys and values' do
      env_file = File.join(tmpdir, '.env')
      File.write(env_file, "  TEST_KEY  =  hello  \n")
      described_class.load(env_file)
      expect(ENV['TEST_KEY']).to eq('hello')
    end

    it 'handles inline comments are not stripped (treated as value)' do
      env_file = File.join(tmpdir, '.env')
      File.write(env_file, "TEST_KEY=value # not a comment\n")
      described_class.load(env_file)
      expect(ENV['TEST_KEY']).to eq('value # not a comment')
    end

    it 'file overrides defaults' do
      env_file = File.join(tmpdir, '.env')
      File.write(env_file, "TEST_KEY=from_file\n")
      result = described_class.load(env_file, defaults: { 'TEST_KEY' => 'default_val' })
      expect(result['TEST_KEY']).to eq('from_file')
    end

    it 'uses default only when key not in file' do
      env_file = File.join(tmpdir, '.env')
      File.write(env_file, "TEST_KEY=present\n")
      result = described_class.load(env_file, defaults: { 'DEFAULT_ONLY' => 'fallback' })
      expect(result['DEFAULT_ONLY']).to eq('fallback')
      expect(ENV['DEFAULT_ONLY']).to eq('fallback')
    end

    it 'coerces float type' do
      env_file = File.join(tmpdir, '.env')
      File.write(env_file, "TEST_FLOAT=3.14\n")
      described_class.load(env_file, types: { 'TEST_FLOAT' => :float })
      expect(ENV['TEST_FLOAT']).to eq('3.14')
    end

    it 'coerces boolean yes/on/1 values to true' do
      env_file = File.join(tmpdir, '.env')
      File.write(env_file, "TEST_BOOL_YES=yes\nTEST_BOOL_ON=on\n")
      described_class.load(env_file, types: { 'TEST_BOOL_YES' => :boolean, 'TEST_BOOL_ON' => :boolean })
      expect(ENV['TEST_BOOL_YES']).to eq('true')
      expect(ENV['TEST_BOOL_ON']).to eq('true')
    end

    it 'coerces boolean no/off/0 values to false' do
      env_file = File.join(tmpdir, '.env')
      File.write(env_file, "TEST_BOOL_NO=no\n")
      described_class.load(env_file, types: { 'TEST_BOOL_NO' => :boolean })
      expect(ENV['TEST_BOOL_NO']).to eq('false')
    end

    it 'raises with multiple missing required keys' do
      env_file = File.join(tmpdir, '.env')
      File.write(env_file, "TEST_KEY=value\n")
      expect {
        described_class.load(env_file, required: %w[FIRST_KEY SECOND_KEY])
      }.to raise_error(Philiprehberger::EnvLoader::ValidationError, /FIRST_KEY.*SECOND_KEY|SECOND_KEY.*FIRST_KEY/)
    end

    it 'loads from multiple files merging all keys' do
      file1 = File.join(tmpdir, '.env')
      file2 = File.join(tmpdir, '.env.local')
      File.write(file1, "FIRST_KEY=one\n")
      File.write(file2, "SECOND_KEY=two\n")
      result = described_class.load(file1, file2)
      expect(result).to include('FIRST_KEY' => 'one', 'SECOND_KEY' => 'two')
    end
  end

  describe '.validate!' do
    it 'passes when all keys are present' do
      ENV['TEST_KEY'] = 'value'
      expect { described_class.validate!('TEST_KEY') }.not_to raise_error
    end

    it 'raises when keys are missing' do
      expect {
        described_class.validate!('REQUIRED_KEY')
      }.to raise_error(Philiprehberger::EnvLoader::ValidationError, /REQUIRED_KEY/)
    end

    it 'raises when keys are empty' do
      ENV['TEST_KEY'] = ''
      expect {
        described_class.validate!('TEST_KEY')
      }.to raise_error(Philiprehberger::EnvLoader::ValidationError)
    end

    it 'validates multiple keys at once' do
      ENV['TEST_KEY'] = 'present'
      ENV['TEST_HOST'] = 'localhost'
      expect { described_class.validate!('TEST_KEY', 'TEST_HOST') }.not_to raise_error
    end

    it 'reports all missing keys in error message' do
      expect {
        described_class.validate!('FIRST_KEY', 'SECOND_KEY')
      }.to raise_error(Philiprehberger::EnvLoader::ValidationError, /FIRST_KEY/)
    end
  end

  describe '.generate_template' do
    it 'generates a template file with specified keys' do
      output = File.join(tmpdir, '.env.template')
      described_class.generate_template(output: output, keys: %w[APP_HOST APP_PORT APP_SECRET])
      content = File.read(output)
      expect(content).to include('APP_HOST=')
      expect(content).to include('APP_PORT=')
      expect(content).to include('APP_SECRET=')
    end

    it 'sorts keys alphabetically' do
      output = File.join(tmpdir, '.env.template')
      described_class.generate_template(output: output, keys: %w[ZEBRA ALPHA MIDDLE])
      lines = File.readlines(output).map(&:strip).reject(&:empty?)
      expect(lines).to eq(%w[ALPHA= MIDDLE= ZEBRA=])
    end

    it 'ends file with a newline' do
      output = File.join(tmpdir, '.env.template')
      described_class.generate_template(output: output, keys: %w[KEY])
      content = File.read(output)
      expect(content).to end_with("\n")
    end
  end

  describe 'error class hierarchy' do
    it 'ValidationError inherits from Error' do
      expect(Philiprehberger::EnvLoader::ValidationError).to be < Philiprehberger::EnvLoader::Error
    end

    it 'Error inherits from StandardError' do
      expect(Philiprehberger::EnvLoader::Error).to be < StandardError
    end
  end
end
