module Nodes
  class TopVideos < Node
    describe "A node to retrieve the 5 most viewed videos in the last 3 months for multiple YouTube channels"
    has_input :channels,
      type: Array[{ title: String, subscriber_count: Integer, playlist_id: String }],
      batch_as: :channel,
      description: "The list of YouTube channels to fetch videos from"
    has_output :videos,
      type: Array[{ id: String, title: String, published_at: DateTime, view_count: Integer }],
      description: "The list of videos"
    requires_credential :youtube_api_key

    def perform(channel)
      youtube_credential = credential("youtube_api_key")
      yt_api = Youtube.new(youtube_credential.data["api_key"])
      video_ids = []

      yt_api.browse_videos(channel["playlist_id"]) do |videos|
        videos.each do |video|
          if video.snippet.published_at > 3.months.ago
            video_ids << video.snippet.resource_id.video_id
          else
            raise Youtube::StopBrowsing
          end
        end
      end

      video_stats = yt_api.video_statistics(video_ids)
      video_stats.reject! do |video|
        ActiveSupport::Duration.parse(video.content_details.duration) < 5.minutes
      end
      video_stats.sort! { |v1, v2| v2.statistics.view_count <=> v1.statistics.view_count }
      videos =
        video_stats.take(5).map do |v|
          {
            id: v.id,
            title: v.snippet.title,
            published_at: v.snippet.published_at,
            view_count: v.statistics.view_count
          }
        end
      save_batch_result!(videos:) if videos.any?
    end
  end
end
