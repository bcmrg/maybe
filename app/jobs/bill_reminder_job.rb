class BillReminderJob < ApplicationJob
  queue_as :high_priority

  def perform
    Family.find_each do |family|
      reminder_preference = family.reminder_preference
      next unless reminder_preference && reminder_preference.reminder_recipients.any?
      remind_days = reminder_preference.remind_days

      # Due reminders based on remind_days (do nothing if remind_days is empty or nil)
      if remind_days.present?
        family.bills.active.each do |bill|
          next unless bill.next_due_date
          days_until_due = (bill.next_due_date - Date.current).to_i
          if remind_days.include?(days_until_due)
            reminder_preference.reminder_recipients.each do |user|
              BillReminderMailer.due_reminder(
                user,
                bill,
                reminder_preference
              ).deliver_later
            end
          end
        end
      end

      # Reminders for overdue bills (only if send_overdue_reminders is true)
      if reminder_preference.send_overdue_reminders
        family.bills.active.overdue.each do |bill|
          reminder_preference.reminder_recipients.each do |user|
            BillReminderMailer.overdue_reminder(
              user,
              bill,
              reminder_preference
            ).deliver_later
          end
        end
      end
    end
  end
end