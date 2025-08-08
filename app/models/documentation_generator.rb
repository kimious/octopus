class DocumentationGenerator
  def self.generate
    Node.descendants.map do |node_class|
      doc = ""
      doc << "`#{node_class.node_name}`:\n"
      doc << "* Description: #{node_class.description}\n"
      doc << "* Inputs:\n"
      node_class.inputs.each do |input, config|
        doc << "  - `#{input}`:\n"
        doc << "    * Description: #{config[:description]}\n"
        if config[:type]
          doc << "    * Type: #{type_info(config[:type])}\n"
        elsif config[:enum]
          doc << "    * Type: Enum { #{config[:enum].join(", ")} }\n"
        end
        doc << "    * Required: #{!config[:default]}\n"
        doc << "    * Default: #{config[:default]}\n" if config[:default]
      end
      doc << "* Outputs:\n"
      node_class.outputs.each do |output, config|
        doc << "  - `#{output}`:\n"
        doc << "    * Description: #{config[:description]}\n"
        if config[:type]
          doc << "    * Type: #{type_info(config[:type])}\n"
        elsif config[:enum]
          doc << "    * Type: Enum { #{config[:enum].join(", ")} }\n"
        end
      end
      doc
    end.join("\n--\n\n")
  end

  def self.type_info(type)
    if type.is_a?(Array)
      "Array<#{type_info(type[0])}>"
    elsif type.is_a?(Hash)
      info = "{ "
      info << type.map do |key, key_type|
        "#{key}: #{type_info(key_type)}"
      end.join(", ")
      info << " }"
      info
    elsif type.in?([ String, Integer, Float, Boolean, DateTime, Hash ])
      type.to_s
    end
  end
end
