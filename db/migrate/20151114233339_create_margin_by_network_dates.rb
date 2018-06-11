class CreateMarginByNetworkDates < ActiveRecord::Migration
  def up
    create_table :margin_by_network_dates, :id => false do |t|
      t.datetime  :run_at

      t.date      :date_network
      t.integer   :date_network_to_days, :null => false, :default => 0

      t.integer   :customer_id, :null => false, :default => 0
      t.string    :customer_name, :limit => 40
      t.integer   :adops_assignee_id
      t.string    :adops_assignee_name, :limit => 60

      t.integer   :placement_id, :null => false, :default => 0
      t.string    :placement_name, :limit => 80
      t.string    :dbam_symbol, :limit => 16
      t.string    :external_id
      t.boolean   :placement_is_mobile

      t.integer   :ad_source_id, :null => false, :default => 0
      t.boolean   :ad_source_is_mobile

      t.integer   :network_id, :null => false, :default => 0
      t.string    :network_name, :limit => 80

      t.integer   :impressions_m0
      t.decimal   :revenue_in_m0, :precision => 11, :scale => 7
      t.decimal   :pay_out_m0, :precision => 11, :scale => 7

      t.decimal   :network_impressions_m1, :precision => 15, :scale => 7
      t.decimal   :dbam_impressions_m1, :precision => 15, :scale => 7
      t.decimal   :revenue_in_m1, :precision => 11, :scale => 7
      t.decimal   :pay_out_m1, :precision => 11, :scale => 7

      t.decimal   :network_impressions_m2, :precision => 15, :scale => 7
      t.decimal   :dbam_impressions_m2, :precision => 15, :scale => 7
      t.decimal   :revenue_in_m2, :precision => 11, :scale => 7
      t.decimal   :pay_out_m2, :precision => 11, :scale => 7

      t.integer   :reconciled_impressions
    end

    add_index :margin_by_network_dates, [ :date_network_to_days, :customer_id ], { :name => 'idx_date_customer' }
    add_index :margin_by_network_dates, [ :date_network_to_days, :placement_id ], { :name => 'idx_date_placement' }
    add_index :margin_by_network_dates, [ :date_network_to_days, :ad_source_id ], { :name => 'idx_date_ad_source' }
    add_index :margin_by_network_dates, [ :date_network_to_days, :network_id ], { :name => 'idx_date_network' }

    execute "ALTER TABLE margin_by_network_dates ADD PRIMARY KEY (date_network_to_days, customer_id, placement_id, ad_source_id);"
  end

  def down
    drop_table   :margin_by_network_dates
  end
end
