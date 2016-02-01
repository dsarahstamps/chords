module ApplicationHelper
  include Sys

  # return the database size in MB.
  def self.total_db_size_mb
    # Create a query to determine the database size. Use the information_schema
    # table, summing data and index totals for disk based tables that are using our
    # database.
    sql = "SELECT pg_database_size('#{get_current_db_name}')"
    query_result = perform_sql_query(sql)
    # Round the value to tenths of MB
    return  ((query_result[0]['pg_database_size'].to_f/1.0e6)*10).round / 10.0
  end

  # Return the name of the database that rails is currently using
  def self.get_current_db_name    
    return Rails.configuration.database_configuration[Rails.env]["database"]
  end

  # Return the results of an SQL query.
  def self.perform_sql_query(query)
    result = []
    mysql_res = ActiveRecord::Base.connection.execute(query)
    mysql_res.each do |res|
      result << res
    end
    return result
  end
  
  # Return the uptime, in words
  def self.uptime
    time_ago_in_words(Uptime.boot_time)
  end

end
