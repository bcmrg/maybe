# Preview all emails at http://localhost:3000/rails/mailers/bill_reminder_mailer
class BillReminderMailerPreview < ActionMailer::Preview
  def test_reminder
    user = Current.user || User.first
    reminder_preference = user.family.reminder_preference
    BillReminderMailer.test_reminder(user, reminder_preference)
  end

  def due_reminder
    user = Current.user || User.first
    bill = user.family.bills.first
    reminder_preference = user.family.reminder_preference
    BillReminderMailer.due_reminder(user, bill, reminder_preference)
  end

  def overdue_reminder
    user = Current.user || User.first
    bill = user.family.bills.first
    reminder_preference = user.family.reminder_preference
    BillReminderMailer.overdue_reminder(user, bill, reminder_preference)
  end
end
