require "minitest/autorun"
require "minitest/mock"
require "tmpdir"
require "ostruct"
require_relative "../lib/store_release"
require "fastlane"
Fastlane.load_actions

class StoreReleaseTest < Minitest::Test
  def setup
    @root = Dir.mktmpdir("pictools-store-test")
    FileUtils.cp(File.join(StoreRelease::ROOT, "pubspec.yaml"), @root)
    FileUtils.mkdir_p(File.join(@root, "fastlane"))
    %w[metadata release_notes store.json].each do |path|
      FileUtils.cp_r(File.join(StoreRelease::ROOT, "fastlane", path), File.join(@root, "fastlane"))
    end
  end

  def teardown
    FileUtils.remove_entry(@root)
  end

  def project(**options)
    StoreRelease::Project.new(root: @root, **options)
  end

  def edit_json(path)
    full_path = File.join(@root, path)
    value = JSON.parse(File.read(full_path))
    yield value
    File.write(full_path, JSON.pretty_generate(value))
  end

  def test_shared_notes_use_apple_locale_mapping_and_exact_play_version_code
    release = project(build_number: "42").prepare!
    StoreRelease::LOCALES.each do |locale|
      ios = File.join(release.metadata_path("ios"), StoreRelease.ios_locale(locale), "release_notes.txt")
      play = File.join(release.metadata_path("android"), locale, "changelogs/42.txt")
      assert_equal release.notes[locale], File.read(ios)
      assert_equal File.read(ios), File.read(play)
    end
    assert_equal %w[de-DE en-US es-ES fr-FR zh-Hans zh-Hant], Dir.children(release.metadata_path("ios")).sort
    assert_empty Dir.glob(File.join(release.output, "**/support_url.txt"))
    assert_empty Dir.glob(File.join(release.output, "**/copyright.txt"))
  end

  def test_omitted_field_is_removed_from_generated_output
    edit_json("fastlane/metadata/en-US.json") { |data| data["ios"]["support_url"] = "https://support.example.com" }
    release = project.prepare!
    path = File.join(release.metadata_path("ios"), "en-US/support_url.txt")
    assert File.file?(path)
    edit_json("fastlane/metadata/en-US.json") { |data| data["ios"].delete("support_url") }
    project.prepare!
    refute File.exist?(path)
  end

  def test_overlong_localized_title_is_rejected
    edit_json("fastlane/metadata/zh-CN.json") { |data| data["android"]["title"] = "图" * 31 }
    assert_match(/exceeds 30/, assert_raises(RuntimeError) { project }.message)
  end

  def test_new_version_requires_new_release_notes
    File.write(File.join(@root, "pubspec.yaml"), "version: 9.9.9+42\n")
    assert_match(%r{release_notes/9.9.9.json}, assert_raises(RuntimeError) { project }.message)
  end

  def test_keywords_respect_multibyte_limit
    edit_json("fastlane/metadata/zh-CN.json") { |data| data["ios"]["keywords"] = "图" * 34 }
    assert_match(/100 UTF-8 bytes/, assert_raises(RuntimeError) { project }.message)
  end

  def test_missing_translation_or_typo_cannot_silently_drop_copy
    version = project.version
    edit_json("fastlane/release_notes/#{version}.json") { |data| data.delete("fr-FR") }
    assert_raises(RuntimeError) { project }
  end

  def test_unknown_metadata_key_is_rejected
    edit_json("fastlane/metadata/en-US.json") { |data| data["ios"]["sub_title"] = "typo" }
    assert_match(/unsupported fields/, assert_raises(RuntimeError) { project }.message)
  end

  def test_build_number_cannot_inject_shell_options
    assert_raises(RuntimeError) { project(build_number: "3; touch /tmp/no") }
    release = project(build_number: "42")
    assert_includes release.build_command("android"), "--build-number=42"
    assert_includes release.build_command("ios"), "--export-method=app-store"
    assert_includes release.build_command("ios"), "--obfuscate"
  end

  def test_preview_escapes_user_copy
    edit_json("fastlane/metadata/en-US.json") { |data| data["ios"]["description"] = "<script>alert(1)</script>" }
    release = project.prepare!
    html = File.read(File.join(release.output, "preview.html"))
    assert_includes html, "&lt;script&gt;"
    refute_includes html, "<script>"
  end

  def test_false_options_are_false_and_invalid_values_fail
    refute StoreRelease.boolean("false")
    assert StoreRelease.boolean("true")
    assert StoreRelease.boolean(nil, default: true)
    assert_raises(ArgumentError) { StoreRelease.boolean("yes") }
  end

  def test_apple_does_not_rename_unrelated_or_touch_submitted_version
    record = OpenStruct.new(version_string: "1.1.0", app_version_state: "PREPARE_FOR_SUBMISSION")
    app = Object.new
    app.define_singleton_method(:get_edit_app_store_version) { |**_| record }
    assert_raises(RuntimeError) { StoreRelease.apple_version_preflight!(app, "1.2.0") }
    record.version_string = "1.2.0"
    record.app_version_state = "WAITING_FOR_REVIEW"
    assert_raises(RuntimeError) { StoreRelease.apple_version_preflight!(app, "1.2.0") }
    record.app_version_state = "PREPARE_FOR_SUBMISSION"
    assert_equal record, StoreRelease.apple_version_preflight!(app, "1.2.0")
  end

  def test_new_apple_locales_inherit_actual_primary_urls_only
    primary = OpenStruct.new(locale: "zh-Hans", privacy_policy_url: "https://current.example/privacy",
                             support_url: "https://current.example/support", marketing_url: nil)
    english = OpenStruct.new(locale: "en-US", privacy_policy_url: "https://english.example/privacy",
                             support_url: "https://english.example/support", marketing_url: nil)
    info = Object.new
    info.define_singleton_method(:get_app_info_localizations) { [primary, english] }
    record = Object.new
    record.define_singleton_method(:get_app_store_version_localizations) { [primary, english] }
    app = Object.new
    app.define_singleton_method(:fetch_edit_app_info) { info }
    app.define_singleton_method(:primary_locale) { "zh-Hans" }
    values = StoreRelease.apple_inherited_urls(app, project, record)
    assert_equal "https://current.example/support", values[:support_url]["zh-Hant"]
    refute values[:support_url].key?("en-US")
    refute values[:privacy_url].key?("zh-Hans")
    refute values.key?(:marketing_url)
    primary.support_url = nil
    assert_raises(RuntimeError) { StoreRelease.apple_inherited_urls(app, project, record) }
  end

  def fastfile
    Fastlane::FastFile.new(File.join(StoreRelease::ROOT, "fastlane/Fastfile"))
  end

  def test_play_production_draft_uses_normal_api_commit_without_review_flag_retry
    settings = fastfile.play_options(project, nil, { track: "production" }, upload: true)
    assert_equal "draft", settings[:release_status]
    refute settings[:changes_not_sent_for_review]
    refute settings[:rescue_changes_not_sent_for_review]
    assert settings[:skip_upload_images]
    assert settings[:skip_upload_screenshots]
  end

  def test_play_internal_is_explicitly_completed_and_metadata_is_not_a_binary_upload
    file = fastfile
    settings = file.play_options(project, nil, {}, upload: true)
    assert_equal "internal", settings[:track]
    assert_equal "completed", settings[:release_status]
    refute settings[:changes_not_sent_for_review]
    settings = file.play_options(project, nil, {})
    assert_equal "production", settings[:track]
    assert settings[:skip_upload_aab]
    refute settings[:changes_not_sent_for_review]
  end

  def test_explicit_play_review_hold_is_still_honored_without_silent_fallback
    settings = fastfile.play_options(project, nil, { send_for_review: false })
    assert settings[:changes_not_sent_for_review]
    refute settings[:rescue_changes_not_sent_for_review]
    assert settings[:skip_upload_aab]
  end

  def test_play_metadata_commits_via_api_without_uploading_a_build_or_changing_notes
    file, release, captured = fastfile, project.prepare!, nil
    file.define_singleton_method(:release_project) { |*_| release }
    file.define_singleton_method(:google_key) { "test-only.json" }
    file.define_singleton_method(:upload_play_with_validation_cleanup) { |settings| captured = settings }
    file.runner.execute(:metadata, :android, {})
    refute captured[:changes_not_sent_for_review]
    refute captured[:skip_upload_metadata]
    assert captured[:skip_upload_aab]
    assert captured[:skip_upload_apk]
    assert captured[:skip_upload_changelogs]
    assert captured[:skip_upload_screenshots]
    assert captured[:skip_upload_images]
  end

  def test_failed_flutter_export_cannot_return_a_stale_artifact
    FileUtils.mkdir_p(File.join(@root, "android"))
    File.write(File.join(@root, "android/key.properties"), "")
    artifact = File.join(@root, "build/app/outputs/bundle/release/app-release.aab")
    FileUtils.mkdir_p(File.dirname(artifact))
    File.write(artifact, "old artifact")
    File.utime(Time.at(1), Time.at(1), artifact)
    file = fastfile
    # Reproduce a tool that reports success without exporting a new package.
    file.define_singleton_method(:sh) { |*_| true }
    error = assert_raises(FastlaneCore::Interface::FastlaneError) { file.compile_flutter(project, "android") }
    assert_match(/freshly built/, error.message)
  end

  def test_dry_run_release_never_authenticates_builds_or_uploads
    file = fastfile
    release = project.prepare!
    file.define_singleton_method(:release_project) { |*_| release }
    %i[apple_key google_key compile_flutter upload_to_testflight upload_to_play_store sync_apple_metadata].each do |name|
      file.define_singleton_method(name) { |*_| raise "Unexpected side effect: #{name}" }
    end
    file.runner.execute(:release, :ios, { dry_run: "true" })
    file.runner.execute(:release, :android, { dry_run: "true" })
  end

  def test_play_promotion_reuses_existing_binary_and_notes
    file = fastfile
    release = project(build_number: "42").prepare!
    captured = nil
    file.define_singleton_method(:release_project) { |*_| release }
    file.define_singleton_method(:google_key) { "unused-test-key.json" }
    file.define_singleton_method(:compile_flutter) { |*_| raise "Promotion must not rebuild" }
    file.define_singleton_method(:upload_to_play_store) { |**settings| captured = settings }
    file.runner.execute(:promote, :android, { version_code: "42" })
    assert_equal 42, captured[:version_code]
    assert_equal "internal", captured[:track]
    assert_equal "production", captured[:track_promote_to]
    assert_equal "draft", captured[:track_promote_release_status]
    assert captured[:skip_upload_aab]
    assert captured[:skip_upload_metadata]
    assert captured[:skip_upload_changelogs]
  end

  def test_select_build_uses_exact_valid_version_and_manual_release
    require "spaceship"
    record = OpenStruct.new(version_string: project.version, app_version_state: "PREPARE_FOR_SUBMISSION", release_type: "AFTER_APPROVAL")
    selected, updated = nil, nil
    record.define_singleton_method(:select_build) { |build_id:| selected = build_id }
    record.define_singleton_method(:update) { |attributes:| updated = attributes }
    app = OpenStruct.new(id: "app")
    app.define_singleton_method(:get_edit_app_store_version) { |**_| record }
    build = OpenStruct.new(id: "exact-build", version: project.build_number, processing_state: "VALID", expired: false)
    Spaceship::ConnectAPI::Build.stub(:all, ->(**filters) {
      assert_equal project.version, filters[:version]
      assert_equal project.build_number, filters[:build_number]
      [build]
    }) { StoreRelease.apple_select_build!(app, project) }
    assert_equal "exact-build", selected
    assert_equal({ releaseType: "MANUAL" }, updated)
    build.processing_state = "PROCESSING"
    Spaceship::ConnectAPI::Build.stub(:all, [build]) do
      assert_raises(RuntimeError) { StoreRelease.apple_select_build!(app, project) }
    end
  end

  def test_submit_play_draft_replaces_previous_completed_entry_and_keeps_notes
    live = OpenStruct.new(status: "completed", version_codes: ["2"])
    draft = OpenStruct.new(status: "draft", version_codes: ["3"], release_notes: ["keep notes"])
    track = OpenStruct.new(releases: [live, draft])
    client, updated = Object.new, nil
    client.define_singleton_method(:tracks) { |name| raise unless name == "production"; [track] }
    client.define_singleton_method(:update_track) { |name, data| updated = [name, data] }
    StoreRelease.prepare_play_submission!(client, "3")
    assert_equal "completed", draft.status
    assert_equal [draft], updated.last.releases
    assert_equal "completed", live.status
    assert_equal ["keep notes"], draft.release_notes
    assert_raises(RuntimeError) { StoreRelease.prepare_play_submission!(client, "3") }
    assert_raises(RuntimeError) { StoreRelease.prepare_play_submission!(client, "99") }
  end

  def test_submit_dry_runs_have_no_remote_effects
    file, release = fastfile, project.prepare!
    file.define_singleton_method(:release_project) { |*_| release }
    %i[apple_key google_key upload_to_app_store upload_to_play_store].each do |name|
      file.define_singleton_method(name) { |*_| raise "Unexpected side effect: #{name}" }
    end
    file.runner.execute(:submit, :ios, { dry_run: "true" })
    file.runner.execute(:submit, :android, { dry_run: "true" })
  end

  def test_production_upload_keeps_live_release_and_rejects_another_draft
    require_relative "../lib/store_play"
    Supply.config = { track: "production", release_status: "draft", version_name: "1.2.0" }
    live = OpenStruct.new(status: "completed", version_codes: ["2"])
    track = OpenStruct.new(releases: [live])
    client = Object.new
    client.define_singleton_method(:tracks) { |_| [track] }
    updates = []
    client.define_singleton_method(:update_track) { |name, data| updates << [name, data] }
    uploader = StoreRelease::ProductionDraftUploader.new
    uploader.define_singleton_method(:client) { client }
    uploader.send(:update_track, [3])
    assert_equal live, track.releases.first
    assert_equal "completed", track.releases.first.status
    assert_equal "draft", track.releases.last.status
    assert_equal [3], track.releases.last.version_codes
    assert_raises(RuntimeError) { uploader.send(:update_track, [4]) }
    assert_equal 1, updates.length
  end

  def test_binary_staging_cannot_upload_global_listing_or_change_draft_status
    file, release, captured = fastfile, project.prepare!, nil
    file.define_singleton_method(:release_project) { |*_| release }
    file.define_singleton_method(:google_key) { "unused-test-key.json" }
    file.define_singleton_method(:compile_flutter) { |*_| "fresh.aab" }
    file.define_singleton_method(:upload_play_with_validation_cleanup) { |settings| captured = settings }
    file.runner.execute(:stage_binary, :android, { skip_checks: true, validate_only: true, track: "internal", release_status: "completed", screenshots: true, include_graphics: true })
    assert_equal "production", captured[:track]
    assert_equal "draft", captured[:release_status]
    assert captured[:skip_upload_metadata]
    assert captured[:skip_upload_images]
    assert captured[:skip_upload_screenshots]
    refute captured[:skip_upload_changelogs]
    refute captured[:changes_not_sent_for_review]
    refute captured[:rescue_changes_not_sent_for_review]
    assert captured[:validate_only]
  end

  def apple_update_fixture(release)
    patches = []
    localizations = release.notes.map do |locale, text|
      item = OpenStruct.new(locale: StoreRelease.ios_locale(locale), whats_new: text,
                            description: "Remote description", keywords: "remote")
      item.define_singleton_method(:update) do |attributes:|
        patches << [self.locale, attributes]
        self.whats_new = attributes.fetch(:whatsNew)
      end
      item
    end
    record = OpenStruct.new(version_string: release.version, app_version_state: "PREPARE_FOR_SUBMISSION")
    record.define_singleton_method(:get_app_store_version_localizations) { localizations }
    app = OpenStruct.new(id: "app")
    app.define_singleton_method(:get_edit_app_store_version) { |**_| record }
    [app, record, localizations, patches]
  end

  def test_routine_apple_update_changes_only_different_notes_and_is_idempotent
    release = project
    app, record, localizations, patches = apple_update_fixture(release)
    localizations.first.whats_new = "Old release note"
    assert_equal record, StoreRelease.apple_prepare_update!(app, release)
    assert_equal [["zh-Hans", { whatsNew: release.notes.fetch("zh-CN") }]], patches
    assert_equal "Remote description", localizations.first.description
    assert_equal "remote", localizations.first.keywords
    patches.clear
    StoreRelease.apple_prepare_update!(app, release)
    assert_empty patches
  end

  def test_routine_apple_update_creates_version_without_local_listing_fields
    require "spaceship"
    release = project
    app, record, _, patches = apple_update_fixture(release)
    app.define_singleton_method(:get_edit_app_store_version) { |**_| nil }
    app.define_singleton_method(:get_app_store_versions) { |**_| [] }
    response = OpenStruct.new(to_models: [record])
    Spaceship::ConnectAPI.stub(:post_app_store_version, ->(**request) {
      assert_equal({ app_id: "app", attributes: { versionString: release.version, platform: "IOS", releaseType: "MANUAL" } }, request)
      response
    }) do
      assert_equal record, StoreRelease.apple_prepare_update!(app, release)
    end
    assert_empty patches
  end

  def test_routine_apple_update_rejects_missing_locale_before_changing_notes
    release = project
    app, _, localizations, patches = apple_update_fixture(release)
    localizations.first.whats_new = "Old note"
    localizations.pop
    error = assert_raises(RuntimeError) { StoreRelease.apple_prepare_update!(app, release) }
    assert_match(/missing locales: de-DE/, error.message)
    assert_empty patches
  end

  def test_ios_binary_staging_skips_listing_and_review_even_with_extra_options
    require "spaceship"
    file, release, captured, calls = fastfile, project.prepare!, nil, []
    app = Object.new
    file.define_singleton_method(:release_project) { |*_| release }
    file.define_singleton_method(:apple_key) { "test-key" }
    file.define_singleton_method(:compile_flutter) { |*_| "fresh.ipa" }
    %i[sync_apple_metadata sync_apple_screenshots upload_to_app_store prepare_screenshots].each do |name|
      file.define_singleton_method(name) { |*_| raise "Unexpected listing/review action: #{name}" }
    end
    file.define_singleton_method(:upload_to_testflight) { |**settings| captured = settings; calls << :uploaded }
    Spaceship::ConnectAPI::App.stub(:find, app) do
      StoreRelease.stub(:apple_prepare_update!, ->(*args) { assert_equal [app, release], args; calls << :prepared }) do
        StoreRelease.stub(:apple_select_build!, ->(*args) { assert_equal [app, release], args; calls << :selected }) do
          file.runner.execute(:stage_binary, :ios, { skip_checks: true, screenshots: true, submit_for_review: true })
        end
      end
    end
    assert_equal [:prepared, :uploaded, :selected], calls
    assert captured[:skip_submission]
    refute captured[:distribute_external]
    refute captured[:notify_external_testers]
    refute captured[:skip_waiting_for_build_processing]
    refute captured.key?(:localized_app_info)
    assert_equal release.localized_beta_notes, captured[:localized_build_info]
  end

  def test_routine_update_dry_runs_never_access_stores_or_build
    file, release = fastfile, project.prepare!
    file.define_singleton_method(:release_project) { |*_| release }
    %i[apple_key google_key compile_flutter upload_to_testflight upload_play_with_validation_cleanup].each do |name|
      file.define_singleton_method(name) { |*_| raise "Unexpected side effect: #{name}" }
    end
    file.runner.execute(:prepare_update, :ios, { dry_run: true })
    file.runner.execute(:stage_binary, :ios, { dry_run: true })
    file.runner.execute(:stage_binary, :android, { dry_run: true })
  end

  def test_production_upload_fills_only_an_empty_console_draft
    require_relative "../lib/store_play"
    Supply.config = { track: "production", release_status: "draft", version_name: "1.2.0" }
    live = OpenStruct.new(status: "completed", version_codes: ["2"])
    track = OpenStruct.new(releases: [OpenStruct.new(status: "draft"), live])
    client = Object.new
    client.define_singleton_method(:tracks) { |_| [track] }
    client.define_singleton_method(:update_track) { |*_| }
    uploader = StoreRelease::ProductionDraftUploader.new
    uploader.define_singleton_method(:client) { client }
    uploader.send(:update_track, [3])
    assert_equal 2, track.releases.length
    assert_equal live, track.releases.first
    assert_equal "draft", track.releases.last.status
    assert_equal [3], track.releases.last.version_codes
  end
end
