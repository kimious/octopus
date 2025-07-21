module Nodes
  class Transcripts < Node
    def_input :videos, batch_as: :video
    def_output :transcript_ids

    def perform(video)
      res = Youtube.new.transcript(video["id"])
      blob = Blob.create!(
        kind: "yt_transcript",
        metadata: { video_id: video["id"] },
        value: res["transcript"]
      )
      save_batch_result!(transcript_ids: blob.id)
    end
  end
end
