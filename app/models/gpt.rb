class Gpt
  def initialize(api_key)
    @api_key = api_key
  end

  def chat_completion(system_prompt, user_prompt)
    messages = [
      { role: "system", content: system_prompt },
      { role: "user", content: user_prompt }
    ]

    client.chat.completions.create(
      messages:,
      model: "gpt-4.1-nano-2025-04-14"
    )
  end

  def client
    @client ||= OpenAI::Client.new(api_key: @api_key)
  end
end
