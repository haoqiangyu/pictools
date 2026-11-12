require "minitest/autorun"
require "minitest/mock"
require "tmpdir"
require "ostruct"
require "zlib"
require "fastlane"
require_relative "../lib/store_screenshots"
Fastlane.load_actions

class StoreScreenshotsTest < Minitest::Test
  def setup
    @root = Dir.mktmpdir("pictools-screenshots")
    @config = { "source_root" => "assets", "ios" => { "phone" => "APP_IPHONE_61" },
                "android" => { "phone" => "phoneScreenshots" } }
    @project = OpenStruct.new(root: @root, output: File.join(@root, "build/store"))
    config = @config
    @project.define_singleton_method(:read_json) { |_| config }
    @project.define_singleton_method(:metadata_path) { |platform| File.join(output, "metadata", platform) }
    @source = File.join(@root, "assets/zh-CN")
    png(File.join(@source, "app-store/phone/01-first.png"), 1179, 2556, 1)
    png(File.join(@source, "google-play/phone/01-first.png"), 1080, 1920, 1)
    png(File.join(@source, "google-play/phone/02-second.png"), 1080, 1920, 2)
  end

  def teardown
    FileUtils.remove_entry(@root)
  end

  def png(path, width, height, color, alpha: false)
    FileUtils.mkdir_p(File.dirname(path))
    chunk = ->(type, bytes) { [bytes.bytesize].pack("N") + type + bytes + [Zlib.crc32(type + bytes)].pack("N") }
    channels = alpha ? 4 : 3
    scanline = "\0".b + ([color].pack("C") * width * channels)
    bytes = "\x89PNG\r\n\x1a\n".b
    bytes += chunk.call("IHDR", [width, height, 8, alpha ? 6 : 2, 0, 0, 0].pack("NNCCCCC"))
    bytes += chunk.call("IDAT", Zlib.deflate(scanline * height))
    bytes += chunk.call("IEND", "".b)
    File.binwrite(path, bytes)
  end

  def selection(platform, **options)
    StoreRelease::Screenshots.new(@project, platform, locales: "zh-CN", **options)
  end

  def test_ios_layout_is_native_and_locale_mapping_is_preserved
    images = selection("ios").prepare!
    parsed = Deliver::Loader.load_app_screenshots(images.path, false)
    assert_equal 1, parsed.length
    assert_equal "zh-Hans", parsed.first.language
    assert_equal "APP_IPHONE_61", parsed.first.display_type
  end

  def test_android_selection_and_graphics_are_staged_without_text
    png(File.join(@source, "google-play/feature/feature-graphic.png"), 1024, 500, 3)
    png(File.join(@root, "assets/shared-icons/google-play-512.png"), 512, 512, 4, alpha: true)
    images = selection("android", include_graphics: true).prepare!
    assert_equal %w[01-first.png 02-second.png], Dir.children(File.join(images.path, "zh-CN/images/phoneScreenshots")).sort
    assert File.file?(File.join(images.path, "zh-CN/images/icon.png"))
    assert File.file?(File.join(images.path, "zh-CN/images/featureGraphic.png"))
    assert_empty Dir.glob(File.join(images.path, "**/*.txt"))
    FileUtils.mkdir_p(File.join(@project.metadata_path("android"), "zh-CN"))
    text = File.join(@project.metadata_path("android"), "zh-CN/title.txt")
    File.write(text, "Keep this title")
    images.attach_to_metadata!
    assert_equal "Keep this title", File.read(text)
    assert File.file?(File.join(@project.metadata_path("android"), "zh-CN/images/icon.png"))
  end

  def test_missing_locale_does_not_silently_upload_a_partial_set
    assert_raises(RuntimeError) { StoreRelease::Screenshots.new(@project, "ios") }
  end

  def test_icon_stages_six_locales_without_needing_screenshots
    FileUtils.rm_rf(@source)
    png(File.join(@root, "assets/shared-icons/google-play-512.png"), 512, 512, 4, alpha: true)
    icon = StoreRelease::PlayIcon.new(@project).prepare!
    expected = StoreRelease::LOCALES.map { |locale| "#{locale}/images/icon.png" }.sort
    assert_equal expected, Dir.glob("**/*", base: icon.path).select { |path| File.file?(File.join(icon.path, path)) }.sort
    File.write(File.join(icon.path, "zh-CN/images/featureGraphic.png"), "stale staging file")
    StoreRelease::PlayIcon.new(@project, locales: "zh-CN").prepare!
    assert_equal ["zh-CN/images/icon.png"], Dir.glob("**/*.png", base: icon.path)
  end

  def test_icon_enforces_google_dimensions_format_and_size
    path = File.join(@root, "assets/shared-icons/google-play-512.png")
    png(path, 512, 512, 4)
    assert_match(/32-bit RGBA/, assert_raises(RuntimeError) { StoreRelease::PlayIcon.new(@project) }.message)
    png(path, 1024, 1024, 4, alpha: true)
    assert_match(/512x512/, assert_raises(RuntimeError) { StoreRelease::PlayIcon.new(@project) }.message)
    png(path, 512, 512, 4, alpha: true)
    File.open(path, "ab") { |file| file.write("\0" * (1024 * 1024)) }
    assert_match(/1024 KB/, assert_raises(RuntimeError) { StoreRelease::PlayIcon.new(@project) }.message)
  end

  def test_icon_lane_uploads_only_icon_with_all_other_content_skipped
    png(File.join(@root, "assets/shared-icons/google-play-512.png"), 512, 512, 4, alpha: true)
    file = Fastlane::FastFile.new(File.join(StoreRelease::ROOT, "fastlane/Fastfile"))
    project, captured = @project, nil
    project.config = { "package_name" => "com.annuo.pictools" }
    file.define_singleton_method(:release_project) { |*_| project }
    file.define_singleton_method(:google_key) { "test-only.json" }
    file.define_singleton_method(:upload_to_play_store) { |**settings| captured = settings }
    file.runner.execute(:icon, :android, { locales: "zh-CN" })
    %i[skip_upload_apk skip_upload_aab skip_upload_metadata skip_upload_changelogs skip_upload_screenshots sync_image_upload].each do |key|
      assert captured[key], "#{key} must be enabled for an icon-only upload"
    end
    refute captured[:skip_upload_images]
    refute captured[:changes_not_sent_for_review]
    assert_equal ["zh-CN/images/icon.png"], Dir.glob("**/*.png", base: captured[:metadata_path])
  end

  def test_alpha_and_wrong_device_dimensions_fail_before_staging
    file = File.join(@source, "app-store/phone/01-first.png")
    png(file, 1179, 2556, 1, alpha: true)
    assert_match(/alpha/, assert_raises(RuntimeError) { selection("ios") }.message)
    png(file, 1080, 1920, 1)
    assert_match(/does not match/, assert_raises(RuntimeError) { selection("ios") }.message)
  end

  def test_play_count_limit_and_duplicates_are_rejected
    first = File.join(@source, "google-play/phone/01-first.png")
    FileUtils.cp(first, File.join(File.dirname(first), "03-duplicate.png"))
    assert_match(/duplicate/, assert_raises(RuntimeError) { selection("android") }.message)
    9.times { |i| FileUtils.cp(first, File.join(File.dirname(first), "extra-#{i}.png")) }
    assert_match(/expected 1–8/, assert_raises(RuntimeError) { selection("android") }.message)
  end

  FakeImage = Struct.new(:id, :source_file_checksum, :asset_delivery_state, :owner) do
    def delete!
      owner.app_screenshots.delete(self)
    end
  end

  class FakeSet
    attr_reader :screenshot_display_type, :app_screenshots, :uploads, :orders
    def initialize(type)
      @screenshot_display_type, @app_screenshots, @uploads, @orders = type, [], [], []
    end
    def add(id, checksum)
      @app_screenshots << FakeImage.new(id, checksum, { "state" => "COMPLETE" }, self)
    end
    def upload_screenshot(path:, wait_for_processing:)
      @uploads << path
      add("upload-#{uploads.length}", Digest::MD5.file(path).hexdigest)
    end
    def reorder_screenshots(app_screenshot_ids:)
      @orders << app_screenshot_ids
      @app_screenshots = app_screenshot_ids.map { |id| @app_screenshots.find { |image| image.id == id } }
    end
  end

  def test_apple_reuses_matching_images_and_never_touches_other_device_sets
    images = selection("ios").prepare!
    target = FakeSet.new("APP_IPHONE_61")
    target.add("old", "outdated")
    other = FakeSet.new("APP_IPAD_PRO_3GEN_129")
    other.add("preserve", "unrelated")
    locale = OpenStruct.new(locale: "zh-Hans")
    locale.define_singleton_method(:get_app_screenshot_sets) { [target, other] }
    version = Object.new
    version.define_singleton_method(:get_app_store_version_localizations) { [locale] }
    uploader = StoreRelease::AppleScreenshotSync.new(version, images, timeout: 0)
    uploader.sync!
    assert_equal 1, target.uploads.length
    assert_equal ["preserve"], other.app_screenshots.map(&:id)
    assert_empty other.orders
    assert_equal 1, target.app_screenshots.length
    uploader.sync!
    assert_equal 1, target.uploads.length, "Retry must not upload duplicates"
  end

  def test_apple_missing_localizations_fail_before_upload
    version = Object.new
    version.define_singleton_method(:get_app_store_version_localizations) { [] }
    assert_match(/ios metadata/, assert_raises(RuntimeError) {
      StoreRelease::AppleScreenshotSync.new(version, selection("ios").prepare!).sync!
    }.message)
  end

  def test_apple_reorders_existing_images_without_uploading_again
    png(File.join(@source, "app-store/phone/02-second.png"), 1179, 2556, 2)
    images = selection("ios").prepare!
    hashes = images.groups.first[:files].map { |path| Digest::MD5.file(path).hexdigest }
    target = FakeSet.new("APP_IPHONE_61")
    target.add("second", hashes.last)
    target.add("first", hashes.first)
    locale = OpenStruct.new(locale: "zh-Hans")
    locale.define_singleton_method(:get_app_screenshot_sets) { [target] }
    version = Object.new
    version.define_singleton_method(:get_app_store_version_localizations) { [locale] }
    StoreRelease::AppleScreenshotSync.new(version, images, timeout: 0).sync!
    assert_empty target.uploads
    assert_equal [["first", "second"]], target.orders
  end

  def test_play_validation_always_discards_its_edit
    require "supply"
    file = Fastlane::FastFile.new(File.join(StoreRelease::ROOT, "fastlane/Fastfile"))
    [false, true].each do |fail_validation|
      client = OpenStruct.new(current_edit: nil, discarded: false)
      client.define_singleton_method(:abort_current_edit) { self.discarded = true; self.current_edit = nil }
      uploader = Object.new
      uploader.define_singleton_method(:client) { client }
      uploader.singleton_class.send(:private, :client)
      uploader.define_singleton_method(:perform_upload) do
        client.current_edit = "temporary-edit"
        raise "Validation rejected" if fail_validation
      end
      FastlaneCore::Configuration.stub(:create, {}) do
        Supply::Uploader.stub(:new, uploader) do
          if fail_validation
            assert_raises(RuntimeError) { file.upload_play_with_validation_cleanup(validate_only: true) }
          else
            file.upload_play_with_validation_cleanup(validate_only: true)
          end
        end
      end
      assert client.discarded
      assert_nil client.current_edit
    end
  end

  def test_screenshot_lane_skips_binaries_text_and_changelogs
    file = Fastlane::FastFile.new(File.join(StoreRelease::ROOT, "fastlane/Fastfile"))
    captured = nil
    project, images = @project, selection("android").prepare!
    project.config = { "package_name" => "com.annuo.pictools" }
    file.define_singleton_method(:release_project) { |*_| project }
    file.define_singleton_method(:prepare_screenshots) { |*_| images }
    file.define_singleton_method(:google_key) { "test-only.json" }
    file.define_singleton_method(:upload_to_play_store) { |**settings| captured = settings }
    file.runner.execute(:screenshots, :android, {})
    assert captured[:skip_upload_apk]
    assert captured[:skip_upload_aab]
    assert captured[:skip_upload_metadata]
    assert captured[:skip_upload_changelogs]
    assert captured[:skip_upload_images]
    refute captured[:skip_upload_screenshots]
    refute captured[:changes_not_sent_for_review]
    assert captured[:sync_image_upload]
    assert_equal images.path, captured[:metadata_path]
  end
end
