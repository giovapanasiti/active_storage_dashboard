# frozen_string_literal: true

module ActiveStorageDashboard
  # Reports whether the host application's Active Storage image pipeline is
  # exposed to CVE-2026-66066 - arbitrary file read (escalating to RCE) through
  # libvips "unfuzzed" loaders during variant processing.
  #
  # This gem does not contain the vulnerability, but several of its features
  # hand user-uploaded bytes to libvips (Analyzer, VariantRegenerator, and the
  # preview helpers), so it reports on the surrounding environment rather than
  # assuming it is safe.
  #
  # Every probe degrades to nil or :unknown instead of raising. This runs on
  # every dashboard request and must never be the reason a page fails to render.
  class SafetyCheck
    CVE = "CVE-2026-66066"

    # From the advisory: the first release in each series that disables the
    # unfuzzed operations. Keyed by "major.minor" series.
    FIXED_IN_SERIES = {
      "8.1" => "8.1.3.1",
      "8.0" => "8.0.5.1"
    }.freeze

    # Everything below the 8.0 series received a single backport.
    FIXED_BELOW_8_0 = "7.2.3.2"

    # Earlier libvips cannot disable the unfuzzed operations at all.
    MINIMUM_LIBVIPS = "8.13"

    # Values of VIPS_BLOCK_UNTRUSTED that mean "not enabled". libvips itself
    # only checks whether the variable is present, but an operator who wrote
    # "0" or "false" clearly did not intend to enable it, and reporting that as
    # safe would be misleading.
    FALSEY_ENV_VALUES = ["", "0", "false", "no", "off"].freeze

    class << self
      # Is this activestorage version one of the fixed releases?
      # Returns nil when the version cannot be parsed.
      def activestorage_fixed?(version)
        return nil if version.nil? || version.to_s.strip.empty?

        parsed = Gem::Version.new(version.to_s)
        series = parsed.segments.first(2).join(".")

        if (fixed = FIXED_IN_SERIES[series])
          parsed >= Gem::Version.new(fixed)
        elsif parsed < Gem::Version.new("8.0")
          parsed >= Gem::Version.new(FIXED_BELOW_8_0)
        else
          # A series newer than anything the advisory listed, so it postdates
          # the fix.
          true
        end
      rescue ArgumentError
        nil
      end

      def libvips_sufficient?(version)
        return nil if version.nil? || version.to_s.strip.empty?

        Gem::Version.new(version.to_s) >= Gem::Version.new(MINIMUM_LIBVIPS)
      rescue ArgumentError
        nil
      end

      def block_untrusted_env?(env)
        value = env["VIPS_BLOCK_UNTRUSTED"]
        return false if value.nil?

        !FALSEY_ENV_VALUES.include?(value.to_s.strip.downcase)
      end

      # The pure decision. Split out from the environment probing above so the
      # branch that matters can be exercised without booting Rails.
      #
      # Returns one of :ok, :warning, :critical, :unknown.
      def evaluate(variant_processor:, activestorage_version:, block_untrusted_env:)
        processor = variant_processor.to_s

        # An undetectable processor is not the same as a safe one. Report it as
        # unknown rather than letting it fall through to the "not vips, so not
        # affected" branch and showing a false all-clear.
        return :unknown if processor.empty? || processor == "unknown"

        # libvips is only reachable when it is the configured processor; this
        # governs the analyzer as well as variant generation.
        return :ok unless processor == "vips"

        case activestorage_fixed?(activestorage_version)
        when true
          # Fixed releases block the unfuzzed operations themselves, and refuse
          # to boot against libvips < 8.13.
          :ok
        when false
          # Vulnerable Active Storage. The environment variable is the
          # advisory's documented interim mitigation, but it only works with
          # libvips >= 8.13 and does not remove the need to upgrade.
          block_untrusted_env ? :warning : :critical
        else
          :unknown
        end
      end
    end

    def status
      @status ||= self.class.evaluate(
        variant_processor: variant_processor,
        activestorage_version: activestorage_version,
        block_untrusted_env: block_untrusted_env?
      )
    end

    def ok?
      status == :ok
    end

    def summary
      case status
      when :ok
        if variant_processor.to_s == "vips"
          "Active Storage is running a patched release with the unfuzzed libvips operations blocked."
        else
          "Active Storage is not using libvips (processor: #{variant_processor}), so #{CVE} does not apply."
        end
      when :warning
        "Active Storage #{activestorage_version} is vulnerable to #{CVE}, but VIPS_BLOCK_UNTRUSTED is set. " \
          "That is an interim mitigation only - upgrade activestorage and rotate your secrets."
      when :critical
        "Active Storage #{activestorage_version} is vulnerable to #{CVE} and the unfuzzed libvips operations " \
          "are not blocked. Uploaded files may be able to read arbitrary files from this server. " \
          "Do not run the dashboard's reanalyze or regenerate_variants tasks."
      else
        "Could not determine whether this application is affected by #{CVE}. Verify the installed " \
          "activestorage and libvips versions by hand."
      end
    end

    # Rows for the dashboard panel: [label, value, state] where state is one of
    # :good, :bad, :unknown, :neutral.
    def details
      [
        activestorage_detail,
        processor_detail,
        libvips_detail,
        block_untrusted_detail
      ]
    end

    def variant_processor
      @variant_processor ||= begin
        if defined?(::ActiveStorage) && ::ActiveStorage.respond_to?(:variant_processor)
          ::ActiveStorage.variant_processor || :unknown
        else
          :unknown
        end
      rescue StandardError
        :unknown
      end
    end

    def activestorage_version
      @activestorage_version ||= begin
        if defined?(::ActiveStorage::VERSION::STRING)
          ::ActiveStorage::VERSION::STRING
        elsif defined?(::ActiveStorage) && ::ActiveStorage.respond_to?(:version)
          ::ActiveStorage.version.to_s
        end
      rescue StandardError
        nil
      end
    end

    # ruby-vips is loaded lazily by Active Storage, so an unknown version here
    # means "not loaded yet", not "not installed". Reported as unknown rather
    # than assumed either way.
    def libvips_version
      return @libvips_version if defined?(@libvips_version)

      @libvips_version = begin
        if !defined?(::Vips)
          nil
        elsif defined?(::Vips::LIBRARY_VERSION)
          ::Vips::LIBRARY_VERSION
        elsif ::Vips.respond_to?(:version)
          [::Vips.version(0), ::Vips.version(1), ::Vips.version(2)].join(".")
        end
      rescue StandardError, LoadError
        nil
      end
    end

    def block_untrusted_env?
      self.class.block_untrusted_env?(ENV)
    end

    private

    def activestorage_detail
      case self.class.activestorage_fixed?(activestorage_version)
      when true  then ["Active Storage", "#{activestorage_version} (patched)", :good]
      when false then ["Active Storage", "#{activestorage_version} - vulnerable to #{CVE}", :bad]
      else ["Active Storage", activestorage_version || "unknown", :unknown]
      end
    end

    def processor_detail
      if variant_processor.to_s == "vips"
        ["Variant processor", "vips (libvips is in use)", :neutral]
      elsif variant_processor.to_s == "unknown"
        ["Variant processor", "unknown", :unknown]
      else
        ["Variant processor", "#{variant_processor} (libvips not in use)", :good]
      end
    end

    def libvips_detail
      case self.class.libvips_sufficient?(libvips_version)
      when true  then ["libvips", "#{libvips_version} (>= #{MINIMUM_LIBVIPS})", :good]
      when false then ["libvips", "#{libvips_version} - below the required #{MINIMUM_LIBVIPS}", :bad]
      else ["libvips", "not loaded in this process", :unknown]
      end
    end

    def block_untrusted_detail
      if block_untrusted_env?
        ["VIPS_BLOCK_UNTRUSTED", "set", :good]
      else
        ["VIPS_BLOCK_UNTRUSTED", "not set", :neutral]
      end
    end
  end
end
