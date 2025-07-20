class Node
  include Sidekiq::Job

  attr_accessor :workflow_instance

  class << self
    attr_reader :inputs

    def node_inputs(*input_names)
      @inputs = input_names
    end
  end

  def read_input(path)
    return nil unless path.include?(".")

    segments = path.split(".")
    case segments[0]
    when "root"
      workflow_instance.args.dig(*segments[1..-1])
    else
      workflow_instance.context.dig("#{segments[0]}", "inputs", *segments[1..-1])
    end
  end

  def read_ouput(path)
    return nil unless path.include?(".")

    segments = path.split(".")
    workflow_instance.context.dig("#{segments[0]}", "outputs", *segments[1..-1])
  end

  def batch? = respond_to?(:perform_batch)

  def batch_result(bid) = REDIS.lrange("#{bid}_result", 0, -1)

  def save_batch_result!(result)
    REDIS.lpush("#{bid}_result", result)
  end

  def on(status, listener, params = {})
    @callbacks ||= {}
    @callbacks[status] = { listener:, params: }
  end

  def notify!(status, result)
    callback = @callbacks[status]
    callback[:listener].constantize.send("on_#{status}", callback[:params].merge(result:))
  end
end
