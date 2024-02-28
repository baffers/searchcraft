require "scenic"

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
      unless klass.respond_to?(:populated?) && klass.populated?
        klass.refresh!
      end
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
      # NOTE: https://github.com/scenic-views/scenic/pull/406 will do this clean up for us
      schemaless_table_name = table_name.split(".").last.presence || table_name
      if Scenic.database.respond_to?(:populated?)
        Scenic.database.populated?(schemaless_table_name)
      else
        warn "Upgrade Scenic beyond v1.7.0 to get populated? method"
        true
      end
    end

    def refresh_concurrently=(value)
      @refresh_concurrently = value
    end
  end

  def read_only?
    true
  end
end
