class CreateTdRtbDemandTable < ActiveRecord::Migration
  def up
    create_table :td_rtb_demand do |t|
      t.datetime :dd_hour
      t.datetime :dd_est
      t.integer :network_id, default: 0
      t.integer :ad_source_id
      t.integer :bid_requests
      t.integer :bid_responses
      t.datetime :updated_at
      t.integer :data_source_id, default: 0
    end
    add_index :td_rtb_demand, [:dd_hour, :ad_source_id, :data_source_id], { name: "idx_unique", unique: true }
  end

  def down
    drop_table :td_rtb_demand
  end
end
