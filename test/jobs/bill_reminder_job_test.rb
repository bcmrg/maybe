require "test_helper"

class BillReminderJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  def setup
    @family = families(:dylan_family)
    @user = @family.users.first
    @family.create_reminder_preference!(reminder_recipients: []) unless @family.reminder_preference
    @bill = @family.bills.create!(
      name: "Test Bill",
      amount: 100,
      currency: "USD",
      frequency: "monthly",
      start_date: Date.current,
      next_due_date: Date.current # Will be set in each test
    )
    @default_remind_days = [7, 3, 1, 0]
  end

  test "sends reminder only when days_until_due matches remind_days" do
    @family.reminder_preference.update!(remind_days: @default_remind_days)
    @bill.update!(next_due_date: 3.days.from_now)
    @family.reminder_preference.reminder_recipients << @user
    assert_emails 1 do
      perform_enqueued_jobs do
        BillReminderJob.perform_now
        email = ActionMailer::Base.deliveries.last
        assert_equal [@user.email], email.to
        assert_includes email.text_part.body.to_s, @bill.name
      end
    end
    # Now set to a day not in remind_days
    @bill.update!(next_due_date: 5.days.from_now)
    assert_emails 0 do
      perform_enqueued_jobs { BillReminderJob.perform_now }
    end
  end

  test "does not send reminder if days_until_due is not in remind_days" do
    @family.reminder_preference.update!(remind_days: @default_remind_days)
    @bill.update!(next_due_date: 4.days.from_now)
    @family.reminder_preference.reminder_recipients << @user
    assert_emails 0 do
      perform_enqueued_jobs { BillReminderJob.perform_now }
    end
  end

  test "does not send due soon reminders if remind_days is empty or nil" do
    @family.reminder_preference.update!(remind_days: nil)
    @bill.update!(next_due_date: 7.days.from_now)
    @family.reminder_preference.reminder_recipients << @user
    assert_emails 0 do
      perform_enqueued_jobs { BillReminderJob.perform_now }
    end
    @family.reminder_preference.update!(remind_days: [])
    @bill.update!(next_due_date: 1.day.from_now)
    assert_emails 0 do
      perform_enqueued_jobs { BillReminderJob.perform_now }
    end
  end

  test "sends overdue reminder for overdue bills if flag is true" do
    @family.reminder_preference.update!(send_overdue_reminders: true)
    @bill.update!(next_due_date: 2.days.ago)
    @family.reminder_preference.reminder_recipients << @user
    assert_emails 1 do
      perform_enqueued_jobs do
        BillReminderJob.perform_now
        email = ActionMailer::Base.deliveries.last
        assert_equal [@user.email], email.to
        assert_includes email.text_part.body.to_s, @bill.name
      end
    end
  end

  test "does not send overdue reminder if send_overdue_reminders is false" do
    @family.reminder_preference.update!(send_overdue_reminders: false)
    @bill.update!(next_due_date: 2.days.ago)
    @family.reminder_preference.reminder_recipients << @user
    assert_emails 0 do
      perform_enqueued_jobs { BillReminderJob.perform_now }
    end
  end

  test "does not send reminders when no recipients are set" do
    @family.reminder_preference.update!(remind_days: @default_remind_days)
    @family.reminder_preference.reminder_recipients.clear
    @bill.update!(next_due_date: 3.days.from_now)
    assert_emails 0 do
      perform_enqueued_jobs do
        BillReminderJob.perform_now
      end
    end
  end

  test "does not send reminder when no due bills exist for remind_days" do
    @family.reminder_preference.update!(remind_days: @default_remind_days)
    @bill.update!(next_due_date: 10.days.from_now)
    @family.reminder_preference.reminder_recipients << @user
    assert_emails 0 do
      perform_enqueued_jobs do
        BillReminderJob.perform_now
      end
    end
  end

  test "does not send reminder for paused bills" do
    @family.reminder_preference.update!(remind_days: @default_remind_days)
    @bill.update!(status: "paused", next_due_date: 3.days.from_now)
    @family.reminder_preference.reminder_recipients << @user
    assert_emails 0 do
      perform_enqueued_jobs { BillReminderJob.perform_now }
    end
  end

  test "sends reminder to multiple recipients" do
    @family.reminder_preference.update!(remind_days: @default_remind_days)
    @user = users(:family_admin)
    user2 = users(:family_member)
    @family.reminder_preference.reminder_recipients = [@user, user2]
    @bill.update!(next_due_date: 3.days.from_now)
    assert_emails 2 do
      perform_enqueued_jobs { BillReminderJob.perform_now }
    end
  end

  test "sends reminders only for bills matching remind_days when multiple bills exist" do
    @family.reminder_preference.update!(remind_days: @default_remind_days)
    @bill.update!(next_due_date: 3.days.from_now)
    other_bill = @family.bills.create!(
      name: "Future Bill",
      amount: 50,
      currency: "USD",
      frequency: "monthly",
      start_date: Date.current,
      next_due_date: 15.days.from_now
    )
    @family.reminder_preference.reminder_recipients << @user
    assert_emails 1 do
      perform_enqueued_jobs { BillReminderJob.perform_now }
    end
  end

  test "bill due today is considered for remind_days 0" do
    @family.reminder_preference.update!(remind_days: @default_remind_days)
    @bill.update!(next_due_date: Date.current)
    @family.reminder_preference.reminder_recipients << @user
    assert_emails 1 do
      perform_enqueued_jobs { BillReminderJob.perform_now }
      email = ActionMailer::Base.deliveries.last
      assert_includes email.subject, @bill.name
      assert_includes email.subject.downcase, "due"
    end
  end
end