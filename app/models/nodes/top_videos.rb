module Nodes
  class TopVideos < Node
    has_input :channels, batch_as: :channel
    has_output :videos

    def perform(channel)
      yt_api = Youtube.new
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
        video_stats.take(1).map do |v|
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
