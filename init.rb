require_dependency 'redmine_kakao_work'

Rails.configuration.to_prepare do
  unless ProjectsHelper.included_modules.include? RedmineWebhook::ProjectsHelperPatch
    ProjectsHelper.send(:include, RedmineWebhook::ProjectsHelperPatch)
  end
end

Redmine::Plugin.register :redmine_kakao_work do
  name 'Redmine Kakao Work plugin'
  author 'KollHong'
  description 'A Redmine plugin webhooks on creating and updating articles based on https://github.com/suer/redmine_webhook'
  version '0.0.2'
  url 'https://github.com/sdrstone1/redmine_kakao_work'
  author_url 'https://kollhong.com/'
  settings :default => { 'app_key' => " " },
    partial: 'settings/kakao_work/general'

  permission :manage_hook, {:webhook_settings => [:show,:update,:create, :destroy]}, :require => :member
end
