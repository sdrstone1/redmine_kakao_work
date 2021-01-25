module RedmineWebhook
  class WebhookListener < Redmine::Hook::Listener

    def skip_webhooks(context)
      return true unless context[:request]
      return true if context[:request].headers['X-Skip-Webhooks']

      false
    end

    def controller_issues_new_after_save(context = {})
      return if skip_webhooks(context)
      issue = context[:issue]
      controller = context[:controller]
      project = issue.project
      webhooks = Webhook.where(:project_id => project.project.id)
      webhooks = Webhook.where(:project_id => 0) unless webhooks && webhooks.length > 0
      return unless webhooks
      post(webhooks, issue_to_json(issue, controller))
    end

    def controller_issues_edit_after_save(context = {})
      return if skip_webhooks(context)
      journal = context[:journal]
      controller = context[:controller]
      issue = context[:issue]
      project = issue.project
      webhooks = Webhook.where(:project_id => project.project.id)
      webhooks = Webhook.where(:project_id => 0) unless webhooks && webhooks.length > 0
      return unless webhooks
      post(webhooks, journal_to_json(issue, journal, controller))
    end

    def controller_issues_bulk_edit_after_save(context = {})
      return if skip_webhooks(context)
      journal = context[:journal]
      controller = context[:controller]
      issue = context[:issue]
      project = issue.project
      webhooks = Webhook.where(:project_id => project.project.id)
      webhooks = Webhook.where(:project_id => 0) unless webhooks && webhooks.length > 0
      return unless webhooks
      post(webhooks, journal_to_json(issue, journal, controller))
    end
    
    def controller_wiki_edit_after_save(context = {})
      return if skip_webhooks(context)
      page = context[:page]
      controller = context[:controller]
      project = context[:project]
      params = context[:params]
      webhooks = Webhook.where(:project_id => project.id)
      webhooks = Webhook.where(:project_id => 0) unless webhooks && webhooks.length > 0
      return unless webhooks
      post(webhooks, wiki_to_json(page, controller, project, params))
    end

    def model_changeset_scan_commit_for_issue_ids_pre_issue_update(context = {})
      issue = context[:issue]
      journal = issue.current_journal
      webhooks = Webhook.where(:project_id => issue.project.project.id)
      webhooks = Webhook.where(:project_id => 0) unless webhooks && webhooks.length > 0
      return unless webhooks
      post(webhooks, journal_to_json(issue, journal, nil))
    end

    private
    def issue_to_json(issue, controller)
      {
        :payload => {
          :action => 'opened',
          :issue => RedmineWebhook::IssueWrapper.new(issue).to_hash,
          :url => controller.issue_url(issue)
        }
      }.to_json
    end

    def journal_to_json(issue, journal, controller)
      {
        :payload => {
          :action => 'updated',
          :issue => RedmineWebhook::IssueWrapper.new(issue).to_hash,
          :journal => RedmineWebhook::JournalWrapper.new(journal).to_hash,
          :url => controller.nil? ? 'not yet implemented' : controller.issue_url(issue)
        }
      }.to_json
    end

    def wiki_to_json(page, controller, project, params)
      content = params[:content]
      text = content[:text]
      comments = content[:comments]
      {
        :text => "Wiki #{controller.action_name} : #{project}",
        :datas => [
          { 
            :type => "section",
            :data => {
              :content => "### 위키 페이지 #{controller.action_name}\r\n\r\n" +
              "#### 프로젝트 #{project}의 #{page.title}\r\n" +
              "**한줄설명** : #{comments}\r\n",
              :type => "markdown"
            }
          },
          { 
            :type => "section",
            :data => {
              :content => "#{text}",
              :type => "markdown"
            }
          }
        ]
      }.to_json
        # page.attributes = {
        #   "wiki_id"=>1,
        #   "protected"=>false,
        #   "parent_id"=>2,
        #   "id"=>3,
        #   "title"=>"Third",
        #   "created_on"=>Wed, 20 Jan 2021 05:40:08 UTC +00:00
        # }
        # page.new_record = bool 
              
        # controller.action_name = update
        # controller.params = {
        #   "utf8"=>"✓",
        #   "_method"=>"put",
        #   "authenticity_token"=>"#",
        #   "content"=><ActionController::Parameters {
        #     "version"=>"1",
        #     "text"=>"# Third\r\n\r\nwiki",
        #     "comments"=>""
        #   } permitted: false>,
        #   "wiki_page"=><ActionController::Parameters {
        #     "parent_id"=>"2"
        #   } permitted: false>,
        #   "commit"=>"Save",
        #   "controller"=>"wiki",
        #   "action"=>"update",
        #   "project_id"=>"test-project",
        #   "id"=>"Third"
        # }
        # project = title
        # project.attributes = {
        #   "id"=>1,
        #   "name"=>"test project",
        #   "description"=>"",
        #   "homepage"=>"",
        #   "is_public"=>true,
        #   "parent_id"=>nil,
        #   "created_on"=>Thu, 14 Jan 2021 07:25:46 UTC +00:00,
        #   "updated_on"=>Thu, 14 Jan 2021 07:25:46 UTC +00:00,
        #   "identifier"=>"test-project",
        #   "status"=>1,
        #   "lft"=>1,
        #   "rgt"=>2,
        #   "inherit_members"=>false,
        #   "default_version_id"=>nil,
        #   "default_assigned_to_id"=>nil
        # }
    end

    def post(webhooks, request_body)
      Thread.start do
        webhooks.each do |webhook|
          begin
            Faraday.post do |req|
              req.url webhook.url
              req.headers['Content-Type'] = 'application/json'
              req.body = request_body
            end
          rescue => e
            Rails.logger.error e
          end
        end
      end
    end
  end
end
