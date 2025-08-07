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
        doc << "    * Required: #{!config[:default]}\n"
        doc << "    * Default: #{config[:default]}\n" if config[:default]
      end
      doc << "* Outputs:\n"
      node_class.outputs.each do |output, config|
        doc << "  - `#{output}`:\n"
        doc << "    * Description: #{config[:description]}\n"
      end
      doc
    end.join("\n--\n\n")
  end
end
