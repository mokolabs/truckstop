class LegacyBase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection :legacy

  def migrate
    # Grab new model class name
    model = self.class.to_s.gsub(/Legacy/,'').constantize

    # Build new model record
    new_record = model.new(map)

    # Set new model primary key value to LegacyModel primary key value
    new_record[:id] = self[self.class.primary_key.to_sym]

    # Migrate new model record
    new_record.save

    # Return any errors
    return record.errors if new_record.errors.count > 0
  end

end
