module Nodes
  class Transcripts < Node
    node_inputs :video_ids

    def perform_batch(workflow_instance_id:, video_ids:)
      b = Sidekiq::Batch.new
      b.on(:success, self.class, { bid: b.bid, callbacks: @callbacks })
      b.jobs do
        video_ids.each do |video_id|
          self.class.perform_async("workflow_instance_id" => workflow_instance_id, "video_id" => video_id)
        end
      end
    end

    def perform(params)
      video_id = params["video_id"]
      res = Youtube.new.transcript(video_id)
      blob = Blob.create!(
        kind: "yt_transcript",
        metadata: { video_id: },
        value: res["transcript"]
      )

      save_batch_result!(blob.id)
    end

    def on_success(status, options)
      @callbacks = options["callbacks"].deep_symbolize_keys
      notify!(:success, { transcript_ids: batch_result(options["bid"]) })
    end
  end
end
