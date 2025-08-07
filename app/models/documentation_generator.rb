# In development, classes are lazy loaded which prevent use `Class#descendants` method
Dir.glob(File.join(Rails.root, "app", "models", "nodes", "**", "*.rb"), &method(:require))

class DocumentationGenerator
  def self.generate
    Node.descendants.map do |node_class|
      doc = ""
      doc << "`#{node_class.node_name}`:\n"
      doc << "* Description: #{node_class.description}\n"
      doc << "* Inputs:\n"
      node_class.inputs.each do |input, config|
        doc << " - `#{input}`: #{config[:description]}\n"
      end
      doc << "* Outputs:\n"
      node_class.outputs.each do |output, config|
        doc << " - `#{output}`: #{config[:description]}\n"
      end
      doc
    end.join("\n--\n\n")
  end
end
