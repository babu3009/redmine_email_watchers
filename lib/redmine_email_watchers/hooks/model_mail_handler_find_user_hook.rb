module RedmineEmailWatchers
  module Hooks
    class ModelMailHandlerFindUserHook < Redmine::Hook::ViewListener
      def model_mail_handler_find_user(context={})

        if context[:user].nil? && context[:sender_email].present? && context[:email].in_reply_to.present?
          sender = context[:sender_email]

          # Duplicate from MailHandler because it's private...
          # -- In-Reply-To: <redmine.issue-100.....>
          issue_match = context[:email].in_reply_to.first.match(%r{^<redmine\.([a-z0-9_]+)\-(\d+)\.\d+@})
          if issue_match && issue_match[1] == 'issue'
            issue_id = issue_match[2]

            # Scan through watchers looking for matching email_watchers
            # TODO: since this is serialized, it will catch a bunch of records
            watcher = Watcher.first(:conditions =>
                                    ['email_watchers IS NOT NULL AND user_id IN (:user) AND watchable_type = "Issue" AND watchable_id IN (:issue_id)',
                                     {
                                       :user => EmailWatcherUser.default.id,
                                       :issue_id => issue_id
                                     }])

            if watcher && watcher.email_watchers.include?(sender)
              # Email watcher is valid
              user = EmailWatcherUser.default
              # Store the project on the user object
              user.instance_variable_set('@project_id', Issue.find(issue_id).project_id.to_i)
              
              # Mock out allowed_to? for this project only to edit issues
              def user.allowed_to?(permission, project)
                permission == :edit_issues && project.id.to_i == instance_variable_get('@project_id')
              end
              
              return user
            end
          end
          
        end
        
        return []
      end
    end
  end
end
