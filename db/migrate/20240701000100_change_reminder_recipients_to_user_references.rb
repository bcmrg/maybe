class ChangeReminderRecipientsToUserReferences < ActiveRecord::Migration[7.2]
  def change
    create_table :family_reminder_preference_recipients do |t|
      t.references :family_reminder_preference, null: false, foreign_key: true, index: { name: 'index_frp_recipients_on_frp_id' }
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.timestamps
    end

    add_index :family_reminder_preference_recipients, [:family_reminder_preference_id, :user_id], unique: true, name: 'index_frp_recipients_on_frp_and_user'

    remove_column :family_reminder_preferences, :reminder_recipients, :string, array: true
  end
end 