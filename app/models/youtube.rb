class Youtube
  # documentation: https://www.rubydoc.info/gems/google-apis-youtube_v3/0.4.0/Google/Apis/YoutubeV3/YouTubeService

  class StopBrowsing < StandardError; end

  def initialize
    @api_key = ENV.fetch("YOUTUBE_API_KEY")
  end

  def channel(url)
    handle = url.split("@").last
    result = service.list_channels("id,contentDetails", for_handle: handle)
    result.items[0]
  end

  def videos(playlist_id)
    next_page_token = nil
    results = []

    loop do
      result = service.list_playlist_items(
        "snippet",
        playlist_id:,
        max_results: 100,
        page_token: next_page_token
      )
      result.items.each { |i| results << i }
      next_page_token = result.next_page_token
      break unless next_page_token
    end

    results
  end

  def browse_videos(playlist_id, &block)
    next_page_token = nil

    loop do
      result = service.list_playlist_items(
        "snippet",
        playlist_id:,
        max_results: 100,
        page_token: next_page_token
      )

      block.call(result.items)

      next_page_token = result.next_page_token
      break unless next_page_token
    rescue StopBrowsing
      break
    end
  end

  def video_statistics(video_ids)
    results = []

    video_ids.each_slice(50).to_a.each do |ids|
      result = service.list_videos(
        "contentDetails,statistics",
        id: ids.join(","),
        max_results: 50
      )
      result.items.each { |i| results << i }
    end

    results
  end

  def transcript(video_id)
    uri = URI("#{ENV.fetch('YOUTUBE_TRANSCRIPT_API_BASE_URL')}/transcripts/#{video_id}")
    req = Net::HTTP::Get.new(uri)
    # TODO: secure
    req["Authorization"] = "Bearer #{}"
    req["Content-Type"] = "application/json"
    res = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }
    JSON.parse(res.body)
  end

  def service
    return @service if @service

    @service = Google::Apis::YoutubeV3::YouTubeService.new
    @service.key = @api_key
    @service
  end
end
