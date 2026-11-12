require "supply"

module StoreRelease
  # Supply normally replaces the track's release array. Staging a production
  # draft must preserve the currently published release until review completes.
  class ProductionDraftUploader < Supply::Uploader
    private

    def update_track(version_codes)
      return if version_codes.empty?
      raise "Expected a production draft" unless Supply.config[:track] == "production" && Supply.config[:release_status] == "draft"
      track = client.tracks("production").first || Google::Apis::AndroidpublisherV3::Track.new(track: "production", releases: [])
      releases = track.releases || []
      drafts = releases.select { |release| release.status == "draft" }
      raise "A production draft already exists. Resume it in Play Console or submit it with android submit." if drafts.length > 1 || drafts.any? { |release| !(release.version_codes || []).empty? }
      # Console can create an empty draft before any bundle is selected. Fill
      # that placeholder, but never replace a draft containing a real build.
      track.releases = (releases - drafts) + [Google::Apis::AndroidpublisherV3::TrackRelease.new(
        name: Supply.config[:version_name], status: "draft", version_codes: version_codes
      )]
      client.update_track("production", track)
    end
  end
end
