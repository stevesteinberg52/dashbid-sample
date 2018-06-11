class AddRemoveIndexesInHourlyMargins < ActiveRecord::Migration
  def up
  # dd, network_for_date, ad_source_id
    add_index :hourly_margins, [:dd, :network_for_date, :ad_source_id ], :name => 'idx_dd_networkfordate_adsourceid'

    # KEY `index_hourly_margins_on_network_for_date_and_network_id` (`network_for_date`,`network_id`),
    remove_index :hourly_margins, :name => "index_hourly_margins_on_network_for_date_and_network_id" if index_exists?(:hourly_margins, [:network_for_date, :network_id])

    # KEY `index_hourly_margins_on_customer_id_and_date_est` (`customer_id`,`date_est`),
    remove_index :hourly_margins, :name => "index_hourly_margins_on_customer_id_and_date_est" if index_exists?(:hourly_margins, [:customer_id, :date_est])

    # KEY `index_hourly_margins_on_placement_id_and_date_est` (`placement_id`,`date_est`),
    remove_index :hourly_margins, :name => "index_hourly_margins_on_placement_id_and_date_est" if index_exists?(:hourly_margins, [:placement_id, :date_est])

    # KEY `index_hourly_margins_on_ad_source_id_and_network_for_date` (`ad_source_id`,`network_for_date`),
    remove_index :hourly_margins, :name => "index_hourly_margins_on_ad_source_id_and_network_for_date" if index_exists?(:hourly_margins, [:ad_source_id, :network_for_date])

    # KEY `index_hourly_margins_on_network_id_and_network_for_date` (`network_id`,`network_for_date`),
    remove_index :hourly_margins, :name => "index_hourly_margins_on_network_id_and_network_for_date" if index_exists?(:hourly_margins, [:network_id, :network_for_date])

    # KEY `idx_date_est_customer_id` (`date_est`,`customer_id`),
    remove_index :hourly_margins, :name => "idx_date_est_customer_id"

    # KEY `idx_date_est_network_id` (`date_est`,`network_id`),
    remove_index :hourly_margins, :name => "idx_date_est_network_id"

    # KEY `index_hourly_margins_on_date_est_and_customer_id` (`date_est`,`customer_id`,`id`)
    remove_index :hourly_margins, :name => "index_hourly_margins_on_date_est_and_customer_id"
  end

  def down
    remove_index :hourly_margins, :name => "idx_dd_networkfordate_adsourceid"
  end
end
