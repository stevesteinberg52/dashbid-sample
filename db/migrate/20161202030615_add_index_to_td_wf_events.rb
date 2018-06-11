class AddIndexToTdWfEvents < ActiveRecord::Migration
  def up
    add_index :td_wf_events,
              [ :dd_est, :customer_id, :placement_id ],
              { :name => 'idx_dd_est_customer' } unless index_exists?(:td_wf_events, [:dd_est, :customer_id, :placement_id], name: 'idx_dd_est_customer')
  end

  def down
    remove_index :td_wf_events, :name => 'idx_dd_est_customer'
  end
end
