module Nodes
  class ChannelInfo < Node
    def_input :urls, batch_as: :url
    def_input :min_subscribers
    def_output :channels

    def perform(url, min_subscribers)
      channel = Youtube.new.channel(url)
      if channel.statistics.subscriber_count > min_subscribers
          save_batch_result!(
            channels: {
              title: channel.snippet.title,
              custom_url: channel.snippet.custom_url,
              published_at: channel.snippet.published_at,
              view_count: channel.statistics.view_count,
              subscriber_count: channel.statistics.subscriber_count,
              playlist_id: channel.content_details.related_playlists.uploads
            }
          )
      end
    end
  end
end
