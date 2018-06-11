class NetworkRevenueDailyReport
  attr_accessor :data, :csv

  def initialize(dates, networks, network_totals, td_date_impressions, td_total_impressions, network_data)
    @dates                = dates
    @networks             = networks
    @network_totals       = network_totals
    @td_date_impressions  = td_date_impressions
    @td_total_impressions = td_total_impressions
    @network_data         = network_data
    @csv                  = to_csv
  end

  private

  def to_csv
    CSV.generate do |csv|
      csv << csv_column_names
      @dates.each { |date| csv << date_row(date) }
      csv << total_row
    end
  end

  def date_row(date)
    @date = date

    [
      @date,
      percentage,
      diff_percent,
      @td_date_impressions[@date],
      diff,
      @total_for_date_revenue.round(2),
      @total_for_date_impressions,
      cpm(@total_for_date_revenue, @total_for_date_impressions)
    ] + networks_columns
  end

  def networks_columns(type=nil)
    @networks.map do |n|
      network_datum = @network_data.find{|o| o.network_id == n[:id] && o.dd == (type ? nil : @date)} || false
      rev = network_datum ? network_datum.revenue.round(2) : nil
      imp = network_datum ? network_datum.impressions : nil
      [rev, imp, cpm(rev,imp)]
    end.flatten
  end

  def total_row
    @total = @network_totals.find{|o| o.dd.nil?}

    [
      'Totals',
      total_percentage,
      (total_percentage - 100.0).round(1),
      @td_total_impressions,
      total_diff,
      @total.revenue.round(2),
      @total.impressions,
      cpm(@total.revenue, @total.impressions)
    ] + networks_columns(:total)
  end

  def csv_column_names
    ['Day', 'Net/Dbam', 'Diff %', 'Dbam Imp', 'Diff', 'Rev', 'Imp', 'CPM'] + @networks.map do |n|
      ["#{n[:abbrev]} Rev", "#{n[:abbrev]} Imp", "#{n[:abbrev]} CPM"]
    end.flatten
  end

  def total_percentage
    if @td_total_impressions && @td_total_impressions > 0
      return (100.0 * @total.try(:impressions) / @td_total_impressions.to_f).round(1)
    end
    return 0.0
  end

  def total_diff
    diff = (@total.try(:impressions) || 0) - (@td_total_impressions || 0)
    "#{diff > 0 ? '+' : ''}#{diff}"
  end

  def percentage
    total_for_date              = @network_totals.find{|o| o.dd == @date}
    @total_for_date_impressions = total_for_date.try(:impressions) || 0
    @total_for_date_revenue     = total_for_date.try(:revenue) || 0

    if @td_date_impressions[@date] && @td_date_impressions[@date] > 0 && @total_for_date_impressions
      return (100.0 * @total_for_date_impressions / @td_date_impressions[@date]).round(1)
    end

    return 0.0
  end

  def diff_percent
    num = percentage
    "#{num > 100.0 ? '+' : ''}#{(num-100.0).round(1)}"
  end

  def diff
    diff = (@total_for_date_impressions || 0) - (@td_date_impressions[@date] || 0)
    "#{diff > 0 ? '+' : ''}#{diff}"
  end

  def cpm(rev,imp)
    if rev && imp && imp > 0
      (1000.00 * rev / imp.to_f).round(2)
    end
  end
end