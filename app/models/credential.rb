class Credential < ApplicationRecord
  serialize :data, type: Hash, coder: JSON
  encrypts :data
end
