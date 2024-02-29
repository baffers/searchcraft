require "scenic"
require "ext/scenic/adapters/postgres"

module SearchCraft::Model
  # Maintain a list of classes that include this module
  @included_classes = []

  # Class method to add a class to the list of included classes
  def self.included(base)
    if base.is_a?(Class)
      base.extend ClassMethods

      if base.is_a?(ClassMethods) && base.respond_to?(:table_name=)
        base.table_name = base.name.to_s.tableize.tr("/", "_")

        @included_classes << base unless @included_classes.include?(base)
      end
    end
    super
  end

  # Runs .refresh! on all classes that include SearchCraft::Model
  def self.refresh_all!
    included_classes.each do |klass|
      warn "Refreshing materialized view #{klass.table_name}..." unless Rails.env.test?
      if klass.is_a?(ClassMethods)
        klass.refresh!
      end
    end
  end

  def self.refresh_any_unpopulated!
    included_classes.each do |klass|
      klass.refresh! unless klass.populated?
    end
  end

  def self.included_classes
    @included_classes | if SearchCraft.config.explicit_model_class_names
      SearchCraft.config.explicit_model_class_names.map(&:constantize)
    else
      []
    end
  end

  module ClassMethods
    def refresh!
      refresh_concurrently = @refresh_concurrently && populated?
      puts "Refreshing materialized view #{table_name}..." if SearchCraft.debug?

      Scenic.database.refresh_materialized_view(table_name, concurrently: refresh_concurrently, cascade: false)
    end

    def populated?
      Scenic.database.populated?(table_name)
    end

    def refresh_concurrently=(value)
      @refresh_concurrently = value
    end

    # Checks the database server to see if the materialized view is currently being refreshed
    def currently_refreshing?
      # quoted_table_name is table_name, but with double quotes around each chunk
      # e.g. "schema"."table" or "table"
      quoted_table_name = Scenic.database.quote_table_name(table_name)
      dbname = ActiveRecord::Base.connection_db_config.database
      sql = <<~SQL
        SELECT EXISTS (
          SELECT 1
          FROM pg_stat_activity
          WHERE datname = '#{dbname}'
            AND query LIKE '%REFRESH MATERIALIZED VIEW #{quoted_table_name}%'
            AND pid <> pg_backend_pid()
        ) AS is_refresh_running;
      SQL

      warn "Checking if #{table_name} is currently being refreshed..." if SearchCraft.debug?
      if (result = ActiveRecord::Base.connection.execute(sql))
        result.first["is_refresh_running"]
      else
        false
      end
    end
  end

  def read_only?
    true
  end
end
