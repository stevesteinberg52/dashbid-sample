class CustomerStatementDate < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :locked_by, :class_name => 'User', :foreign_key => 'locked_by_id'

  scope :last_months, lambda { |offset| select_attributes.where( self.arel_table[:dd].
                                                                 gteq(offset.months.ago.to_date).
                                                                 and(self.arel_table[:dd].lteq(1.day.ago)) ) }
  scope :not_locked, -> { where(locked_dt: nil) }
  scope :dbif_not_locked, -> { where(dbif_locked_at: nil) }

  def self.add_missing_days(params_hash)
    year_month = params_hash[:year_month]
    date_string = "#{year_month}-01"
    month_start_date = date_string.to_date
    month_end_date = month_start_date.end_of_month

    yesterday = Time.now.to_date - 1.day
    end_date = [month_end_date, yesterday].min

    if month_start_date <= end_date
      dates_in_range = (month_start_date..end_date).to_a
    else
      dates_in_range = []
    end

    dates_in_range.each do |one_date|
      unless self.where(:dd => one_date).first
        self.create({:dd => one_date})
      end
    end
  end

  def self.by_month
    self.select("DATE_FORMAT(dd,'%Y-%m') AS year_and_month")
        .group("DATE_FORMAT(dd,'%Y-%m')")
        .order("DATE_FORMAT(dd,'%Y-%m') DESC")
  end

  def self.month_by_day(params_hash)
    select_attributes.where("DATE_FORMAT(dd,'%Y-%m') = '#{params_hash[:year_month]}'").order('dd')
  end

  private

  def self.select_attributes
    self.
      select(:dd).
      select(:locked_dt).
      select(:dbif_locked_at).
      select(:dbif_run_dt).
      select(:dbif_hours).
      joins('LEFT OUTER JOIN (SELECT id, email FROM users) u ON u.id = locked_by_id').
      select('u.email AS locked_by_email').
      joins("LEFT OUTER JOIN
                  (SELECT dd AS cs_dd,
                      SUM(revenue) AS revenue, SUM(imp) AS impressions,
                          MIN(calculated_at) AS earliest_dt,
                      SUM(latest_revenue) AS latest_revenue, SUM(latest_imp) AS latest_imp,
                          MAX(latest_recalc_dt) AS latest_recalc_dt,
                      SUM(wf_requests) AS wf_requests_sum,
                      SUM(wf_impressions) AS wf_impressions_sum,
                      SUM(dbif_fee) AS dbif_fee_sum
                  FROM customer_statements
                  GROUP BY dd) cs
                  ON cs.cs_dd = dd").
      select('cs.revenue').
      select('cs.impressions').
      select('cs.earliest_dt').
      select('cs.latest_recalc_dt').
      select('cs.latest_imp').
      select('cs.latest_revenue').
      select('cs.wf_requests_sum').
      select('cs.wf_impressions_sum').
      select('cs.dbif_fee_sum').
      joins("LEFT OUTER JOIN
                  (SELECT for_date,
                        MAX(updated_at) AS latest_reconcile_dt
                      FROM network_reconciliations
                      GROUP BY for_date) nr
                      ON nr.for_date = dd").
      select('nr.latest_reconcile_dt').
      joins("LEFT OUTER JOIN
                  (SELECT for_date,
                        MAX(updated_at) AS latest_as_reconcile_dt
                      FROM ad_source_reconciliations
                      GROUP BY for_date) asr
                      ON asr.for_date = dd").
      select('asr.latest_as_reconcile_dt')
  end
end
