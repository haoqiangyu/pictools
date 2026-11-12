require_relative "store_release"
require "fastimage"
require "digest"
require "deliver"

module StoreRelease
  def self.asset_locales(value)
    locales = value ? value.to_s.split(",").map(&:strip) : LOCALES
    unless !locales.empty? && (locales - LOCALES).empty? && locales.uniq == locales
      raise "locales must contain unique names from #{LOCALES.join(',')}"
    end
    locales
  end

  module ImageValidation
    def validate_image!(file, slot, size: nil, allow_alpha: false)
      raise "Missing image: #{file}" unless File.file?(file)
      format = FastImage.type(file)
      dimensions = FastImage.size(file)
      valid_extensions = { png: %w[.png], jpeg: %w[.jpg .jpeg] }
      unless dimensions && valid_extensions.fetch(format, []).include?(File.extname(file).downcase)
        raise "Invalid PNG/JPEG or extension mismatch: #{file}"
      end
      validate_png!(file, allow_alpha: allow_alpha) if format == :png
      if platform == "android" && slot == "icon"
        unless format == :png && File.binread(file, 26).getbyte(25) == 6 && File.size(file) <= 1024 * 1024
          raise "#{file}: Play icons must be 32-bit RGBA PNG, at most 1024 KB"
        end
      end
      if size
        raise "#{file}: expected #{size.join('x')}, found #{dimensions.join('x')}" unless dimensions == size
      elsif platform == "ios"
        actual = Deliver::AppScreenshot.new(file, "en-US").display_type
        raise "#{file}: #{dimensions.join('x')} does not match #{slot} (detected #{actual})" unless actual == slot
      elsif dimensions.min < 320 || dimensions.max > 3840 || dimensions.max > dimensions.min * 2
        raise "#{file}: Play screenshots need sides 320–3840 px and aspect ratio <= 2:1"
      end
      raise "#{file}: exceeds Play's 8 MB image limit" if platform == "android" && File.size(file) > 8 * 1024 * 1024
    end

    def validate_png!(file, allow_alpha:)
      data = File.binread(file)
      raise "Invalid PNG header: #{file}" unless data.byteslice(0, 8) == "\x89PNG\r\n\x1a\n".b
      allowed = allow_alpha ? [2, 6] : [2]
      unless data.getbyte(24) == 8 && allowed.include?(data.getbyte(25))
        raise "#{file}: expected 8-bit RGB PNG#{allow_alpha ? ' or RGBA icon' : ' without an alpha channel'}"
      end
      offset = 8
      while offset + 12 <= data.bytesize
        length = data.byteslice(offset, 4).unpack1("N")
        chunk = data.byteslice(offset + 4, 4)
        raise "Truncated PNG: #{file}" if offset + length + 12 > data.bytesize
        raise "#{file}: transparent/animated PNG is not supported" if chunk == "acTL" || (chunk == "tRNS" && !allow_alpha)
        return if chunk == "IEND"
        offset += length + 12
      end
      raise "Truncated PNG: #{file}"
    end

  end

  class Screenshots
    include ImageValidation
    attr_reader :project, :platform, :locales, :groups, :graphics, :path

    def initialize(project, platform, locales: nil, include_graphics: false)
      @project, @platform = project, platform
      raise "Unknown screenshot platform: #{platform}" unless %w[ios android].include?(platform)
      @locales = StoreRelease.asset_locales(locales)
      raise "include_graphics is only supported for Google Play" if include_graphics && platform != "android"
      config = project.read_json("fastlane/screenshots.json")
      source = File.expand_path(config.fetch("source_root"), project.root)
      slots = config.fetch(platform)
      raise "Configure at least one screenshot device group" if slots.empty?
      raise "Each device group must have a different destination" unless slots.values.uniq == slots.values
      @path = File.join(project.output, "screenshots", platform)
      @groups, @graphics = [], []
      @locales.each do |locale|
        slots.each do |folder, slot|
          raise "Invalid source folder: #{folder}" unless folder.match?(/\A[a-zA-Z0-9_-]+\z/)
          store = platform == "ios" ? "app-store" : "google-play"
          files = Dir.glob(File.join(source, locale, store, folder, "*.{png,jpg,jpeg}"), File::FNM_CASEFOLD).sort
          max = platform == "ios" ? 10 : 8
          raise "#{locale}/#{folder}: expected 1–#{max} images, found #{files.length}" unless (1..max).cover?(files.length)
          if platform == "android" && !%w[phoneScreenshots sevenInchScreenshots tenInchScreenshots].include?(slot)
            raise "Unsupported Play screenshot slot #{slot}"
          end
          files.each { |file| validate_image!(file, slot) }
          hashes = files.map { |file| Digest::SHA256.file(file).hexdigest }
          raise "#{locale}/#{folder}: duplicate screenshots" unless hashes.uniq == hashes
          @groups << { locale: locale, store_locale: platform == "ios" ? StoreRelease.ios_locale(locale) : locale,
                       folder: folder, slot: slot, files: files, sha256: hashes }
        end
        next unless include_graphics
        { "featureGraphic" => [File.join(source, locale, "google-play/feature/feature-graphic.png"), [1024, 500]],
          "icon" => [File.join(source, "shared-icons/google-play-512.png"), [512, 512]] }.each do |slot, (file, size)|
          validate_image!(file, slot, size: size, allow_alpha: slot == "icon")
          @graphics << { locale: locale, slot: slot, file: file }
        end
      end
    end

    def prepare!
      # Validate the whole selection before replacing any generated staging data.
      FileUtils.rm_rf(path)
      groups.each do |group|
        dir = File.join(path, group.fetch(:store_locale))
        dir = File.join(dir, "images", group.fetch(:slot)) if platform == "android"
        FileUtils.mkdir_p(dir)
        group[:files] = group.fetch(:files).map do |file|
          name = platform == "ios" ? "#{group.fetch(:folder)}__#{File.basename(file)}" : File.basename(file)
          target = File.join(dir, name)
          FileUtils.cp(file, target)
          target
        end
      end
      graphics.each do |graphic|
        dir = File.join(path, graphic.fetch(:locale), "images")
        FileUtils.mkdir_p(dir)
        FileUtils.cp(graphic.fetch(:file), File.join(dir, "#{graphic.fetch(:slot)}.png"))
      end
      report = { platform: platform, groups: groups, graphics: graphics }
      File.write(File.join(project.output, "#{platform}-screenshots.json"), JSON.pretty_generate(report))
      self
    end

    def attach_to_metadata!
      raise "Only Google Play embeds screenshots in its metadata directory" unless platform == "android"
      locales.each do |locale|
        destination = File.join(project.metadata_path("android"), locale, "images")
        FileUtils.rm_rf(destination)
        FileUtils.cp_r(File.join(path, locale, "images"), destination)
      end
    end
  end

  class PlayIcon
    include ImageValidation
    attr_reader :platform, :path, :locales

    def initialize(project, locales: nil)
      @project, @platform = project, "android"
      @locales = StoreRelease.asset_locales(locales)
      config = project.read_json("fastlane/screenshots.json")
      source = File.expand_path(config.fetch("source_root"), project.root)
      @file = File.join(source, "shared-icons/google-play-512.png")
      @path = File.join(project.output, "icons/android")
      validate_image!(@file, "icon", size: [512, 512], allow_alpha: true)
    end

    def prepare!
      # A separate icon-only directory prevents Supply from finding any other assets.
      FileUtils.rm_rf(path)
      locales.each do |locale|
        dir = File.join(path, locale, "images")
        FileUtils.mkdir_p(dir)
        FileUtils.cp(@file, File.join(dir, "icon.png"))
      end
      report = { source: @file, sha256: Digest::SHA256.file(@file).hexdigest, locales: locales, path: path }
      File.write(File.join(@project.output, "android-icon.json"), JSON.pretty_generate(report))
      self
    end
  end

  # Fastlane's overwrite_screenshots removes every device set of a language.
  # Use Spaceship to synchronize only the selected language/device pairs.
  class AppleScreenshotSync
    def initialize(version, selection, timeout: 300)
      @version, @selection, @timeout = version, selection, timeout
    end

    def sync!
      localizations = @version.get_app_store_version_localizations
      missing = @selection.groups.map { |group| group[:store_locale] }.uniq - localizations.map(&:locale)
      raise "Initialize missing locales with `fastlane ios metadata` first: #{missing.join(', ')}" unless missing.empty?
      @selection.groups.each do |group|
        localization = localizations.find { |record| record.locale == group[:store_locale] }
        sync_group!(localization, group)
      end
    end

    def sync_group!(localization, group)
      desired = group.fetch(:files).map { |file| Digest::MD5.file(file).hexdigest }
      sets = localization.get_app_screenshot_sets
      set = sets.find { |record| record.screenshot_display_type == group.fetch(:slot) }
      set ||= localization.create_app_screenshot_set(attributes: { screenshotDisplayType: group.fetch(:slot) })
      current = set.app_screenshots || []
      if current.map(&:source_file_checksum) == desired && current.all? { |image| complete?(image) }
        FastlaneCore::UI.message("Screenshots unchanged: #{localization.locale} / #{group[:slot]}")
        return
      end
      kept = []
      current.each do |image|
        hash = image.source_file_checksum
        if complete?(image) && desired.include?(hash) && !kept.include?(hash)
          kept << hash
        else
          image.delete!
        end
      end
      group.fetch(:files).zip(desired).each do |file, hash|
        next if kept.include?(hash)
        FastlaneCore::UI.message("Uploading #{localization.locale} / #{group[:slot]} / #{File.basename(file)}")
        set.upload_screenshot(path: file, wait_for_processing: false)
      end
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + @timeout
      loop do
        set = localization.get_app_screenshot_sets.find { |record| record.screenshot_display_type == group[:slot] }
        images = set&.app_screenshots || []
        raise "Apple rejected screenshot processing for #{localization.locale}/#{group[:slot]}" if images.any? { |image| image.asset_delivery_state&.fetch("state", nil) == "FAILED" }
        if images.length == desired.length && images.all? { |image| complete?(image) && image.source_file_checksum }
          raise "Remote screenshot checksums differ for #{localization.locale}/#{group[:slot]}" unless images.map(&:source_file_checksum).sort == desired.sort
          ids = desired.map { |hash| images.find { |image| image.source_file_checksum == hash }.id }
          set.reorder_screenshots(app_screenshot_ids: ids) unless images.map(&:id) == ids
          return
        end
        raise "Screenshot processing timed out for #{localization.locale}/#{group[:slot]}; rerun to retry" if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
        sleep(3)
      end
    end

    def complete?(image)
      image.asset_delivery_state&.fetch("state", nil) == "COMPLETE"
    end
  end
end
