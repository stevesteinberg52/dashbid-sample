class HourlyMarginProcess < ActiveRecord::Base ## AR for using connection.execute

  def self.run_all(start_dd, end_dd)
    start_date = start_dd.to_date
    end_date = [end_dd.to_date, Date.today].min

    if start_date <= end_date
      dates_in_range = (start_date..end_date).to_a
      dates_in_range.reverse_each do |one_date|
        log_event('start_processing', one_date)

        self.insert_unique_from_tdasevents(one_date)
        log_event('insert_unique_from_tdasevents', one_date)

        self.update_from_networks(one_date)
        log_event('update_from_networks', one_date)

        self.update_from_ad_sources(one_date)
        log_event('update_from_ad_sources', one_date)

        self.update_from_placements(one_date)
        log_event('update_from_placements', one_date)

        self.update_from_network_data(one_date)
        log_event('update_from_network_data', one_date)

        self.update_from_ad_source_reconciliations(one_date)
        log_event('update_from_ad_source_reconciliations', one_date)

        self.calculate_no_loss(one_date)
        log_event('calculate_no_loss', one_date)

        self.calculate_m1(one_date)
        log_event('calculate_m1', one_date)

        self.calculate_m2(one_date)
        log_event('calculate_m2', one_date)
      end
    end
  end

  def self.insert_unique_from_tdasevents(one_date)
    log_string = ""

    start_string = start_datetime_for_mysql(one_date)
    end_string = end_datetime_for_mysql(one_date)

    insert_sql = "
      INSERT IGNORE INTO hourly_margins (dd, customer_id, placement_id, ad_source_id)
        SELECT dd, customer_id, placement_id, ad_source_id
        FROM td_as_events
        WHERE dd >= '#{start_string}' AND dd <= '#{end_string}'
              AND ad_source_id IS NOT NULL
              AND ad_source_id > 0
              AND (imp > 0 OR acs > 0)"
    start_time = Time.now
    ActiveRecord::Base.connection.execute(insert_sql)
    end_time = Time.now
    log_string += "\n#{insert_sql}"
    log_string += "\n#{end_time - start_time} sec\n"

    update_sql = "
      UPDATE hourly_margins hm
        INNER JOIN (
            SELECT dd, customer_id, placement_id, ad_source_id, network_id,
                  SUM(acs) AS acs, SUM(imp) AS imp
            FROM td_as_events
            WHERE dd >= '#{start_string}' AND dd <= '#{end_string}'
            GROUP BY dd, customer_id, placement_id, ad_source_id
          ) td_grouped ON hm.dd = td_grouped.dd
                  AND hm.customer_id = td_grouped.customer_id
                  AND hm.placement_id = td_grouped.placement_id
                  AND hm.ad_source_id = td_grouped.ad_source_id
      SET
          hm.acs = td_grouped.acs,
          hm.imp = td_grouped.imp,
          hm.network_id = td_grouped.network_id,
          hm.date_utc = DATE(hm.dd),
          hm.date_est = DATE(CONVERT_TZ(hm.dd, 'UTC', 'EST'))"
    start_time = Time.now
    ActiveRecord::Base.connection.execute(update_sql)
    end_time = Time.now
    log_string += "\n#{update_sql}"
    log_string += "\n#{end_time - start_time} sec\n"

    # the network id in td_as_events gets filled in based on ad_source
    # with a cron job which may not have run
    # at the time that the above query does the insert into hourly_margins
    update_sql = "
      UPDATE hourly_margins hm
        INNER JOIN ad_sources adsrc ON hm.ad_source_id = adsrc.id
      SET hm.network_id = adsrc.network_id
      WHERE hm.date_est = '#{one_date}' AND hm.network_id IS NULL"
    start_time = Time.now
    ActiveRecord::Base.connection.execute(update_sql)
    end_time = Time.now
    log_string += "\n#{update_sql}"
    log_string += "\n#{end_time - start_time} sec\n"

    return log_string
  end

  def self.update_from_networks(one_date)
    log_string = ""

    # start_string = start_datetime_for_mysql(one_date)
    # end_string = end_datetime_for_mysql(one_date)

    update_sql = "
      UPDATE hourly_margins hm
        INNER JOIN networks nt ON hm.network_id = nt.id
      SET hm.network_tz_offset = nt.tz_offset_from_utc
      WHERE hm.date_est = '#{one_date}'
        AND IFNULL(hm.network_tz_offset,'') = ''"
    start_time = Time.now
    ActiveRecord::Base.connection.execute(update_sql)
    end_time = Time.now
    log_string += "\n#{update_sql}"
    log_string += "\n#{end_time - start_time} sec\n"

    update_sql = "
      UPDATE hourly_margins hm
        INNER JOIN convert_tz tz ON tz.date_hour = hm.dd AND tz.tz_offset = hm.network_tz_offset
      SET hm.network_for_date = tz.offset_date
      WHERE hm.date_est = '#{one_date}'"
    start_time = Time.now
    ActiveRecord::Base.connection.execute(update_sql)
    end_time = Time.now
    log_string += "\n#{update_sql}"
    log_string += "\n#{end_time - start_time} sec\n"

    return log_string
  end


  def self.update_from_ad_sources(one_date)
    log_string = ""

    # start_string = start_datetime_for_mysql(one_date)
    # end_string = end_datetime_for_mysql(one_date)

    update_sql = "
      UPDATE hourly_margins hm
        INNER JOIN ad_sources ads ON hm.ad_source_id = ads.id
      SET hm.as_floor_price = ads.min_floor_price
      WHERE hm.date_est = '#{one_date}'"
    start_time = Time.now
    ActiveRecord::Base.connection.execute(update_sql)
    end_time = Time.now
    log_string += "\n#{update_sql}"
    log_string += "\n#{end_time - start_time} sec\n"
  end

  def self.update_from_placements(one_date)
    log_string = ""

    # start_string = start_datetime_for_mysql(one_date)
    # end_string = end_datetime_for_mysql(one_date)

    update_sql = "
      UPDATE hourly_margins hm
        INNER JOIN placements pl ON hm.placement_id = pl.id
        INNER JOIN customers cu ON hm.customer_id = cu.id
      SET hm.p_fixed_price_only = pl.fixed_price_only,
          hm.p_commission =
                IF(pl.fixed_price_only, NULL,
                    IFNULL(pl.commission_percentage / 100.0, cu.commission_rate)),
          hm.p_fixed_price =
                IF(pl.fixed_price_only, pl.fixed_price, NULL)
      WHERE hm.date_est = '#{one_date}'"
    start_time = Time.now
    ActiveRecord::Base.connection.execute(update_sql)
    end_time = Time.now
    log_string += "\n#{update_sql}"
    log_string += "\n#{end_time - start_time} sec\n"

    return log_string
  end

  def self.update_from_network_data(one_date)
    log_string = ""

    # start_string = start_datetime_for_mysql(one_date)
    # end_string = end_datetime_for_mysql(one_date)

    update_sql = "
      UPDATE hourly_margins hm
        LEFT JOIN network_data nd
           ON hm.network_for_date = nd.dd
            AND hm.ad_source_id = nd.ad_source_id
            AND nd.cc = '#{NetworkDatum::NO_CC}'
      SET hm.network_datum_id = nd.id,
          hm.nd_revenue = nd.revenue,
          hm.nd_impressions = nd.impressions
      WHERE hm.date_est = '#{one_date}'"
    start_time = Time.now
    ActiveRecord::Base.connection.execute(update_sql)
    end_time = Time.now
    log_string += "\n#{update_sql}"
    log_string += "\n#{end_time - start_time} sec\n"

    yesterday = one_date.to_date - 1.day
    yesterday_start_string = start_datetime_for_mysql(yesterday)

    tomorrow = one_date.to_date + 1.day
    tomorrow_end_string = end_datetime_for_mysql(tomorrow)

    update_sql = "
      UPDATE hourly_margins hm
        INNER JOIN (

          SELECT tz.offset_date AS network_date,
            td.ad_source_id,
            SUM(td.imp) AS sum_imp
          FROm
          (
          SELECT dd, ad_source_id, network_id, imp
          FROM td_as_events
          WHERE dd >= '#{yesterday_start_string}' AND dd <= '#{tomorrow_end_string}'
          ) td

          INNER JOIN networks nt ON nt.id = td.network_id
          INNER JOIN convert_tz tz ON tz.date_hour = td.dd AND tz.tz_offset = nt.tz_offset_from_utc

          GROUP BY tz.offset_date, td.ad_source_id

        ) td_grouped ON td_grouped.network_date = hm.network_for_date
            AND td_grouped.ad_source_id = hm.ad_source_id

      SET hm.nd_dbam_impressions = td_grouped.sum_imp
      WHERE hm.date_est = '#{one_date}'"

    start_time = Time.now
    ActiveRecord::Base.connection.execute(update_sql)
    end_time = Time.now
    log_string += "\n#{update_sql}"
    log_string += "\n#{end_time - start_time} sec\n"

    return log_string
  end

  def self.update_from_ad_source_reconciliations(one_date)
    ## TODO: how do we know and what do we do if the Ad Source Reconciliation record changes?
    log_string = ""

    # start_string = start_datetime_for_mysql(one_date)
    # end_string = end_datetime_for_mysql(one_date)

    update_sql = "
      UPDATE hourly_margins hm
        LEFT JOIN ad_source_reconciliations asr
          ON hm.network_for_date = asr.for_date
            AND hm.ad_source_id = asr.ad_source_id
            AND asr.active = 1

      SET hm.ad_source_reconciliation_id = asr.id,
          hm.asr_revenue = asr.revenue,
          hm.asr_adjusted_network_impressions = IFNULL(asr.network_impressions,0) + IFNULL(asr.network_adjustment,0),
          hm.asr_adjusted_dbam_impressions = IFNULL(asr.dbam_impressions,0) + IFNULL(asr.dbam_adjustment,0),
          hm.asr_max_adjustment_ratio = IFNULL(asr.max_adjustment_ratio,1)

      WHERE hm.date_est = '#{one_date}'"
    start_time = Time.now
    ActiveRecord::Base.connection.execute(update_sql)
    end_time = Time.now
    log_string += "\n#{update_sql}"
    log_string += "\n#{end_time - start_time} sec\n"

    update_sql = "
      UPDATE hourly_margins hm
      SET asr_adjustment_ratio =
              IF( asr_adjusted_dbam_impressions = 0, 1,
                  asr_adjusted_network_impressions / asr_adjusted_dbam_impressions )
      WHERE hm.date_est = '#{one_date}'"
    start_time = Time.now
    ActiveRecord::Base.connection.execute(update_sql)
    end_time = Time.now
    log_string += "\n#{update_sql}"
    log_string += "\n#{end_time - start_time} sec\n"

    return log_string
  end

  def self.calculate_no_loss(one_date)
    log_string = ""

    # start_string = start_datetime_for_mysql(one_date)
    # end_string = end_datetime_for_mysql(one_date)

    # no reconciliation, no loss
    # ignore network impressions, use dbam (unadjusted) imp
    update_sql = "
      UPDATE hourly_margins
      SET revenue_in_m0 = imp * as_floor_price / 1000.00,
          pay_out_m0 = IF( p_fixed_price_only,
                        imp * p_fixed_price / 1000.00,
                        imp * as_floor_price * (1 - p_commission) / 1000.00 )
      WHERE date_est = '#{one_date}'"
    start_time = Time.now
    ActiveRecord::Base.connection.execute(update_sql)
    end_time = Time.now
    log_string += "\n#{update_sql}"
    log_string += "\n#{end_time - start_time} sec\n"

    return log_string
  end

  def self.calculate_m1(one_date)
    ## TODO: how do we determine and what do we do if the Network Data record changes?
    log_string = ""

    # start_string = start_datetime_for_mysql(one_date)
    # end_string = end_datetime_for_mysql(one_date)

    # if there is no Network Data record, revenue & payout at 80%
    update_sql = "
      UPDATE hourly_margins hm
      SET network_impressions_m1 = imp,
          revenue_in_m1 = imp * as_floor_price / 1000.00,
          dbam_impressions_m1 = imp,
          pay_out_m1 = IF( p_fixed_price_only,
                              imp * p_fixed_price / 1000.00,
                              imp * as_floor_price * (1 - p_commission) / 1000.00 )
      WHERE hm.date_est = '#{one_date}'
          AND network_datum_id IS NULL"
    start_time = Time.now
    ActiveRecord::Base.connection.execute(update_sql)
    end_time = Time.now
    log_string += "\n#{update_sql}"
    log_string += "\n#{end_time - start_time} sec\n"

    # there is a Network Data record ()
    update_sql = "UPDATE hourly_margins hm
                    SET
                        network_impressions_m1 =
                          IF( IFNULL(nd_dbam_impressions,0) = 0, 0, imp * nd_impressions / nd_dbam_impressions ),
                        revenue_in_m1 =
                          IF( IFNULL(nd_dbam_impressions,0) = 0, 0, nd_revenue * imp / nd_dbam_impressions ),

                        dbam_impressions_m1 =
                          IF( IFNULL(nd_dbam_impressions,0) = 0, 0,
                              imp * asr_adjusted_dbam_impressions / nd_dbam_impressions )

                    WHERE hm.date_est = '#{one_date}'
                        AND network_datum_id IS NOT NULL"
    start_time = Time.now
    ActiveRecord::Base.connection.execute(update_sql)
    end_time = Time.now
    log_string += "\n#{update_sql}"
    log_string += "\n#{end_time - start_time} sec\n"

    update_sql = "UPDATE hourly_margins hm
                    SET pay_out_m1 =
                          IF( p_fixed_price_only,
                                LEAST(imp, network_impressions_m1) * p_fixed_price / 1000.00,
                                revenue_in_m1 * (1 - p_commission) )
                    WHERE hm.date_est = '#{one_date}'
                        AND network_datum_id IS NOT NULL"
    start_time = Time.now
    ActiveRecord::Base.connection.execute(update_sql)
    end_time = Time.now
    log_string += "\n#{update_sql}"
    log_string += "\n#{end_time - start_time} sec\n"

    return log_string
  end

  def self.calculate_m2(one_date)
    ## TODO: how do we track and what do we do if the Ad Source Reconciliation record changes?
    log_string = ""

    # start_string = start_datetime_for_mysql(one_date)
    # end_string = end_datetime_for_mysql(one_date)

    # if there is no Ad Source Reconciliation record, revenue & payout at 80%
    update_sql = "UPDATE hourly_margins hm
                    SET network_impressions_m2 = imp * 0.8,
                        revenue_in_m2 = imp * 0.8 * as_floor_price / 1000.00,
                        dbam_impressions_m2 = imp * 0.8,
                        pay_out_m2 = IF( p_fixed_price_only,
                                            imp * 0.8 * p_fixed_price / 1000.00,
                                            imp * 0.8 * as_floor_price * (1 - p_commission) / 1000.00 )
                    WHERE hm.date_est = '#{one_date}'
                        AND ad_source_reconciliation_id IS NULL"
    start_time = Time.now
    ActiveRecord::Base.connection.execute(update_sql)
    end_time = Time.now
    log_string += "\n#{update_sql}"
    log_string += "\n#{end_time - start_time} sec\n"

    # there is an Ad Source Reconciliation record
    update_sql = "UPDATE hourly_margins hm
                    SET network_impressions_m2 =
                          IF( IFNULL(nd_dbam_impressions,0) = 0, 0,
                              imp * asr_adjusted_network_impressions / nd_dbam_impressions ),
                        revenue_in_m2 =
                          IF( IFNULL(nd_dbam_impressions,0) = 0, 0,
                              imp * asr_revenue / nd_dbam_impressions ),
                        dbam_impressions_m2 = imp * LEAST(asr_adjustment_ratio, asr_max_adjustment_ratio)

                    WHERE hm.date_est = '#{one_date}'
                        AND ad_source_reconciliation_id IS NOT NULL"
    start_time = Time.now
    ActiveRecord::Base.connection.execute(update_sql)
    end_time = Time.now
    log_string += "\n#{update_sql}"
    log_string += "\n#{end_time - start_time} sec\n"

    update_sql = "UPDATE hourly_margins hm
                    SET pay_out_m2    = IF( p_fixed_price_only,
                                            dbam_impressions_m2 * p_fixed_price / 1000.00,
                                            revenue_in_m2 * (1 - p_commission) )

                    WHERE hm.date_est = '#{one_date}'"
    start_time = Time.now
    ActiveRecord::Base.connection.execute(update_sql)
    end_time = Time.now
    log_string += "\n#{update_sql}"
    log_string += "\n#{end_time - start_time} sec\n"

    return log_string
  end

  ################
  private

  def self.start_datetime_for_mysql(in_datetime)
    in_datetime.to_date.beginning_of_day.utc.strftime('%Y-%m-%d %H:%M:%S')
  end

  def self.end_datetime_for_mysql(in_datetime)
    in_datetime.to_date.end_of_day.utc.strftime('%Y-%m-%d %H:%M:%S')
  end

  def self.log_event(message, one_date)
    HourlyMarginDate.log_event(message, one_date, one_date)
  end
end

