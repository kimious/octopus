module Nodes
  class Transcripts < Node
    describe "A node to retrieve transcripts for multiple YouTube videos"
    has_input :videos,
      type: Array[{ id: String, title: String, published_at: DateTime, view_count: Integer }],
      batch_as: :video,
      description: "The list of videos including the id for each"
    has_output :transcript_ids,
      type: Array[Integer],
      description: "The list of transcript IDs for each video"

    def perform(video)
      res = Youtube.new(nil).transcript(video["id"])
      blob = Blob.create!(
        kind: "yt_transcript",
        metadata: { video_id: video["id"] },
        value: res["transcript"]
      )
      save_batch_result!(transcript_ids: blob.id)
    end
  end
end
