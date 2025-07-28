class WorkflowBuilder
  attr_reader :schema
  attr_reader :errors, :warnings

  REF_REGEXP = /\A\w+#\d+\z/
  NODE_OUTPUT_REGEXP = /\A((\w+#\d+)|trigger)(\.\w+)+\z/

  def initialize
    @schema = {}
    @errors = []
    @warnings = []
  end

  # TODO:
  # - detect missing required inputs for each node
  def parse_json!(json)
    json = JSON.parse(json)
    nodes = {}
    errors.clear
    warnings.clear

    trigger = set_trigger(json.dig("trigger", "params") || [])
    json_nodes = json["nodes"] || {}

    json_nodes.each do |node_ref, node_config|
      if !node_ref.match(REF_REGEXP)
        error(
          code: :invalid_node_ref,
          key: "nodes.#{node_ref}",
          message: "node '#{node_ref}' in object 'nodes' is not a valid node reference (valid node references must match regexp /\A\w+#\d+\z/)"
        )
        next
      end

      node = add_node(node_ref)
      nodes[node_ref] = node
    end

    json_nodes.each do |node_ref, node_config|
      node = nodes[node_ref]
      node.set_initial(true) if node_config["initial_node"]

      next unless node_config["inputs"]

      node_config["inputs"].each do |input, input_config|
        case input_config["source"]
        when "context"
          if !input_config["path"]
            error(
              code: :missing_input_source_path,
              key: "nodes.#{node_ref}.inputs.#{input}",
              message: "property 'path' is missing in object 'nodes.#{node_ref}.inputs.#{input}' (context source inputs must define a path)"
            )
            next
          end

          if !input_config["path"].match(NODE_OUTPUT_REGEXP)
            error(
              code: :invalid_input_source_path,
              key: "nodes.#{node_ref}.inputs.#{input}.path",
              value: input_config["path"],
              message: "value '#{input_config["path"]}' of property 'nodes.#{node_ref}.inputs.#{input}.path' is not a valid input path (valid input path must match regexp /\A((\w+#\d+)|trigger)(\.\w+)+\z/)"
            )
            next
          end

          path_segments = input_config["path"].split(".")
          source_node_ref = path_segments.first
          source_node_output = path_segments[1..-1].join(".")

          if source_node_ref == node_ref
            error(
              code: :self_referencing_node,
              key: "nodes.#{node_ref}.inputs.#{input}.path",
              value: source_node_ref,
              message: "path '#{input_config["path"]}' in 'nodes.#{node_ref}.inputs.#{input}.path' cannot reference node '#{node_ref}' (self-referencing is not allowed)"
            )
            next
          end

          if source_node_ref == "trigger"
            if !trigger.valid_param?(source_node_output)
              error(
                code: :nonexistent_trigger_param,
                key: "nodes.#{node_ref}.inputs.#{input}.path",
                value: input_config["path"],
                message: "trigger parameter '#{source_node_output}' does not exist"
              )
              next
            end
            node.connect_input(input, trigger.param(source_node_output))
          else
            if !nodes[source_node_ref]
              error(
                code: :nonexistent_source_node,
                key: "nodes.#{node_ref}.inputs.#{input}.path",
                value: source_node_ref,
                message: "node reference '#{source_node_ref}' does not exist in object 'nodes'"
              )
              next
            end

            if !nodes[source_node_ref].valid_output?(source_node_output)
              error(
                code: :nonexistent_source_node_output,
                key: "nodes.#{node_ref}.inputs.#{input}.path",
                value: input_config["path"],
                message: "output '#{source_node_output}' does not exist in node '#{nodes[source_node_ref].node_name}'"
              )
              next
            end
            node.connect_input(input, nodes[source_node_ref].output(source_node_output))
          end
        when "static"
          if !input_config.key?("value")
            error(
              code: :missing_source_value,
              key: "nodes.#{node_ref}.inputs.#{input}",
              message: "property 'value' is missing in object 'nodes.#{node_ref}.inputs.#{input}' (static source inputs must define a value)"
            )
            next
          end
          node.static_input(input, input_config["value"])
        else
          warning(
            code: :unknown_input_source,
            key: "nodes.#{node_ref}.inputs.#{input}.source",
            value: input_config["source"],
            message: "source '#{input_config["source"]}' in 'nodes.#{node_ref}.inputs.#{input}.source' is invalid (valid sources are 'static' and 'context')"
          )
          nil
        end
      end
    end
  end

  def errors? = errors.any?

  def warnings? = warnings.any?

  def error_messages = errors.map { |e| e[:message] }

  def warning_messages = warnings.map { |w| w[:message] }

  private

  def warning(code:, key:, value: nil, message: nil)
    warnings << { code:, key:, value:, message: }.compact
  end

  def error(code:, key:, value: nil, message: nil)
    errors << { code:, key:, value:, message: }.compact
  end

  def set_trigger(*params) = Trigger.new(*params)

  def add_node(node_name) = NodeBuilder.new(node_name, schema).add

  class Trigger
    attr_reader :params

    def initialize(params)
      @params = params
    end

    def param(param_name) = { node: "trigger", name: "trigger.#{param_name}" }

    def valid_param?(param_name) = params.include?(param_name)
  end

  class NodeBuilder
    attr_reader :node_name, :node_ref, :node_class, :schema
    def initialize(node_ref, schema)
      @node_ref = node_ref
      @node_class = Node.node_for(node_ref)
      @node_name = @node_class.node_name
      @schema = schema
    end

    def valid_output?(output_name) = node_class.valid_output?(output_name.to_sym)

    def add
      schema[node_ref] = {
        credentials: Hash[node_class.credentials.map { |i| [ i.to_s, nil ] }],
        inputs: Hash[node_class.inputs.keys.map { |i| [ i.to_s, { source: nil } ] }],
        outputs: node_class.outputs.keys.map(&:to_s),
        next: []
      }
      self
    end

    def set_initial(bool)
      schema[node_ref][:initial_node] = bool
      self
    end

    def connect_input(input_name, output)
      schema[node_ref][:inputs][input_name][:source] = "context"
      schema[node_ref][:inputs][input_name][:path] = output[:name]
      output[:node].add_next(self) unless output[:node] == "trigger"
      self
    end

    def static_input(input_name, value)
      schema[node_ref][:inputs][input_name][:source] = "static"
      schema[node_ref][:inputs][input_name][:value] = value
      self
    end

    def output(name) = { node: self, name: "#{node_ref}.outputs.#{name}" }

    def add_next(node)
      schema[node_ref][:next] << node.node_ref
      self
    end
  end
end
