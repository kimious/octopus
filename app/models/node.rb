class Node
  include Sidekiq::Job

  sidekiq_options retry: 0
  sidekiq_options backtrace: true

  sidekiq_retries_exhausted do |job, error|
    callbacks = REDIS.smembers("BID-#{job["bid"]}-callbacks-success")
    callback = JSON.parse(callbacks[0])
    workflow_instance_id = callback.dig("opts", "callbacks", "success", "params", "workflow_instance_id")
    node_name = callback.dig("opts", "callbacks", "success", "params", "node_name")

    instance = WorkflowInstance.find(workflow_instance_id)
    instance.log_failure!(
      error: error.class.name,
      message: error.message,
      node_name:,
      params: job["args"],
      location: error.backtrace.first
    )
  end

  class MultipleBatchInput < StandardError; end

  attr_writer :workflow_instance, :node_name

  class << self
    attr_reader :description
    attr_reader :inputs
    attr_reader :outputs
    attr_reader :credentials

    def inputs = (@inputs ||= {})

    def outputs = (@outputs ||= {})

    def credentials = (@credentials ||= [])

    def describe(description)
      @description = description
    end

    def has_input(input, options = {})
      inputs[input] = options
      if options[:batch_as]
        raise MultipleBatchInput if method_defined?(:perform_batch)

        def_batch(input, options[:batch_as])
      end
    end

    def has_output(output, options = {})
      outputs[output] = options
    end

    def valid_input?(input) = inputs.key?(input)

    def valid_output?(output) = outputs.key?(output)

    def def_batch(input, batch_input)
      define_method(:perform_batch) do |params|
        input = params[input.to_s]
        input = input.respond_to?(:each) ? input : [ input ]

        batch = Sidekiq::Batch.new
        batch.on(:success, self.class, { bid: batch.bid, callbacks: @callbacks })
        batch.jobs do
          input.each do |item|
            self.class.perform_async(item, *input_values(params))
          end
        end
      end

      define_method(:on_success) do |status, options|
        @callbacks = options["callbacks"].deep_symbolize_keys
        notify!(:success, batch_result(options["bid"]))
      end
    end

    def requires_credential(credential)
      credentials << credential
    end

    def node_for(node_name) = Nodes.const_get(node_name.split("#")[0].camelize)

    def node_name = name.demodulize.underscore
  end

  def workflow_instance
    return @workflow_instance if @workflow_instance

    @callbacks ||= REDIS.smembers("BID-#{bid}-callbacks-success")
    callback = JSON.parse(@callbacks[0])
    workflow_instance_id = callback.dig("opts", "callbacks", "success", "params", "workflow_instance_id")

    @workflow_instance = WorkflowInstance.find(workflow_instance_id)
  end

  def node_name
    return @node_name if @node_name

    @callbacks ||= REDIS.smembers("BID-#{bid}-callbacks-success")
    callback = JSON.parse(@callbacks[0])
    @node_name = callback.dig("opts", "callbacks", "success", "params", "node_name")
  end

  def input_values(inputs)
    self.class.inputs.keys
      .select { |input| !self.class.inputs[input][:batch_as] }
      .map { |input| inputs[input.to_s] }
  end

  def batch? = respond_to?(:perform_batch)

  def batch_result(bid)
    self.class.outputs.keys.reduce({}) do |result, output|
      result[output] = REDIS.lrange("#{bid}_#{output}_result", 0, -1)
      result[output] = result[output].map { |item| JSON.parse(item) }
      result
    end
  end

  def save_batch_result!(outputs)
    REDIS.multi do |transaction|
      outputs.each do |output, result|
        transaction.lpush(
          "#{bid}_#{output}_result",
          result.is_a?(Array) ? result.map { |r| JSON.dump(r) } : JSON.dump(result)
        )
      end
    end
  end

  def on(status, listener, params = {})
    @callbacks ||= {}
    @callbacks[status] = { listener:, params: }
  end

  def notify!(status, result)
    callback = @callbacks[status]
    callback[:listener].constantize.send("on_#{status}", callback[:params].merge(result:))
  end

  def credential(kind)
    @credentials ||= {}

    return @credentials[kind] if @credentials.key?(kind)

    @credentials[kind] = Credential.find(workflow_instance.schema[node_name]["credentials"][kind])
  end
end
