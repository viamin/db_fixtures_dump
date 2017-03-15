# Original from http://snippets.dzone.com/posts/show/4468 by MichaelBoutros
#
# Optimized version which uses to_yaml for content creation and checks
# that models are ActiveRecord::Base models before trying to fetch
# them from database.

# Then forked from https://gist.github.com/iiska/1527911
#
# fixed obsolete use of RAILS_ROOT, glob
# allow to specify output directory by FIXTURES_PATH

namespace :db do
  namespace :fixtures do
    desc 'Dumps all models into fixtures.'
    task dump: :environment do
      models = Dir.glob(Rails.root + 'app/models/**.rb').map do |s|
        Pathname.new(s).basename.to_s.gsub(/\.rb$/,'').camelize
      end
      # specify FIXTURES_PATH to test/fixtures if you do test:unit
      dump_dir = ENV['FIXTURES_PATH'] || 'spec/fixtures/'
      excludes = []
      excludes = ENV['EXCLUDE_MODELS'].split(' ') if ENV['EXCLUDE_MODELS']
      excluded_columns = []
      excluded_columns = ENV['EXCLUDE_COLUMNS'].split(' ') if ENV['EXCLUDE_COLUMNS']
      includes = models
      includes = ENV['INCLUDE_MODELS'].split(' ') if ENV['INCLUDE_MODELS']
      puts 'Found models: ' + models.join(', ')
      puts 'Excluding: ' + excludes.join(', ')
      puts 'Dumping to: ' + dump_dir

      models.each do |m|
        next if excludes.include?(m)
        next unless includes.include?(m)

        model = m.constantize
        next unless model.ancestors.include?(ActiveRecord::Base)

        records = model.unscoped.all.order('id ASC')
        puts "Dumping model: #{m} (#{records.length} records)"

        increment = 1

        # use test/fixtures if you do test:unit
        # model_file = File.join(Rails.root, dump_dir, m.underscore.pluralize + '.yml')
        model_file = Rails.root.join(dump_dir, m.underscore.pluralize + '.yml')
        output = {}
        records.each do |record|
          attrs = record.attributes
          attrs.delete_if { |_k, v| v.nil? }
          attrs.delete_if { |k, _v| excluded_columns.include? k }

          output["#{m}_#{increment}"] = attrs

          increment += 1
        end
        File.open(model_file, 'w') { |f| f.write output.to_yaml }
        # file = File.open(model_file, 'w')
        # file << output.to_yaml
        # file.close #better than relying on gc
      end
    end
  end
end
