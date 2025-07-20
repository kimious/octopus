module Nodes
  class ChannelPlaylists < Node
    node_inputs :urls

    def perform_batch(workflow_instance_id:, urls:)
      b = Sidekiq::Batch.new
      b.on(:success, self.class, { bid: b.bid, callbacks: @callbacks })
      b.jobs do
        urls.each do |url|
          self.class.perform_async("workflow_instance_id" => workflow_instance_id, "url" => url)
        end
      end
    end

    def perform(params)
      channel = Youtube.new.channel(params["url"])
      # this returns the channel's playlist id to browse videos
      save_batch_result!(channel.content_details.related_playlists.uploads)
    end

    def on_success(status, options)
      @callbacks = options["callbacks"].deep_symbolize_keys
      notify!(:success, { playlist_ids: batch_result(options["bid"]) })
    end
  end
end
