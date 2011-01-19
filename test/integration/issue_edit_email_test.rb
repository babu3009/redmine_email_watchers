require 'test_helper'

class IssueEditEmailTest < ActionController::IntegrationTest
  should "show include email watchers in an issue edit email" do
    Setting.notified_events = ['issue_updated']
    Setting.bcc_recipients = '0'
    ActionMailer::Base.deliveries.clear
    
    generate_user_as_project_manager

    login_as
    visit_issue_page(@issue)

    fill_in('Add email watcher', :with => 'add-new@example.com')
    click_button('Add')
    assert_response :success

    assert_difference('Journal.count') do
      fill_in('notes', :with => 'An issue note to trigger an email')
      click_button('Submit')
      assert_response :success
    end

    assert_equal 1, ActionMailer::Base.deliveries.size
    mail = ActionMailer::Base.deliveries.last
    assert mail.cc.include?('add-new@example.com')
  end
end
