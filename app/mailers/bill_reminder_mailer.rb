require 'ostruct'

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

  def test_due_reminder(user, reminder_preference)
    sample_bill = OpenStruct.new(
      name: "Sample Bill",
      next_due_date: 3.days.from_now.to_date,
      amount: 100.00,
      currency: "USD",
      account: OpenStruct.new(name: "Sample Checking Account")
    )
    @user = user
    @bill = sample_bill
    @reminder_preference = reminder_preference
    mail(
      to: @user.email,
      subject: "Upcoming Bill Due: #{@bill.name}",
      template_name: 'due_reminder'
    )
  end

  def test_overdue_reminder(user, reminder_preference)
    sample_bill = OpenStruct.new(
      name: "Sample Overdue Bill",
      next_due_date: 5.days.ago.to_date,
      amount: 200.00,
      currency: "USD",
      account: OpenStruct.new(name: "Sample Checking Account")
    )
    @user = user
    @bill = sample_bill
    @reminder_preference = reminder_preference
    mail(
      to: @user.email,
      subject: "Overdue Bill: #{@bill.name}",
      template_name: 'overdue_reminder'
    )
  end
end
