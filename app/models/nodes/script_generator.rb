module Nodes
  class ScriptGenerator < Node
    describe "A node to generate a YouTube video script based on the analysis of other video scripts"
    has_input :analysis_ids,
      type: Array[Integer],
      description: "The list of analysis IDs to use as strategic principles"
    has_input :video_prompt,
      type: String,
      description: "The prompt that describes the video to make"
    has_output :script_id,
      type: Integer,
      description: "ID of the newly generated script"
    requires_credential :openai_api_key

    def perform(analysis_ids, video_prompt)
      openai_credential = credential("openai_api_key")
      analysis_list = Blob.find(analysis_ids)

      generated_script = Gpt.new(openai_credential.data["api_key"]).chat_completion(
        "
        You are an expert YouTube scriptwriter.
        Write a title and script for #{video_prompt} using the analysis below:
        ",
        analysis_list.map { |a| "\"\"\"#{a.value}\"\"\"" }.join("\n")
      )

      result = "
        Sur la base de ce prompt : \"#{video_prompt}\",\n
        voici le script que je te propose:\n
        \"\"\"#{generated_script.choices.first&.message&.content}\"\"\"
      "

      script_blob = Blob.create!(
        kind: "yt_generated_script",
        metadata: { analysis_ids: },
        value: result
      )

      { script_id: script_blob.id }
    end
  end
end
