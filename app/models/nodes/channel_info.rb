module Nodes
  class ChannelInfo < Node
    has_input :urls, batch_as: :url
    has_input :min_subscribers
    has_output :channels
    requires_credential :youtube_api_key

    def perform(url, min_subscribers)
      youtube_credential = credential("youtube_api_key")
      channel = Youtube.new(youtube_credential.data["api_key"]).channel(url)

      if channel.statistics.subscriber_count > min_subscribers
          save_batch_result!(
            channels: {
              title: channel.snippet.title,
              subscriber_count: channel.statistics.subscriber_count,
              playlist_id: channel.content_details.related_playlists.uploads
            }
          )
      end
    end
  end
end
