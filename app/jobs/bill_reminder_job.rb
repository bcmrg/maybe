class BillReminderJob < ApplicationJob
  queue_as :high_priority

  def perform
    Family.find_each do |family|
      next unless family.reminder_preference&.reminder_recipients.present?

      family.bills.active.due_soon.each do |bill|
        next if bill.paid_for_period?

        family.reminder_preference.reminder_recipients.each do |recipient|
          BillReminderMailer.due_reminder(
            recipient,
            bill,
            family.reminder_preference
          ).deliver_later
        end
      end
    end
  end
end