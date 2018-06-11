class Api::Networks::Vdopia
  require 'net/https'
  require 'open-uri'

  API_KEY = "81cff29afedb4781cd8e3069c9ad3070"

  def initialize(options={})
    @options = options
    connect
    get_report
    save_network_data
    reconcile
  end

  def connect
  end

  def get_report
    save_options
    report  = `curl --insecure "#{report_url}"`
    @report = JSON.parse report
  end

  def save_network_data
    @report['data'].each do |as|
      if ad_source = AdSource.find_by(external_id: as['channel_name'])
        good_data  = { ad_source_id: ad_source.id, network_id: ad_source.network_id, customer_id: ad_source.customer_id, dd: @options[:for_date], requests: as['queries'], impressions: as['impressions'], revenue: as['payout'], clicks: as['clicks'], cc: NetworkDatum::NO_CC }
        data       = NetworkDatum.new(good_data)

        return "Object not valid" if !data.valid?

        data.update_or_save(good_data, Time.now)
      end
    end
  end

  def reconcile
  end

  private

  def save_options
    @start_date  = @options[:for_date] || Date.yesterday.to_s
    @end_date    = @options[:for_date] || Date.yesterday.to_s
    @data_fields = "date,channel_name,revenue,requests,impressions,clicks"
  end

  def report_url
    "https://www.vdopia.com/library/reportApi.php?apikey=#{API_KEY}&auth=publisher&publisher_id=9930&start_date=#{@start_date}&end_date=#{@end_date}&source=stats&field=#{@data_fields}"
  end
end