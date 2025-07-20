module Nodes
  class TopVideos < Node
    node_inputs :playlist_ids

    def perform_batch(workflow_instance_id:, playlist_ids:)
      b = Sidekiq::Batch.new
      b.on(:success, self.class, { bid: b.bid, callbacks: @callbacks })
      b.jobs do
        playlist_ids.each do |playlist_id|
          self.class.perform_async("workflow_instance_id" => workflow_instance_id, "playlist_id" => playlist_id)
        end
      end
    end

    def perform(params)
      playlist_id = params["playlist_id"]
      yt_api = Youtube.new

      # TODO
      # This node does not use the .search endpoint but rather .list_playlist_items
      video_ids = []

      yt_api.browse_videos(playlist_id) do |videos|
        videos.each do |video|
          if video.snippet.published_at > 3.months.ago
            video_ids << video.snippet.resource_id.video_id
          else
            raise Youtube::StopBrowsing
          end
        end
      end

      stats = yt_api.video_statistics(video_ids)
      stats.reject! do |video|
        ActiveSupport::Duration.parse(video.content_details.duration) < 5.minutes
      end
      stats.sort! { |v1, v2| v2.statistics.view_count <=> v1.statistics.view_count }
      save_batch_result!(stats.take(1).map(&:id))
    end

    def on_success(status, options)
      @callbacks = options["callbacks"].deep_symbolize_keys
      notify!(:success, { video_ids: batch_result(options["bid"]) })
    end
  end
end
