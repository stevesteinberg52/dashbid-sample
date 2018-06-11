      # require 'sidekiq-ent/web'

DbamApp::Application.routes.draw do
  mount UserImpersonate::Engine => "/impersonate", as: "impersonate_engine"
        # mount Sidekiq::Web => '/admin/sidekiq'

  root to: "dashboard#index"

  devise_for :users, controllers: { invitations: 'devise/invitations', sessions: 'users/sessions' }

  get 'workers/update_ad_source' => 'workers#update_ad_source', as: :update_ad_source

  get 'real_time', to: Metal::RealTimeController.action(:index)

  resources :placements, only: [:index] do
    member do
      post 'set_pp_name'
      get 'revenue_estimator'
    end
  end

  resources :reports, only: [] do
    collection do
      get 'placements_by_day'
      get 'account_by_day'
    end
  end

  resource :dashboard, controller: 'customer_dashboard' do
    collection do
      get 'index'
      get 'placements_by_day'
      get 'placements_by_rtb'
      get 'generate_placements_by_day_report'
      get 'account_by_day'
      get 'placements'
      get 'tags', to: 'customer_dashboard#placements'
    end
  end

  resource :demand_dashboard, controller: 'demand_dashboard' do
    collection do
      get 'index'
      get 'rtb_performance'
    end
  end

  # , path: '', constraints: { subdomain: "api" } # for forcing sub-domain and not having a second 'api' in the URL
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :sessions, only: :create

      resources :customers, only: [] do
        resources :tags, only: [:index] do
          member do
            get 'performance', to: 'performance#show'
          end
        end
      end
    end
    get '*unmatched_route', to: 'api#unmatched_route'
  end

  namespace :admin do
    resources :ad_source_comments
    resources :network_comments
    resources :placement_comments
    resources :customer_comments
    resources :ad_source_groups
    resources :fpf do
      get 'calculate_on_demand', on: :member
    end
    resources :queries do
      get :new_for_home_page, on: :collection
    end
    resources :rtb_network_pies do
      get :populate_table, on: :collection
    end

    resources :network_users, except: [:index] do
      get :network_list, on: :collection
      get :confirm, on: :member
      get :sign_in_info, on: :member
      get :invitation_info, on: :member
      get :versions, on: :collection
    end
    resources :customer_users, except: [:index] do
      get :customer_list, on: :collection
      get :confirm, on: :member
      get :sign_in_info, on: :member
      get :invitation_info, on: :member
      get :versions, on: :collection
    end
    resources :dashbid_users, except: [:index] do
      get :dashbid_list, on: :collection
      get :confirm, on: :member
      get :sign_in_info, on: :member
      get :invitation_info, on: :member
      get :versions, on: :collection
    end

    resources :home, only: [:index] do
      collection do
        get 'check_ad_source_no_fill'
        get 'clear_cookie'
        get 'customer_status'
        post 'customer_status'
        get 'explore_data'
        get 'network_status'
        get 'reports'
        get 'server_status'
        get 'whats_new'
        get 'deploys'
        get 'customers_from_account_contact'
        get 'real_time_test'
      end
    end

    # why 2x? [once above, once here]
    get 'clear_cookie'  => 'home#clear_cookie'
    get 'dbams/configs' => "dbams#configs" # Ugh awful for AJAX

    get 'td'                => 'td#index'
    get 'td/:table/schema'  => 'td#schema'
    get 'td/:table/tail/:n' => 'td#tail'

    get 'ad_source_hourly/base', to: 'ad_source_hourly#base'
    get 'ad_source_hourly/pivot', to: 'ad_source_hourly#pivot'

    get 'ad_source_hourly', to: 'ad_source_hourly#index'

    get 'placement_dashboard', to: 'placement_dashboard#index'

    get 'real_time', to: 'real_time#index'

    get 'td_api/templates',    to: 'td_api#templates'
    get 'td_api/download_csv', to: 'td_api#download_csv'
    post 'td_api/run',         to: 'td_api#run'
    post 'td_api/kill_job',    to: 'td_api#kill_job'

    resources :activity_logs, only: [:index] do
      collection do
        get 'activities'
        get 'activity_users'
        get 'activity_user_detail'
        get 'activity_detail'
      end
    end

    resources :ad_source_reconciliations do
      member do
        post "edit_int"
      end
    end

    resources :ad_sources do
      member do
        get 'copy'
        get 'network_data'
        get 'versions'
        get 'comments'
        get 'waterfalls'
        get 'bag_of_tags'
        post 'save_groups'
        get 'ad_source_groups'
      end
      collection do
        get 'ad_source_map2'
        get 'list'
        get 'list_assignments'
        get 'player_sizes'
      end
      resources :ad_source_reconciliations, only: ["index"]
    end

    resources :build_tests, only: [:show, :edit, :update, :destroy, :run, :run_parent] do
      member do
        get '_dbam'
        get 'dbam_script'
        get 'pass'
        get 'run'
        get 'run_parent'
        get 'unpass'
      end
    end

    resources :build_tests

    resources :countries do
      member do
        post :activate
        post :deactivate
      end
      collection do
        get 'list'
      end
    end

    resources :customers, constraints: { id: /[0-9]+/ } do
      collection do
        get 'hourly_check'
      end

      member do
        get 'checkout'
        get 'commits'
        get 'deploys'
        get 'history'
        get 'placements'
        get 'pull'
        get 'repo'
        get 'reset'
        get 'users'
        get 'versions'
        get 'comments'
      end

      resources :daily_revenues

      resources 'generate_text', controller: 'customer_generate_text', only: [:index] do
        collection do
          get 'export'
        end
      end

      resources 'margins', controller: 'customer_margins', only: [:index]
      resources 'placement_margins', controller: 'customer_placement_margins', only: [:show]

      ## TODO jb: use shallow in rails 4!
      resources :placements, except: [:show, :edit, :update, :destroy] do
      end

      resources 'td_ad_sources', controller: 'customer_td_ad_sources', only: [:index]
    end

    resources :customer_statements, only: [:index] do
      collection do
        get '/', to: 'customer_statements#all_months'
        get 'all_months'
        get 'month_by_day'
        get 'month_by_customer'
        get 'day_by_customer'
        get 'customer_month_by_day'
        get 'customer_day_by_placement'
      end
    end

    resources :customer_statement_dates, only: [:index] do
      collection do
        get 'all_months'
        get 'month_by_day'
        get 'billing_template'
        get 'generate_date'
        post 'generate_all_dates_by_month'
        get 'lock_date'
        get 'unlock_date'
        get 'unlock_dbif_date'
        get 'lock_dbif_date'
        get 'lock_all_dates'
        get 'lock_all_fpf_dates'
      end
    end

    resources :data_explorers do
      collection do
        get 'ad_source_hourly', to: redirect('/admin/ad_source_hourly')
        get 'ad_source_daily'
        get 'domain_hourly'
        get 'network'
        get 'network3'
        get 'network_pivot'
        get 'network_heat_map'
        get 'placements'
        get 'ad_sources'
        get 'server_performance_hourly'
        get 'waterfall_daily'
        get 'waterfall_hourly'
        get 'waterfall_hourly_to_csv'
      end
    end

    resources :data_sources

    resources :dbam_builds, only: [:show, :destroy]   do
      member do
        get 'build_waterfall'
        get 'dbam_commit'
        get 'git_file'
        get 'target_commit'
      end
      resources :build_tests, except: [:show, :edit, :update, :destroy]
      resources :deploys, except: [:show, :edit, :update, :destroy]
    end

    resources :dbams do
      member do
        get 'checkout'
        get 'placements'
        get 'pull'
        get 'reset'
      end
    end

    resources :definitions do
      collection do
        get 'list'
      end
    end

    resources :deploys, only: [:index, :show, :new, :create]

    resources :domains, only: [:index, :show] do
      collection do
        get 'list'
      end
    end

    get 'help', to: 'resources#index'

    resources :resources, only: [:index] do
      collection do
      end
    end


    resources :groups do
      collection do
        get 'add_placement'
      end
      member do
        get 'add_ad_source'
        get 'remove_placement'
        get 'edit_ad_source_group'
        get 'remove_ad_source'
      end
    end

    resources :health_check, only: [:index] do
      collection do
        get 'td_wf_events_job'
        get 'td_as_events_job'
      end
    end

    resources :hourly_margin_dates, only: [:index] do
      collection do
        get 'all_months'
        get 'month_by_day'
        get 'generate_day_data'
        get 'generate_month_data'
        post 'generate_selected_days_data'
        post 'generate_outdated_days_data'
      end
    end

    resources :infrastructure_fees, only: [:index] do
      collection do
        get 'all_months'
        get 'month_by_day'
        get 'generate_date'
        post 'generate_all_dates_by_month'
      end
    end

    resources :jobs, only: [:index] do
      collection do
        get 'purge_td_domain_referrers'
        post 'purge_td_domain_referrers_do'
        get 'purge_td_domain_http_referers'
        post 'purge_td_domain_http_referers_do'
        get 'derive_margin_data'
        post 'derive_margin_data_do'
        get 'mysql_processes'
        get 'kill_mysql_process'
        get 'explain_mysql_process'
        get :not_used_lists
        post :delete_not_used_lists
        get :delete_all_not_used_lists
        get :delete_checked_unused_lists
        get :import_pixalate_ip_list
        post :import_pixalate_ip_list_post
      end
    end

    resources :list_assignment_groups, except: [:destroy] do
      collection do
        get 'add_list_assignment'
        get 'remove_list_assignment'
      end
      member do
        get 'versions'
      end
    end

    resources :list_assignments, except: [:destroy] do
      collection do
        get 'export_memcache'
      end
      member do
        get 'versions'
      end
    end

    resources :list_builds, only: [:index, :show] do
      member do
         post 'reset_ready'
      end
      collection do
        get 'list'
        post 'build_deploy_do'
      end
    end

    resources :lists, except: [:destroy] do
      collection do
        get 'menu'
        get 'compare'
        get 'compare_export_csv'
        get :td_list_empty_vast
        post :import_td_list_empty_vast
        get :pixalate_ips
        get :import_pixalate_list
        post :import_pixalate_list_post
      end
      member do
        get 'domains'
        post 'delete_domains'
        get 'import_file'
        post 'upload_file_create'
        get 'import_uploaded_file'
        get 'bulk_import_uploaded_file'
        get 'remove_uploaded_file'
        get 'import_list'
        post 'import_list_do'
        get 'delete_list'
        post 'delete_list_do'
        get 'import_text'
        post 'import_text_do'
        get 'events'
        get 'export_csv'
        get 'belongs_to'
        get 'add_belongs_to'
        get 'remove_belongs_to'
        get 'versions'
      end
    end

    resources :margin_report, only: [:index] do
      collection do
        get 'excel'
      end
    end

    resources :margin_report_beta, only: [:index] do
      collection do
        get 'excel'
      end
    end

    resources :mobile, only: [:index]

    resources :customer_domain_report, only: [:index, :show, :create] do
      collection do
        post 'generate'
      end
    end

    resources :margin_report_hourly, only: [:index] do
      collection do
        get 'excel'
      end
    end

    resources :network_data_parsers, constraints: {id: /[0-9]+/} do
      collection do
        get 'new_from_file'
        post 'build'
      end
    end

    resources :network_data do
      collection do
        post 'parse'
        get 'status'
        get 'reconcile'
        get 'upload'
      end
    end

    resources :network_reconciliations do
      collection do
        post 'clean_all'
        get 'missing'
      end

      member do
        get 'reconcile'
        post 'activate'
        post 'clean'
        post 'deactivate'
        post 'make_ready'
        post 'make_unready'
      end
    end

    resources :network_revenue_daily, only: [:index]

    resources :network_revenues, only: [:index] do
      collection do
        get 'by_month'
        get 'by_year'
      end
    end

    resources :networks do
      member do
        get 'ad_sources'
        get 'network_data_matrix'
        get 'reconciliation_matrix'
        get 'reconciliation_trend'
        get 'versions'
        get 'comments'
        get 'notes'
      end
    end

    resources :notifications, except: [:edit, :update]  do
      collection do
        get 'inbox'
        get 'inbox_archive'
        get 'sent'
        get 'sent_archive'

        post 'archive_inbox'
        post 'restore_archive'
        post 'archive_sent'
      end
      member do
        get 'compose'
        get 'view_sent'
      end
    end

    resources :pivot do
      collection do
        get 'network'
        get 'waterfall'
        get 'margin_by_date'
      end
    end

    resources :pixalate

    resources :placements, only: [:index, :show, :edit, :update, :destroy] do
      member do
        get '_test_pages'
        get 'ad_tags'
        get 'dbam_builds'
        get 'dbam_events'
        get 'customer_comments'
        get 'hourly_revenue_estimator'
        get 'show_next_vast'
        post 'status_update'
        get 'traffic'
        get 'view_file'
        get 'write_dbam_map'
        post 'remove_ad_sources_from_waterfall'
        post 'remove_ad_sources_from_bag_of_tags'
        get 'heat_map_test'
        get 'versions'
        get 'vast_packet_inspector'
        post 'parse_vast_packet'
        get 'placement_groups'
        get  'comments'
        post 'save_groups'
      end

      collection do
        get 'placement_map'
        get 'select_vpaid_file'
      end

      resources :dbam_builds, except: [:show, :edit, :update, :destroy]
      resources :test_pages, except: [:show, :edit, :update, :destroy]

      resources :wopr, except: [:show, :edit, :update, :destroy]  do
        collection do
          get 'results'
          get 'fixed_eval'
          post 'fixed_eval'
          post 'optimize'
        end
      end
    end

    resources :vpaids, except: [:show]

    resources :placement_groups, only: [:index]

    resources :read_replica do
      collection do
        get 'mysql_processes'
        get 'kill_mysql_process'
        post 'explain_mysql_process'
      end
    end

    resources :report_types

    resources :saved_reports

    resources :secrets, only: [:index] do
      collection do
        get '/', to: 'secrets#index'
        get 'customer_cache'
        get 'td_ad_source_id_fix'
        get 'td_ad_source_id_monthly_status'
        get 'td_ad_source_id_sample_missing'
      end
    end

    resources :tableau, only: [:index] do
      collection do
        post 'report'
      end
    end

    resources :td_domain_dailies, only: [:index] do
      collection do
        get 'excel'
      end
    end

    resources :td_templates do
      collection do
        get 'manage'
        post 'manage'
      end

      member do
        post 'run'
      end
    end

    resources :domain_referrers, only: [:index] do
      collection do
        get 'generate'
      end
    end

    resources :domain_http_referers, only: [:index] do
      collection do
        get 'generate'
      end
    end

    resources :test_events

    resources :test_pages, only: [:show, :edit, :update, :destroy] do
      member do
        get 'copy'
      end
    end

    resources :uploads

    resources :users do
      member do
        get 'confirm'
        get 'invitation_info'
        get 'sign_in_info'
        get 'versions'
        post 'unlock'
      end
    end

    resources :user_roles, only: [:index, :edit, :update]

    resources :waterfall_reports, only: [:index] do
      collection do
        get '/', to: 'waterfall_reports#index'
        get 'by_hour'
        get 'by_hour_mobile'
        get 'by_day'
        get 'by_month'
        get 'by_placements'
        get 'by_placements_to_csv'

        # delete soon
        get 'customer_by_day', action: :by_date
        get 'day_by_hour', action: :by_hour
      end
    end

    resources :waterfall_comments, except: [:index]
  end

  # customers/placements ...
  resources :customers do
    member do
    end
    resources :placements, only: [] do
      collection do
      end
      member do
      end
    end
  end

  get '*unmatched_route', to: 'application#log_and_render_template'
end
