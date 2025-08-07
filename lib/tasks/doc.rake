namespace :doc do
  desc "Generate the documentation for all nodes in `app/models/nodes`"
  task generate: :environment do
    # In development, classes are lazy loaded which prevent use `Class#descendants` method
    Dir.glob(File.join(Rails.root, "app", "models", "nodes", "**", "*.rb"), &method(:require))

    doc_string = DocumentationGenerator.generate
    FileUtils.mkdir_p "documentation"
    File.open("documentation/nodes.md", "w+") { |f| f.write(doc_string)  }
    puts "generated `documentation/nodes.md`"
  end
end
