# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe Philiprehberger::EnvLoader do
  let(:tmpdir) { Dir.mktmpdir }

  after do
    FileUtils.rm_rf(tmpdir)
    %w[TEST_KEY TEST_HOST TEST_PORT TEST_DEBUG TEST_OTHER REQUIRED_KEY].each { |k| ENV.delete(k) }
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
  end
end
