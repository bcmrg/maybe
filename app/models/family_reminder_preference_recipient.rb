class FamilyReminderPreferenceRecipient < ApplicationRecord
  belongs_to :family_reminder_preference
  belongs_to :user

  validates :user_id, uniqueness: { scope: :family_reminder_preference_id }
  validate :user_belongs_to_family

  private

  def user_belongs_to_family
    unless user&.family_id == family_reminder_preference&.family_id
      errors.add(:user, "must belong to the same family")
    end
  end
end 