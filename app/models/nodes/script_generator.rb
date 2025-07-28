module Nodes
  class ScriptGenerator < Node
    has_input :analysis_ids
    has_input :video_prompt
    has_output :script_id

    def perform(analysis_ids, video_prompt)
      analysis_list = Blob.find(analysis_ids)

      generated_script = Gpt.new.chat_completion(
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
