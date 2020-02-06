require "trucker/version"

module Trucker

  def self.migrate(name, options={})
    # Grab custom entity label if present
    label = options.delete(:label) if options[:label]

    unless options[:helper]

      # Grab model
      model = name.to_s.classify.constantize

      # Grab legacy model
      legacy_model = "Legacy#{name.to_s.classify}".constantize

      # Wipe out existing records
      model.delete_all

      # Status message
      status = "Migrating "
      status += "#{limit || "all"} #{label || name}"
      status += " after #{offset}" if offset

      # Set import counter
      counter = 0
      counter += offset if offset
      total_records = legacy_model.where(options[:where]).all.count

      # Set up error tracking
      errors = []

      # Start import
      legacy_model.where(options[:where]).limit(limit).offset(offset).each do |record|
        counter += 1
        puts status + " (#{counter}/#{total_records})"
        error = record.migrate
        errors << error unless error == nil
      end

      # Show errors
      if errors.count > 0
        puts "\n\n#{errors.count} ERRORS"

        errors.each do |error|
          puts "...................."
          puts error.inspect
        end
      end

      # Reset primary key sequence value for new records
      # (so values for new records don't clash with old records)
      model.reset_pk_sequence
    else
      eval options[:helper].to_s
    end
  end

  protected

    def self.limit
      nil || ENV['limit'].to_i if ENV['limit'].to_i > 0
    end

    def self.offset
      nil || ENV['offset'].to_i if ENV['offset'].to_i > 0
    end

end
