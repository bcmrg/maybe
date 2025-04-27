class BillReminderMailer < ApplicationMailer
  def test_reminder(user, reminder_preference)
    @user = user
    @reminder_preference = reminder_preference
    mail(to: @user.email, subject: "This is your test bill reminder email")
  end

  def due_reminder(user, bill, reminder_preference)
    @user = user
    @bill = bill
    @reminder_preference = reminder_preference
    mail(to: @user.email, subject: "Upcoming Bill Due: #{@bill.name}")
  end

  def overdue_reminder(user, bill, reminder_preference)
    @user = user
    @bill = bill
    @reminder_preference = reminder_preference
    mail(to: @user.email, subject: "Overdue Bill: #{@bill.name}")
  end
end
