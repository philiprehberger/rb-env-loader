# frozen_string_literal: true

require_relative 'env_loader/version'

module Philiprehberger
  module EnvLoader
    class Error < StandardError; end
    class ValidationError < Error; end

    # Load environment variables from one or more .env files with options.
    #
    # Files are loaded in order; later files take precedence. Existing ENV
    # values take precedence over all files unless overridden.
    #
    # @param files [Array<String>] paths to .env files
    # @param required [Array<String>] keys that must be present after loading
    # @param types [Hash<String, Symbol>] type coercions (:integer, :float, :boolean)
    # @param defaults [Hash<String, String>] default values for missing keys
    # @return [Hash<String, String>] the loaded key-value pairs
    # @raise [ValidationError] if required keys are missing
    def self.load(*files, required: [], types: {}, defaults: {}, prefix: nil, strip_prefix: false)
      loaded = {}

      defaults.each { |key, value| loaded[key.to_s] = value.to_s }

      files.each do |file|
        next unless File.exist?(file)

        parse_file(file).each { |key, value| loaded[key] = value }
      end

      loaded.each { |key, value| ENV[key] = value unless ENV.key?(key) }

      missing = required.map(&:to_s).select { |key| ENV[key].nil? || ENV[key].empty? }
      raise ValidationError, "missing required keys: #{missing.join(', ')}" unless missing.empty?

      coerce_types(types)

      if prefix
        loaded = loaded.select { |key, _| key.start_with?(prefix) }
        loaded = loaded.transform_keys { |key| key.delete_prefix(prefix) } if strip_prefix
      end

      loaded
    end

    # Validate that all specified keys are present and non-empty in ENV.
    #
    # @param keys [Array<String>] keys to validate
    # @return [void]
    # @raise [ValidationError] if any keys are missing or empty
    def self.validate!(*keys)
      missing = keys.map(&:to_s).select { |key| ENV[key].nil? || ENV[key].empty? }
      raise ValidationError, "missing required keys: #{missing.join(', ')}" unless missing.empty?
    end

    # Generate a .env.template file listing all currently loaded keys.
    #
    # @param output [String] the output file path
    # @param keys [Array<String>] keys to include (defaults to all loaded ENV keys)
    # @return [void]
    def self.generate_template(output:, keys: [])
      target_keys = keys.empty? ? ENV.keys.sort : keys.map(&:to_s).sort
      content = target_keys.map { |key| "#{key}=" }.join("\n")
      File.write(output, "#{content}\n")
    end

    # Parse `.env`-formatted content from a string into a hash.
    #
    # Useful for tests, embedded configurations, and any scenario where the
    # `.env` content does not live in a file. Comments (`#`), blank lines,
    # and surrounding whitespace are ignored. Single- and double-quoted
    # values are unwrapped. ENV is not touched.
    #
    # @param content [String] the `.env`-formatted text
    # @return [Hash{String => String}] parsed key-value pairs
    def self.parse(content)
      result = {}
      content.to_s.each_line do |line|
        line = line.strip
        next if line.empty? || line.start_with?('#')

        key, value = line.split('=', 2)
        next if key.nil? || value.nil?

        key = key.strip
        value = value.strip
        value = value[1..-2] if (value.start_with?('"') && value.end_with?('"')) ||
                                (value.start_with?("'") && value.end_with?("'"))
        result[key] = value
      end
      result
    end

    # Parse a .env file into a hash of key-value pairs.
    #
    # @param path [String] the file path
    # @return [Hash<String, String>] parsed key-value pairs
    def self.parse_file(path)
      parse(File.read(path))
    end
    private_class_method :parse_file

    # Apply type coercions to ENV values.
    #
    # @param types [Hash<String, Symbol>] key => type mapping
    # @return [void]
    def self.coerce_types(types)
      types.each do |key, type|
        key = key.to_s
        next unless ENV.key?(key)

        case type.to_sym
        when :integer
          ENV[key] = ENV[key].to_i.to_s
        when :float
          ENV[key] = ENV[key].to_f.to_s
        when :boolean
          ENV[key] = %w[true 1 yes on].include?(ENV[key].downcase).to_s
        end
      end
    end
    private_class_method :coerce_types
  end
end
