module Nodes
  class ChannelInfo < Node
    describe "A node to fetch information about YouTube channels"
    has_input :urls,
      type: Array[String],
      batch_as: :url,
      description: "The list of YouTube channel URLs"
    has_output :channels,
      type: Array[{ title: String, subscriber_count: Integer, playlist_id: String }],
      description: "The list of Youtube channels"

    requires_credential :youtube_api_key

    def perform(url)
      youtube_credential = credential("youtube_api_key")
      channel = Youtube.new(youtube_credential.data["api_key"]).channel(url)

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
