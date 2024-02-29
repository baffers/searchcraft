# Features of Scenic not available in v1.7.0
class Scenic::Adapters::Postgres
  # True if supplied relation name is populated. Useful for checking the
  # state of materialized views which may error if created `WITH NO DATA`
  # and used before they are refreshed. True for all other relation types.
  #
  # @param name The name of the relation
  #
  # @raise [MaterializedViewsNotSupportedError] if the version of Postgres
  #   in use does not support materialized views.
  #
  # @return [boolean]
  def populated?(name)
    raise_unless_materialized_views_supported

    schemaless_name = name.split(".").last

    sql = "SELECT relispopulated FROM pg_class WHERE relname = '#{schemaless_name}'"
    relations = execute(sql)

    if relations.count.positive?
      relations.first["relispopulated"].in?(["t", true])
    else
      false
    end
  end
end
