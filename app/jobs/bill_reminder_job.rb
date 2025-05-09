class BillReminderJob < ApplicationJob
  queue_as :high_priority

  def perform
    Family.find_each do |family|
      reminder_preference = family.reminder_preference
      next unless reminder_preference && reminder_preference.reminder_recipients.any?

      # Reminders for due soon bills
      family.bills.active.due_soon.each do |bill|
        next if bill.paid_for_period?
        reminder_preference.reminder_recipients.each do |user|
          BillReminderMailer.due_reminder(
            user,
            bill,
            reminder_preference
          ).deliver_later
        end
      end

      # Reminders for overdue bills
      family.bills.active.overdue.each do |bill|
        next if bill.paid_for_period?
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