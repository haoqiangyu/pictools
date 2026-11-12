require "json"
require "fileutils"
require "cgi"
require "uri"

# Store copy is kept in JSON; only generated deliver/supply files go in build/.
module StoreRelease
  ROOT = File.expand_path("../..", __dir__)
  LOCALES = %w[zh-CN zh-TW en-US es-ES fr-FR de-DE].freeze
  IOS_LOCALES = { "zh-CN" => "zh-Hans", "zh-TW" => "zh-Hant" }.freeze
  LIMITS = {
    "ios" => { "name" => 30, "subtitle" => 30, "promotional_text" => 170,
               "description" => 4000, "keywords" => 100 },
    "android" => { "title" => 30, "short_description" => 80, "full_description" => 4000 }
  }.freeze
  URL_FIELDS = { "ios" => %w[privacy_url support_url marketing_url], "android" => %w[video] }.freeze
  IOS_GLOBAL_FIELDS = %w[copyright primary_category secondary_category].freeze

  def self.boolean(value, default: false)
    return default if value.nil?
    return true if value == true || value == "true"
    return false if value == false || value == "false"
    raise ArgumentError, "Expected true or false, got #{value.inspect}"
  end

  def self.ios_locale(locale)
    IOS_LOCALES.fetch(locale, locale)
  end

  class Project
    attr_reader :root, :version, :build_number, :config, :metadata, :notes

    def initialize(root: ROOT, build_number: nil)
      @root = root
      match = File.read(File.join(root, "pubspec.yaml")).match(/^version:\s*["']?(\d+\.\d+\.\d+)\+(\d+)["']?\s*$/)
      raise "pubspec.yaml must contain version: x.y.z+number" unless match
      @version = match[1]
      @build_number = (build_number || match[2]).to_s
      unless @build_number.match?(/\A[1-9]\d*\z/) && @build_number.to_i <= 2_100_000_000
        raise "build_number must be a positive integer <= 2100000000"
      end
      @config = read_json("fastlane/store.json")
      @metadata = LOCALES.to_h { |locale| [locale, read_json("fastlane/metadata/#{locale}.json")] }
      @notes = read_json("fastlane/release_notes/#{version}.json")
      validate!
    end

    def read_json(relative)
      JSON.parse(File.read(File.join(root, relative), encoding: "UTF-8"))
    rescue Errno::ENOENT
      raise "Missing #{relative}. Add six-language release notes for each new version."
    end

    def validate!
      raise "Unknown store.json fields" unless (config.keys - %w[app_identifier package_name ios]).empty?
      %w[app_identifier package_name].each do |key|
        raise "Invalid #{key}" unless config[key].is_a?(String) && config[key].match?(/\A[a-zA-Z0-9_-]+(?:\.[a-zA-Z0-9_-]+)+\z/)
      end
      raise "Unknown global iOS fields" unless config["ios"].is_a?(Hash) && (config["ios"].keys - IOS_GLOBAL_FIELDS).empty?
      config["ios"].each { |key, value| validate_text!("ios/#{key}", value, 500) unless value.nil? }
      raise "Release notes must contain exactly #{LOCALES.join(', ')}" unless notes.keys.sort == LOCALES.sort
      files = Dir.glob(File.join(root, "fastlane/metadata/*.json")).map { |f| File.basename(f, ".json") }
      raise "Unexpected metadata locales: #{files - LOCALES}" unless files.sort == LOCALES.sort
      metadata.each do |locale, stores|
        raise "#{locale}: expected ios and android" unless stores.keys.sort == %w[android ios]
        LIMITS.each do |platform, fields|
          data = stores.fetch(platform)
          unknown = data.keys - fields.keys - URL_FIELDS.fetch(platform)
          raise "#{platform}/#{locale}: unsupported fields #{unknown}" unless unknown.empty?
          fields.each { |key, limit| validate_text!("#{platform}/#{locale}/#{key}", data.fetch(key), limit) }
          if platform == "ios" && data.fetch("keywords").bytesize > 100
            raise "ios/#{locale}/keywords: exceeds 100 UTF-8 bytes"
          end
          URL_FIELDS.fetch(platform).each do |key|
            value = data[key]
            next if value.nil?
            uri = URI.parse(value)
            raise "#{platform}/#{locale}/#{key}: expected an https URL" unless uri.is_a?(URI::HTTPS) && uri.host && !uri.userinfo
          end
        end
        # A shared note must fit Play's stricter 500-character release-note limit.
        validate_text!("release_notes/#{locale}", notes.fetch(locale), 500)
      end
      self
    end

    def validate_text!(label, value, limit)
      raise "#{label}: expected non-empty text" unless value.is_a?(String) && !value.strip.empty?
      raise "#{label}: #{value.length} characters exceeds #{limit}" if value.length > limit
      raise "#{label}: remove surrounding whitespace" unless value == value.strip
      raise "#{label}: contains control characters" if value.match?(/[\x00-\x08\x0b\x0c\x0e-\x1f]/)
    end

    def output
      File.join(root, "build/store")
    end

    def metadata_path(platform)
      File.join(output, "metadata", platform)
    end

    def prepare!
      # Remove only our generated files so omitted fields can never survive a rerun.
      FileUtils.rm_rf(File.join(output, "metadata"))
      metadata.each do |locale, stores|
        stores.each do |platform, fields|
          store_locale = platform == "ios" ? StoreRelease.ios_locale(locale) : locale
          dir = File.join(metadata_path(platform), store_locale)
          fields.each { |key, value| write_text(File.join(dir, "#{key}.txt"), value) unless value.nil? }
          note_file = platform == "ios" ? "release_notes.txt" : "changelogs/#{build_number}.txt"
          write_text(File.join(dir, note_file), notes.fetch(locale))
        end
      end
      config.fetch("ios").each do |key, value|
        write_text(File.join(metadata_path("ios"), "#{key}.txt"), value) unless value.nil?
      end
      rows = metadata.flat_map do |locale, stores|
        stores.flat_map do |platform, fields|
          fields.merge("release_notes" => notes.fetch(locale)).filter_map do |key, value|
            next if value.nil?
            "<tr><td>#{platform}</td><td>#{locale}</td><td>#{key}<br>#{value.length} chars</td><td><pre>#{CGI.escapeHTML(value)}</pre></td></tr>"
          end
        end
      end.join("\n")
      html = <<~HTML
        <!doctype html><html lang="zh-CN"><meta charset="utf-8"><title>Pictools store metadata</title>
        <style>body{font:16px system-ui;margin:32px;color:#18202b}table{border-collapse:collapse;width:100%}td{border:1px solid #ccd2da;padding:12px;vertical-align:top}pre{white-space:pre-wrap;font:inherit;margin:0}</style>
        <h1>Pictools #{version} (#{build_number})</h1><p>本地文案预览。省略的网址、版权、联系方式保留后台现值；新增 iOS 语言的网址继承后台主要语言。此预览不访问后台。</p>
        <table>#{rows}</table></html>
      HTML
      File.write(File.join(output, "preview.html"), html)
      self
    end

    def write_text(path, value)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, value, encoding: "UTF-8")
    end

    def localized_beta_info
      metadata.to_h do |locale, stores|
        ios = stores.fetch("ios")
        fields = { description: ios.fetch("description") }
        fields[:privacy_policy_url] = ios["privacy_url"] if ios["privacy_url"]
        fields[:marketing_url] = ios["marketing_url"] if ios["marketing_url"]
        [StoreRelease.ios_locale(locale), fields]
      end
    end

    def localized_beta_notes
      notes.to_h { |locale, text| [StoreRelease.ios_locale(locale), { whats_new: text }] }
    end

    def build_command(platform)
      executable = ENV.fetch("FLUTTER_BIN", "flutter")
      args = [executable, "build", platform == "ios" ? "ipa" : "appbundle", "--release",
              "--build-name=#{version}", "--build-number=#{build_number}", "--obfuscate",
              "--split-debug-info=#{File.join(root, 'build/symbols', platform, "#{version}+#{build_number}")}"]
      if platform == "ios"
        export_options = ENV["IOS_EXPORT_OPTIONS_PLIST"]
        if export_options && !export_options.empty?
          path = File.expand_path(export_options, root)
          raise "IOS_EXPORT_OPTIONS_PLIST does not exist" unless File.file?(path)
          args << "--export-options-plist=#{path}"
        else
          args << "--export-method=app-store"
        end
      end
      args
    end
  end

  # Read first; refuse to rename an unrelated editable version or modify a live one.
  def self.apple_version_preflight!(app, version)
    editable = app.get_edit_app_store_version(platform: "IOS")
    if editable
      raise "App Store has editable #{editable.version_string}; requested #{version}. Align pubspec.yaml first." unless editable.version_string == version
      allowed = %w[PREPARE_FOR_SUBMISSION DEVELOPER_REJECTED REJECTED METADATA_REJECTED INVALID_BINARY]
      raise "App Store version is not editable: #{editable.app_version_state}" unless allowed.include?(editable.app_version_state)
    else
      existing = app.get_app_store_versions(filter: { platform: "IOS", versionString: version })
      raise "App Store #{version} already exists but is not editable. Use a new version." unless existing.empty?
    end
    editable
  end

  def self.apple_select_build!(app, project)
    version = apple_version_preflight!(app, project.version)
    raise "Run ios prepare first to create #{project.version}" unless version
    builds = Spaceship::ConnectAPI::Build.all(app_id: app.id, version: project.version,
      build_number: project.build_number, platform: "IOS")
    build = builds.find { |item| item.version == project.build_number && item.processing_state == "VALID" && !item.expired }
    raise "Build #{project.version} (#{project.build_number}) is missing, expired or still processing" unless build
    version.select_build(build_id: build.id)
    version.update(attributes: { releaseType: "MANUAL" }) unless version.release_type == "MANUAL"
    version
  end

  # Routine updates inherit the current App Store listing. Patch only What's New,
  # never pass the complete local metadata directory to deliver in this mode.
  def self.apple_prepare_update!(app, project)
    version = apple_version_preflight!(app, project.version)
    unless version
      require "spaceship"
      version = Spaceship::ConnectAPI.post_app_store_version(
        app_id: app.id,
        attributes: { versionString: project.version, platform: "IOS", releaseType: "MANUAL" }
      ).to_models.first
    end
    raise "App Store did not return the requested version" unless version && version.version_string == project.version
    localizations = version.get_app_store_version_localizations.to_h { |item| [item.locale, item] }
    wanted = project.notes.to_h { |locale, text| [ios_locale(locale), text] }
    missing = wanted.keys - localizations.keys
    unless missing.empty?
      raise "App Store #{project.version} is missing locales: #{missing.join(', ')}. Initialize them with ios metadata before using ios prepare_update."
    end
    wanted.each do |locale, text|
      item = localizations.fetch(locale)
      item.update(attributes: { whatsNew: text }) unless item.whats_new == text
    end
    version
  end

  def self.prepare_play_submission!(client, code)
    raise "version_code must be a positive integer" unless code.to_s.match?(/\A[1-9]\d*\z/)
    track = client.tracks("production").first
    releases = track&.releases || []
    matches = releases.select { |release| (release.version_codes || []).map(&:to_s).include?(code.to_s) }
    raise "Expected one production draft containing versionCode #{code}" unless matches.length == 1
    target = matches.first
    raise "Only a draft can be submitted; current status: #{target.status}" unless target.status == "draft"
    raise "Draft contains multiple version codes; review it in Play Console" unless target.version_codes.map(&:to_s) == [code.to_s]
    # Google allows only one completed release per track. Replace the previous
    # completed entry in this edit, retaining the selected draft's notes. The
    # live release remains unchanged until the edit is committed and reviewed.
    track.releases = releases.reject { |release| release != target && release.status == "completed" }
    target.status = "completed"
    client.update_track("production", track)
  end

  # Omitted URLs on existing locales are never sent. New locales inherit actual
  # server-side URLs instead of a guessed website or a repository support link.
  def self.apple_inherited_urls(app, project, version_record)
    info = app.fetch_edit_app_info || app.fetch_live_app_info
    info_locales = info ? info.get_app_info_localizations : []
    version_record ||= app.get_live_app_store_version(platform: "IOS")
    version_locales = version_record ? version_record.get_app_store_version_localizations : []
    options = {}
    { privacy_url: [info_locales, :privacy_policy_url], support_url: [version_locales, :support_url],
      marketing_url: [version_locales, :marketing_url] }.each do |field, (records, attribute)|
      primary = records.find { |record| record.locale == app.primary_locale }
      project.metadata.each do |locale, stores|
        asc_locale = ios_locale(locale)
        next if stores.fetch("ios")[field.to_s] || records.any? { |record| record.locale == asc_locale }
        value = primary&.public_send(attribute)
        if value.to_s.empty?
          raise "New locale #{asc_locale} needs #{field}; the primary locale has no value. Configure it in App Store Connect first." if field != :marketing_url
          next
        end
        (options[field] ||= {})[asc_locale] = value
      end
    end
    options
  end
end
