class Booking < ApplicationRecord
  belongs_to :booker, class_name: "User"
  belongs_to :availability

  validates :availability_id, uniqueness: true
  validate :booker_must_be_tenant

  private

  def booker_must_be_tenant
    return unless booker

    unless booker.role_tenant?
      errors.add(:booker, "must be a tenant")
    end
  end
end
