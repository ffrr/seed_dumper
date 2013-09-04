namespace :db do
  namespace :seed  do
    desc 'Dump records from the database into db/seeds.rb (param TABLES e.g.: TABLES=people,roles)'
    task :dump => :environment do

      all_tables = ActiveRecord::Base.connection.tables
      tables = ENV['TABLES'].split(",") if ENV['TABLES'].present?
      tables_to_dump = all_tables && (tables.nil? ? all_tables : tables)

      Dir.glob(Rails.root + '/app/models/*.rb').each { |file| require file }
      models = Rails::VERSION::MAJOR >= 3 ? tables_to_dump.map {|t| t.classify.constantize rescue nil}.compact : Object.subclasses_of(ActiveRecord::Base)
      
      models.each { |model| SeedDumper::Writer.write_data(model.name, SeedDumper::Fetcher.fetch_data(model) ) }
    end
    
    desc 'Dump records from a legacy database into db/seeds.rb'
    task :legacy_dump => :environment do
      tables = ActiveRecord::Base.connection.tables - ["schema_migrations"]
      
      tables.each do |table| 
        model_name = table.pluralize.classify
        body = proc { set_table_name table }
        model = Class.new(ActiveRecord::Base, &body)
        Object.const_set(model_name, model)
        
        SeedDumper::Writer.write_data model_name, SeedDumper::Fetcher.fetch_data(model)
      end
    end
  end
end
# /db