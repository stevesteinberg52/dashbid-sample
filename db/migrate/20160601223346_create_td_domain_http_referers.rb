class CreateTdDomainHttpReferers < ActiveRecord::Migration
  def up
    create_table :td_domain_http_referers do |t|
      t.date :dd
      t.integer :customer_id
      t.integer :placement_id
      t.string  :referrer
      t.string  :http_referer
      t.integer :load
      t.integer :load_small
      t.integer :load_medium
      t.integer :load_big
      t.integer :load_invalid
      t.integer :config
      t.integer :acs
      t.integer :imp
      t.integer :imp_small
      t.integer :imp_medium
      t.integer :imp_big
      t.integer :imp_invalid
      t.integer :q4
      t.integer :click
      t.integer :acst
      t.datetime :updated_at
    end

    add_index :td_domain_http_referers,
              [ :dd, :customer_id, :placement_id, :referrer, :http_referer ],
              { :name => 'idx_unique', :unique => true }

    add_index :td_domain_http_referers,
              [ :customer_id, :dd ],
              { :name => 'idx_customer_id' }

    add_index :td_domain_http_referers,
              [ :referrer, :dd ],
              { :name => 'idx_referrer' }

    add_index :td_domain_http_referers,
              [ :http_referer, :dd ],
              { :name => 'idx_http_referer' }

  end

  def down
    drop_table :td_domain_http_referers
  end

end
