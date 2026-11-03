class DocsProject
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :name, :string
  attribute :email, :string
  attribute :public, :boolean, default: true

  validates :name, presence: true

  def self.invalid_example
    new(email: "team@example.com").tap(&:validate)
  end
end
