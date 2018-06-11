class OutdatedDatesForMarginReport

  def initialize(month_by_day_value=nil)
    @month_by_day = month_by_day_value
  end

  def run
    @month_by_day = previous_current_months unless @month_by_day

    selected_dates
  end

  private

  # EM: Always consider previous month in automatic generation to deal with late reconciliation.
  def previous_current_months
    previous_month = (Date.today.-1.month).strftime('%Y-%m')
    current_month  = Date.today.strftime('%Y-%m')

    [previous_month, current_month].map! do |year_month|
      add_missing_days(year_month)
      month_by_day(year_month)
    end.flatten
  end

  def add_missing_days(year_month)
    HourlyMarginDate.add_missing_days(year_month)
  end

  def month_by_day(year_month)
    HourlyMarginDate.month_by_day(year_month)
  end

  def selected_dates
    days = []

    @month_by_day.each_with_index do |day, i|
      days << day.dd if outdated_date?(day, i)
    end

    days
  end

  def outdated_date?(day, i)
    calculate_day(day) || previous_day(i) || next_day(i)
  end

  def previous_day(i)
    calculate_day(@month_by_day[i-1]) if @month_by_day[i-1].present? && i != 0
  end

  def next_day(i)
    # EM: Do run this test if next day is yesterday. Yesterday data is never up to date, and it shouldn't reflect on the day before.
    calculate_day(@month_by_day[i+1]) if @month_by_day[i+1].present? && @month_by_day[i+1].dd != Date.yesterday
  end

  def calculate_day(day)
    no_reconciliation(day) || broken_process(day) || new_reconciliation(day)
  end

  def no_reconciliation(day)
    day.latest_reconcile_dt.blank?
  end

  def broken_process(day)
    day.calculate_m2.present? && day.start_processing.present? && (day.calculate_m2 < day.start_processing)
  end

  def new_reconciliation(day)
    day.calculate_m2.present? && day.latest_reconcile_dt.present? && (day.calculate_m2 < day.latest_reconcile_dt)
  end

end
