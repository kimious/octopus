class Node
  include Sidekiq::Job

  class MultipleBatchInput < StandardError; end

  attr_accessor :workflow_instance

  class << self
    attr_reader :inputs
    attr_reader :outputs

    def def_input(input, options = {})
      (@inputs ||= {})[input] = options
      if options[:batch_as]
        raise MultipleBatchInput if method_defined?(:perform_batch)

        def_batch(input, options[:batch_as])
      end
    end

    def def_output(output, options = {})
      (@outputs ||= {})[output] = options
    end

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

    def node_for(node_name) = Nodes.const_get(node_name.split("#")[0].camelize)

    def node_name = name.demodulize.underscore
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
end
