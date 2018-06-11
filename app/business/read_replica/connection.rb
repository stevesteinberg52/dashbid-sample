module ReadReplicaDb
  class Connection

    attr_reader :connection

    def initialize
      @db_host       = "localhost"
      @db_user       = "root"
      @db_pass       = ""
      @read_replica_mysql = {host: @db_host, username: @db_user, password: @db_pass}
      @connection    = open
      @connection.query('USE dbamapp')
    end

    def open
      @connection ||= Mysql2::Client.new(@read_replica_mysql)
    end

    def close
      @connection.close
    end

  end
end
