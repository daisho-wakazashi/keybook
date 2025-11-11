class User < ApplicationRecord
  has_many :availabilities, dependent: :destroy
  enum :role, {
    property_manager: "property_manager",
    tenant: "tenant"
  }, prefix: true

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :role, presence: true

  def full_name
    "#{first_name} #{last_name}"
  end
end
