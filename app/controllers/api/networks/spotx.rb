class Api::Networks::Spotx
  require 'net/https'
  require 'open-uri'

  USERNAME     = "sanjay@dashbid.com"
  PASSWORD     = "Dashbid#123"
  REPORT_TYPES = ['RevenueReport', 'TrafficReport', 'ReferrerReport', 'AdvertiserReport']

  def initialize(options={})
    @options = options
    connect
    get_report
    save_network_data
    reconcile
  end

  def connect
    @cookie       = `curl -c cookies.txt -X POST -H 'Content-Type: application/json' -d '{"username":"#{USERNAME}","password":"#{PASSWORD}"}' #{initialize_url}`
    @publisher_id = JSON.parse(@cookie).dig("value", "publisher", "publisher_id")
  end

  def get_report
    save_options
    report  = `curl -H 'Accept: application/json, Content-Type: application/json' "#{report_url}" --cookie cookies.txt`
    @report = JSON.parse report
  end

  def save_network_data
    @report['value']['data'].each do |as|
      if ad_source = AdSource.find_by(external_id: as['channel_id'])
        good_data  = { ad_source_id: ad_source.id, network_id: ad_source.network_id, customer_id: ad_source.customer_id, dd: @options[:for_date], requests: as['queries'], impressions: as['impressions'], revenue: as['payout'], clicks: as['clicks'], cc: NetworkDatum::NO_CC }
        data       = NetworkDatum.new(good_data)

        return "Object not valid" if !data.valid?

        data.update_or_save(good_data, Time.now)
      end
    end

    @network_reconciliation = NetworkReconciliation.create(network_id: 10, for_date: @options[:for_date], ready: false, active: false)
  end

  def reconcile
    @network_reconciliation.reconcile!
  end

  private

  def save_options
    @options[:for_date]  = Date.yesterday.to_s unless @options[:for_date]
    @options[:report_type] = REPORT_TYPES[0]   unless @options[:report_type]
  end

  def initialize_url
    "https://publisher-api.spotxchange.com/1.0/Publisher/Login"
  end

  def report_url
    "https://publisher-api.spotxchange.com/1.0/Publisher(#{@publisher_id})/Channels/#{@options[:report_type]}?#{url_options}"
  end

  def url_options
    "date_range=#{@options[:for_date]}|#{@options[:for_date]}"
  end
end