class Admin::CustomerStatementDatesController < AdminController
  include AdminHelper
  include GetRecordByIdHelper

  before_action :authorize!, only: [:index]

  def index
    # RBT: TODO: Refactor this!
    month_by_day
    render 'month_by_day'
  end

  def all_months
    @months = CustomerStatementDate.by_month
  end

  def month_by_day
    if @year_month = params[:year_month] || Time.zone.now.strftime('%Y-%m')
      params_hash = { year_month: @year_month }
      CustomerStatementDate.add_missing_days(params_hash)
      @month_by_day = CustomerStatementDate.month_by_day(params_hash)
      this_month = ("#{@year_month}-01").to_date
      @prev_month = (this_month - 1.month).strftime('%Y-%m')
      @next_month = (this_month + 1.month).strftime('%Y-%m')
    else
      @month_by_day = []
    end
  end

  def lock_date
    if record = CustomerStatementDate.where(:dd => params[:dd]).first
      if record.locked_dt
        flash[:notice] = "'#{record.dd}' is ALREADY LOCKED"
      else
        attr_hash = {
            locked_dt: Time.now.to_datetime,
            locked_by_id: current_user.id,
            dbif_locked_at: record.dbif_locked_at || Time.now.to_datetime
        }
        #
        if record.update_attributes(attr_hash)
          flash[:notice] = "'#{record.dd}' is now LOCKED"
        else
          flash[:alert] = "'#{record.dd}' locking FAILED"
        end
      end
    else
      flash[:alert] = 'Record not found!'
    end

    redirect_to month_by_day_admin_customer_statement_dates_path({ year_month: params[:year_month] })
  end

  def lock_all_dates
      start_date = ("#{params[:year_month]}-01").to_date
      end_date = [start_date.end_of_month, Time.now.to_date - 1.day].min

      (start_date..end_date).each do |date|
        cs = CustomerStatementDate.find_by_dd(date)
        cs.locked_dt = cs.locked_dt.nil? ? Time.now.to_datetime : nil
        cs.locked_by_id = cs.locked_by_id.nil? ? current_user.id : nil
        cs.save
      end

    redirect_to month_by_day_admin_customer_statement_dates_path({:year_month => params[:year_month]})  
  end

  def lock_all_fpf_dates
      start_date = ("#{params[:year_month]}-01").to_date
      end_date = [start_date.end_of_month, Time.now.to_date - 1.day].min

      (start_date..end_date).each do |date|
        cs = CustomerStatementDate.find_by_dd(date)
        cs.dbif_locked_at = cs.dbif_locked_at.nil? ? Time.now.to_datetime : nil
        cs.save
      end

    redirect_to month_by_day_admin_customer_statement_dates_path({:year_month => params[:year_month]})      
  end

  def lock_dbif_date
    if record = CustomerStatementDate.where(:dd => params[:dd]).first
       record.update(dbif_locked_at: Time.now.to_datetime)
    else
       flash[:alert] = 'Record not found!'
    end

    redirect_to month_by_day_admin_customer_statement_dates_path({:year_month => params[:year_month]})    
  end

  def unlock_dbif_date
    if record = CustomerStatementDate.where(:dd => params[:dd]).first
       record.update(dbif_locked_at: nil)
    else
       flash[:alert] = 'Record not found!'
    end

    redirect_to month_by_day_admin_customer_statement_dates_path({:year_month => params[:year_month]})    
  end


  def authorize!
    authorize CustomerStatementDate, :allow?
  end
  
  def unlock_date
    if record = CustomerStatementDate.where(:dd => params[:dd]).first
      unless record.locked_dt
        flash[:notice] = "'#{record.dd}' is ALREADY UNLOCKED"
      else
        attr_hash = {
            :locked_dt => nil,
            :locked_by_id => nil
        }
        if record.update_attributes(attr_hash)
          flash[:notice] = "'#{record.dd}' is now UNLOCKED"
        else
          flash[:alert] = "'#{record.dd}' unlocking FAILED"
        end
      end
    else
      flash[:alert] = 'Record not found!'
    end

    redirect_to month_by_day_admin_customer_statement_dates_path({:year_month => params[:year_month]})
  end

  def generate_date
    if params[:dd].present?
      run_date = params[:dd]
      CustomerStatementDatesGenerateWorker.perform_async(run_date, run_date)
      flash[:notice] = "A background job have been submitted for to process Customer Statement for all customers on #{run_date}."
    else
      flash[:error] = 'Date param not found. It is needed to schedule Customer Statements job. Please try again with a date param (dd).'
    end

    redirect_to month_by_day_admin_customer_statement_dates_path(year_month: params[:year_month])
  end

  def generate_all_dates_by_month
    if params[:year_month].present?
      CustomerStatementDatesGenerateByMonthWorker.perform_async(params[:year_month])
      flash[:notice] = "A background job have been submitted for to process all possible Customer Statements for all customers in this month."
      redirect_to month_by_day_admin_customer_statement_dates_path(year_month: params[:year_month])
    else
      flash[:error] = 'Date param not found. It is needed to schedule Customer Statements job. Please try again using the "Calclate all dates for this Month" button.'
      redirect_to all_months_admin_customer_statement_dates_path
    end
  end

  def billing_template
    if params[:year_month]
      selected_month = params[:year_month]
      selected_month_date = ("#{selected_month}-01").to_date

      year_month = selected_month_date.strftime('%Y-%m')
      file_name = "billing_template_#{year_month}"

      start_date = selected_month_date.beginning_of_month
      end_date = selected_month_date.end_of_month

      @networks_data = NetworkDatum.by_network(start_date, end_date)
      @publishers_data = CustomerStatement.month_by_customer({:year_month => year_month})
      render xlsx: "billing_template", filename: file_name
    else
      flash[:alert] = 'Billing Template generation failed'
      redirect_to month_by_day_admin_customer_statement_dates_path({:year_month => params[:year_month]})

    end
  end
end
