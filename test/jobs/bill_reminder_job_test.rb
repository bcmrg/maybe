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
  end

  test "sends reminder for due soon bills" do
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
  end

  test "sends overdue reminder for overdue bills" do
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

  test "does not send reminders when no recipients are set" do
    @family.reminder_preference.reminder_recipients.clear
    assert_emails 0 do
      perform_enqueued_jobs do
        BillReminderJob.perform_now
      end
    end
  end

  test "does not send reminder when no overdue or due soon bills exist" do
    @bill.update!(next_due_date: 10.days.from_now)
    @family.reminder_preference.reminder_recipients << @user
    assert_emails 0 do
      perform_enqueued_jobs do
        BillReminderJob.perform_now
      end
    end
  end

  test "does not send reminder for paused bills" do
    @bill.update!(status: "paused", next_due_date: 3.days.from_now)
    @family.reminder_preference.reminder_recipients << @user
    assert_emails 0 do
      perform_enqueued_jobs { BillReminderJob.perform_now }
    end
  end

  test "sends reminder to multiple recipients" do
    @user = users(:family_admin)
    user2 = users(:family_member)
    @family.reminder_preference.reminder_recipients = [@user, user2]
    @bill.update!(next_due_date: 3.days.from_now)
    assert_emails 2 do
      perform_enqueued_jobs { BillReminderJob.perform_now }
    end
  end

  test "sends reminders only for due soon or overdue bills when multiple bills exist" do
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

  test "bill due today is considered due soon, not overdue" do
    @bill.update!(next_due_date: Date.current)
    @family.reminder_preference.reminder_recipients << @user
    assert_emails 1 do
      perform_enqueued_jobs { BillReminderJob.perform_now }
      email = ActionMailer::Base.deliveries.last
      assert_includes email.subject, @bill.name
      assert_includes email.subject.downcase, "due" # Should be a due soon subject, not overdue
    end
  end
end