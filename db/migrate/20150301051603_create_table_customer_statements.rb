class CreateTableCustomerStatements < ActiveRecord::Migration
  def up
    create_table :customer_statements do |t|
      t.timestamps

      t.date :dd
      t.integer :customer_id
      t.integer :placement_id
      t.boolean :fixed_price_only
      t.decimal :fixed_price, :precision => 8, :scale => 4
      t.decimal :commission_rate, :precision => 5, :scale => 4  # so that's 1.1234
      t.decimal :revenue, :precision => 10, :scale => 2  # so that's 99,999,999.12
      t.integer :imp

    end

    add_index :customer_statements,
              [ :customer_id, :dd, :placement_id ],
              { :name => 'idx_unique', :unique => true }
  end

  def down
    drop_table :customer_statements
  end
end
