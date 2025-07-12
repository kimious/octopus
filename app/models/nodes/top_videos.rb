module Nodes
  class TopVideos < Node
    def batch(playlist_ids:)
      b = Sidekiq::Batch.new
      b.on(:success, self.class, { bid: b.bid, callbacks: @callbacks })
      b.jobs do
        playlist_ids.each do |playlist_id|
          self.class.perform_async("playlist_id" => playlist_id)
        end
      end
    end

    def perform(params)
      playlist_id = params["playlist_id"]
      yt_api = Youtube.new

      # TODO: replace this with youtube data api
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

      puts "stats: #{stats[0].statistics.view_count}"
      stats.sort! { |v1, v2| v2.statistics.view_count <=> v1.statistics.view_count }
      save_batch_result!(stats.take(5).map(&:id))
    end

    def on_success(status, options)
      @callbacks = options["callbacks"].deep_symbolize_keys
      notify!(:success, { video_ids: batch_result(options["bid"]) })
    end
  end
end
