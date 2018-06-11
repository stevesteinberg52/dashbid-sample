module TableauDb
  class Connection

    def initialize
      @db_host       = "localhost"
      @db_user       = "root"
      @db_pass       = ""
      @tableau_mysql = {host: @db_host, username: @db_user, password: @db_pass}
      @connection    = open
      @connection.query('USE tableau')
    end

    def open
      @connection ||= Mysql2::Client.new(@tableau_mysql)
    end

    def close
      @connection.close
    end

    private

    def connect
      @connection.tables.each do |table|
        klass = self.const_set(table.capitalize,Class.new(ActiveRecord::Base))
        klass.class_eval do
          self.table_name = table
        end
      end
    end
  end
end