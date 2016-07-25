# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

RedmineApp::Application.routes.draw do
  resource :resource_reports, only: [:show] do
    resource :working_hours,        only: [:new, :create]
    resource :rework_resources,     only: [:new, :create]
    resource :release_calendar,     only: [:new, :create]
    resource :resource_provision,   only: [:new, :create]
    resource :forecast_perfomances, only: [:new, :create]
    resource :release_stats, only: [:new, :create]
  end

  resources :auto_estimations, only: [:create]

  resources :competences, except: [:delete, :show]
end
