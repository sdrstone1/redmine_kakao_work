require 'redmine_kakao_work'

Redmine::Plugin.register :redmine_kakao_work do
  name 'Redmine Kakao Work plugin'
  author 'KollHong'
  description 'A Redmine plugin webhooks on creating and updating articles based on https://github.com/suer/redmine_webhook'
  version '0.0.5'
  url 'https://github.com/sdrstone1/redmine_kakao_work'
  author_url 'https://kollhong.com/'
  settings partial: 'settings/kakao_work/general'

  permission :manage_hook, {:webhook_settings => [:index, :show, :update, :create, :destroy]}, :require => :member
end
