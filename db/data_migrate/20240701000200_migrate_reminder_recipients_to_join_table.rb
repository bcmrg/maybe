class MigrateReminderRecipientsToJoinTable < ActiveRecord::Migration[7.2]
  def up
    FamilyReminderPreference.reset_column_information
    FamilyReminderPreference.find_each do |preference|
      # Use the old column if it still exists (for migration safety)
      if preference.has_attribute?(:reminder_recipients)
        emails = preference[:reminder_recipients]
        next unless emails.present?
        emails.each do |email|
          user = preference.family.users.find_by(email: email)
          next unless user
          FamilyReminderPreferenceRecipient.create!(family_reminder_preference: preference, user: user)
        end
      end
    end
  end

  def down
    # No-op: cannot safely reverse
  end
end 