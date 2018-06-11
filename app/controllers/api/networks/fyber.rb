class Api::Networks::Fyber
  require 'net/https'
  require 'open-uri'

  OAUTH_SIGNATURE = "92bb7894d2%26"
  OAUTH_CONSUMER_KEY = "32ad1a5f8c89b25706dbdc7009823b"

  def initialize(options={})
    @options = options
    connect
    get_report
    save_network_data
    reconcile
  end

  def connect
    response  = `curl -H 'Authorization: OAuth realm="", oauth_signature_method="PLAINTEXT", oauth_signature="#{OAUTH_SIGNATURE}", oauth_consumer_key="#{OAUTH_CONSUMER_KEY}", oauth_version="1.0"' --insecure #{initialize_url}`
    @oauth_token, @oauth_token_secret = response.split('&')
    auth_info = `curl -H 'Authorization: OAuth realm="", oauth_signature_method="PLAINTEXT", oauth_consumer_key="#{OAUTH_CONSUMER_KEY}", oauth_signature="#{OAUTH_SIGNATURE}#{@oauth_token_secret.split('=').last}", oauth_version="1.0", oauth_token="#{@oauth_token.split('=').last}"' --insecure #{token_url}`
    @oauth_token, @oauth_token_secret = auth_info.split('&')
  end

  def get_report
    save_options
    report  = `curl -X POST -H 'Authorization: OAuth realm="", oauth_signature_method="PLAINTEXT", oauth_consumer_key="#{OAUTH_CONSUMER_KEY}", oauth_signature="#{OAUTH_SIGNATURE}#{@oauth_token_secret.split('=').last}", oauth_version="1.0", oauth_token="#{@oauth_token.split('=').last}"' -d '#{data_hash}' --insecure #{report_url}`
    @report = JSON.parse report
  end

  def save_network_data
    @report['data'].each do |as|
      if ad_source = AdSource.find_by(external_id: as['description'])
        good_data  = { ad_source_id: ad_source.id, network_id: ad_source.network_id, customer_id: ad_source.customer_id, dd: @start_date, requests: as['requests'], impressions: as['imps'], revenue: (as['total_sprice']/1000000), clicks: as['clicks'], first_quartiles: as['video_firstQuartile'], midpoints: as['video_midpoint'], third_quartiles: as['video_thirdQuartile'], completes: as['video_complete'], cc: NetworkDatum::NO_CC }
        data       = NetworkDatum.new(good_data)

        return "Object not valid" if !data.valid?

        data.update_or_save(good_data, Time.now)
      end
    end

    @network_reconciliation = NetworkReconciliation.create(network_id: 113, for_date: @start_date, ready: false, active: false)
  end

  def reconcile
    @network_reconciliation.reconcile!
  end

  private

  def save_options
    @start_date  = @options[:for_date] || Date.yesterday.to_s
    @end_date    = @options[:for_date] || Date.yesterday.to_s
    @page        = @options[:page]     || "0"
    @per_page    = @options[:per_page] || "500"
    @data_fields = '"requests","imps","total_sprice","clicks","video_firstQuartile","video_midpoint","video_thirdQuartile","video_complete"'
  end

  def initialize_url
    URI.parse("https://reportapi.ang.falktec.com/oauth/initialize")
  end

  def token_url
    "https://reportapi.ang.falktec.com/oauth/token"
  end

  def report_url
    "https://reportapi.ang.falktec.com/reportapi/data/#{@page}/#{@per_page}"
  end

  def data_hash
    '{"categories":["placement"], "startDate":"'+@start_date+'", "endDate":"'+@end_date+'", "orderBy":"imps", "orderDirection":"DESC", "filterChain":[], "dataFields":['+@data_fields+']}'
  end
end