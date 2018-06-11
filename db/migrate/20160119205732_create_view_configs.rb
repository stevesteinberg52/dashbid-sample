class CreateViewConfigs < ActiveRecord::Migration
  def up
    self.connection.execute %Q( CREATE OR REPLACE VIEW vw_configs_by_day_by_customer_by_placement AS
        SELECT
            CAST(dd as date) AS dd,
            customer_id AS customer_id,
            placement_id AS placement_id,
            SUM(config) AS configs
          FROM td_wf_events
          GROUP BY dd, customer_id, placement_id
         )
  end

  def down
    self.connection.execute "DROP VIEW IF EXISTS vw_configs_by_day_by_customer_by_placement;"
  end
end
