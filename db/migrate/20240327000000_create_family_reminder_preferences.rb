class CreateFamilyReminderPreferences < ActiveRecord::Migration[7.2]
  def change
    create_table :family_reminder_preferences do |t|
      t.references :family, null: false, foreign_key: true, type: :uuid
      t.integer :remind_days, array: true, default: [7, 3, 1]
      t.boolean :send_overdue_reminders, default: true
      t.string :digest_frequency, default: 'individual'
      t.string :reminder_recipients, array: true, default: []

      t.timestamps
    end

    # Add index for faster lookups
    add_index :family_reminder_preferences, [:family_id, :remind_days], name: 'index_reminder_prefs_on_family_and_days'
  end
end 