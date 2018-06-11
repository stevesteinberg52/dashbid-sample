class AddDbifToCustomerStatementDate < ActiveRecord::Migration
  def up
    add_column :customer_statement_dates, :dbif_run_dt, :datetime
    add_column :customer_statement_dates, :dbif_locked_dt, :datetime
    add_column :customer_statement_dates, :dbif_locked_by_id, :integer
    add_column :customer_statement_dates, :dbif_hours, :integer

    CustomerStatementDate.where("dd < ?", '2016-10-01').update_all(dbif_locked_dt: Time.now)
  end

  def down
    remove_column :customer_statement_dates, :dbif_run_dt
    remove_column :customer_statement_dates, :dbif_locked_dt
    remove_column :customer_statement_dates, :dbif_locked_by_id
    remove_column :customer_statement_dates, :dbif_hours
  end
end
