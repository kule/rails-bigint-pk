require 'active_support/all'
require 'bigint_pk/version'

module BigintPk
  mattr_accessor :enabled

  autoload :Generators, 'generators/bigint_pk'

  def self.setup
    yield self
  end

  def self.enabled= value
    install_patches! if value
  end


  def self.update_primary_key table_name, key_name
    update_key table_name, key_name, true
  end

  def self.update_foreign_key table_name, key_name
    update_key table_name, key_name, false
  end

  private

  def self.install_patches!
    install_primary_key_patches!
    install_foreign_key_patches!
  end

  def self.install_primary_key_patches!
    ActiveRecord::Base.establish_connection
    ca = ActiveRecord::ConnectionAdapters

    if ca.const_defined? :PostgreSQLAdapter
      ca::PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:primary_key] = 'bigserial primary key'
    end

    if ca.const_defined? :AbstractMysqlAdapter
      ca::AbstractMysqlAdapter::NATIVE_DATABASE_TYPES[:primary_key].gsub! /int\(11\)/, 'bigint(20)'
    end

    if ca.const_defined? :SQLServerAdapter
      ActiveRecord::Base.connection.native_database_types[:primary_key].sub! /^int/, 'bigint'
    end
  end

  def self.install_foreign_key_patches!
    [   ActiveRecord::ConnectionAdapters::TableDefinition,
        ActiveRecord::ConnectionAdapters::Table].each do |abstract_table_type|

      abstract_table_type.class_eval do
        def references_with_default_bigint_fk *args
          options = args.extract_options!
          options.reverse_merge! limit: 8
          # Limit shouldn't affect "#{col}_type" column in polymorphic reference.
          # But don't change value if it isn't simple 'true'.
          # Examples:
          #   t.references :subject, null: false, polymorphic: true ==> t.integer :subject_id, limit: 8, null: false
          #                                                             t.string  :subject_type, null: false
          #   t.references :subject, polymorphic: { limit: 120 }    ==> t.integer :subject_id, limit: 8
          #                                                             t.string  :subject_type, limit: 120
          options[:polymorphic] = options.except(:polymorphic, :limit) if options[:polymorphic] == true
          references_without_default_bigint_fk( *args, options )
        end
        alias_method_chain :references, :default_bigint_fk
        alias_method :belongs_to_without_default_bigint_fk, :belongs_to
        alias_method :belongs_to, :references_with_default_bigint_fk
      end
    end
  end


  def self.update_key table_name, key_name, is_primary_key
    c = ActiveRecord::Base.connection
    case c.adapter_name
    when 'PostgreSQL'
      c.execute %Q{
        ALTER TABLE #{c.quote_table_name table_name}
        ALTER COLUMN #{c.quote_column_name key_name}
        TYPE bigint
      }.gsub(/\s+/, ' ').strip
    when /^MySQL/i
      c.execute %Q{
        ALTER TABLE #{c.quote_table_name table_name}
        MODIFY COLUMN #{c.quote_column_name key_name}
        bigint(20) #{is_primary_key ? 'auto_increment' : 'DEFAULT NULL'}
      }.gsub(/\s+/, ' ').strip
    when 'SQLServer'
      if is_primary_key
        # For primary keys we need to drop & recreate the PK constraint
        c.execute %Q{
          DECLARE @constraint_name AS NVARCHAR(255)

          SET @constraint_name = (
            SELECT kc.Name
            FROM sys.tables t
            INNER JOIN sys.key_constraints kc ON t.object_id = kc.parent_object_id
            INNER JOIN sys.columns c ON kc.parent_object_id = c.object_id
            WHERE t.Name = '#{c.quote_string table_name}' and c.Name = '#{c.quote_string key_name}'
          )

          EXEC('ALTER TABLE #{c.quote_table_name table_name} DROP ' + @constraint_name)

          ALTER TABLE #{c.quote_table_name table_name}
          ALTER COLUMN #{c.quote_column_name key_name} bigint

          ALTER TABLE #{c.quote_table_name table_name}
          ADD PRIMARY KEY (#{c.quote_column_name key_name})
        }.gsub(/\s+/, ' ').strip
      else
        c.execute %Q{
          ALTER TABLE #{c.quote_table_name table_name}
          ALTER COLUMN #{c.quote_column_name key_name} bigint
        }.gsub(/\s+/, ' ').strip
      end
    when 'SQLite'
      # noop; sqlite always has 64bit pkeys
    else
      raise "Unsupported adapter '#{c.adapter_name}'"
    end
  end
end
