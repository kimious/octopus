module Nodes
  class ScriptAnalyzer < Node
    node_inputs :blob_ids

    def perform_batch(workflow_instance_id:, blob_ids:)
      b = Sidekiq::Batch.new
      b.on(:success, self.class, { bid: b.bid, callbacks: @callbacks })
      b.jobs do
        blob_ids.each do |blob_id|
          self.class.perform_async("workflow_instance_id" => workflow_instance_id, "blob_id" => blob_id)
        end
      end
    end

    def perform(params)
      puts "context from ScriptAnalyzer #{workflow_instance.context}"

      blob_id = params["blob_id"]
      blob = Blob.find(blob_id)

      analysis = Gpt.new.chat_completion(
        "
        You are an expert YouTube scriptwriter.
        You will be given a script of a video (within triple double quotes) that performed really well on YouTube.
        Explain why the script worked and identity elements, techniques and methods
        that could used or even improved in order to make another successful video.
        ",
        "\"\"\"#{blob.value}\"\"\""
      )
      analysis_blob = Blob.create!(
        kind: "yt_video_analysis",
        metadata: { transcript_id: blob.id, video_id: blob.metadata["video_id"] },
        value: analysis.choices.first&.message&.content
      )
      save_batch_result!(analysis_blob.id)
    end

    def on_success(status, options)
      @callbacks = options["callbacks"].deep_symbolize_keys
      notify!(:success, { analysis_ids: batch_result(options["bid"]) })
    end
  end
end
