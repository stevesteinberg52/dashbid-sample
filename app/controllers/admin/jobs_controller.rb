class Admin::JobsController < AdminController
  layout "admin"

  before_filter :authorize_for_job!
  before_action :not_used_lists, only: [:delete_all_not_used_lists]

  def index
  end

  def purge_td_domain_referrer_http_referrers
    @max_date = TdDomainDaily.maximum(:dd)
    @min_date = TdDomainDaily.minimum(:dd)
    @purge_date = @max_date - 10.days
  end

  def purge_td_domain_dailies_do
    if params[:purge_date]
      PurgeTdDomainDailiesProcessGenerateWorker.perform_async(params[:purge_date])
      flash[:notice] = 'Purge process set to run as a background job.'
    else
      flash[:alert] = 'No purge date provided.'
    end
    redirect_to purge_td_domain_dailies_admin_jobs_path
  end

  def purge_td_domain_referrers
    @max_date = TdDomainReferrer.maximum(:dd) || Date.today
    @min_date = TdDomainReferrer.minimum(:dd) || Date.today
    @purge_date = @max_date - 10.days
  end

  def purge_td_domain_referrers_do
    if params[:purge_date]
      PurgeTdDomainReferrersProcessGenerateWorker.perform_async(params[:purge_date])
      flash[:notice] = 'Purge process set to run as a background job.'
    else
      flash[:alert] = 'No purge date provided.'
    end
    redirect_to purge_td_domain_referrers_admin_jobs_path
  end

  def purge_td_domain_http_referers
    @max_date = TdDomainHttpReferer.maximum(:dd) || Date.today
    @min_date = TdDomainHttpReferer.minimum(:dd) || Date.today
    @purge_date = @max_date - 10.days
  end

  def purge_td_domain_http_referers_do
    if params[:purge_date]
      PurgeTdDomainReferrerHttpReferersProcessGenerateWorker.perform_async(params[:purge_date])
      flash[:notice] = 'Purge process set to run as a background job.'
    else
      flash[:alert] = 'No purge date provided.'
    end
    redirect_to purge_td_domain_http_referers_admin_jobs_path
  end

  def derive_margin_data_do
    # DeriveMarginDataProcessGenerateWorker.perform_async
    MarginByDateTableGenerator.regenerate

    flash[:notice] = 'Process set to run as a background job.'
    redirect_to derive_margin_data_admin_jobs_path
  end

  def mysql_processes
    # SELECT id, db, command, user, info
    # FROM information_schema.processlist
    # WHERE db='dbamapp'
    # AND command='Query'
    # AND user='admin'
    # AND info LIKE 'SELECT %'
    # AND time >= 120

    processlist_sql = "
      SELECT id, user, db, command, time, state, info
        FROM information_schema.processlist
        WHERE command='Query' AND info NOT LIKE '%action:mysql_processes%';
      "

    @processes = ActiveRecord::Base.connection.execute(processlist_sql)
  end

  def kill_mysql_process
    process_id = params[:process_id]
    kill_sql = "KILL #{process_id};"

    begin
      @processes = ActiveRecord::Base.connection.execute(kill_sql)
    rescue => error
      puts error.inspect
    end

    redirect_to mysql_processes_admin_jobs_path
  end

  def explain_mysql_process
    @sql = params[:sql] || ''
    @execute = "EXPLAIN #{@sql}"

    begin
      @explanation = ActiveRecord::Base.connection.execute(@execute)
    rescue => error
      @explanation = "There was an error in the sql."
    end
  end

  def import_pixalate_ip_list
    require 'net/ftp'
    username = 'dashbid'
    password = 'DbiddhB01_pixalateFtp'

    ftp = Net::FTP.new('ftp.pixalate.com')
    ftp.login(username, password)
    ftp.chdir('ipblocklist')
    @files = ftp.list.map { |file| file.match(/\w+.csv/)[0] }.reverse

    @existing_dates = PixalateIp.select(:file_date).group(:file_date).order(:file_date).reverse_order
  end

  def import_pixalate_ip_list_post
    if params[:file_name] && !params[:file_name].empty?

      cc = "dan.gardiner@dashbid.com,steve@dashbid.com"

      options = { file_name: params[:file_name], email: current_user.email, cc: cc }

      PixalateIpBlacklistWorker.perform_async(options)

      flash[:notice] = "#{params[:file_name]} being imported in a background process"
    else
      flash[:alert] = "Select a file."
    end

    redirect_to import_pixalate_ip_list_admin_jobs_path
  end

  def not_used_lists
    @rejected = ListAssignment.where('list_id IS NOT NULL').pluck(:list_id).uniq
    @lists = List.select([:id, :updated_at, :list_name, :count_of_domains, :notes, :archived]).
      where(archived: true).
      order(:id)
    @lists = @lists.where("id NOT in (?)", @rejected) if @rejected.any?
  end

  def delete_all_not_used_lists
    @lists.each do |l|
      l.destroy  
    end
     redirect_to not_used_lists_admin_jobs_path, notice: "Lists deleted successfully."
  end

  def delete_checked_unused_lists
    if params[:list_ids]
      lists = List.find(params[:list_ids])
      lists.each do |l|
        l.destroy
      end
      flash[:notice] = "Selected lists were deleted."
    else
      flash[:alert] = "No lists were selected."     
    end

    redirect_to not_used_lists_admin_jobs_path
  end

  def delete_not_used_lists
    if params[:list_id].present? && list = List.find(params[:list_id])
      if list.destroyable?
        list.destroy
        redirect_to not_used_lists_admin_jobs_path, notice: "List was deleted" and return
      end
      redirect_to not_used_lists_admin_jobs_path, notice: "List cannot be deleted" and return
    end
    redirect_to not_used_lists_admin_jobs_path, notice: "No List was found" and return
  end

  # ##########################################
  private

  def authorize_for_job!
    authorize Job, :allow?
  end

end
