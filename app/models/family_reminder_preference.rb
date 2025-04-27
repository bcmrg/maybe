class FamilyReminderPreference < ApplicationRecord
  belongs_to :family

  validates :family_id, presence: true
  validates :digest_frequency, inclusion: { in: %w[individual daily weekly] }
  
  # Ensure arrays are never nil
  before_validation :ensure_arrays_present

  private

  def ensure_arrays_present
    self.remind_days ||= []
    self.reminder_recipients ||= []
  end
end 