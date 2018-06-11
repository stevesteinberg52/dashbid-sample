class HealthCheck

  def self.td_wf_events_job(how_many_hours)
    # Treasure hourly job runs at 50 minutes past the hour and takes seconds to run.
    # Schedule to run after the first of the hour, such that last_hour is 2 hours earlier.
    last_hour     = Time.zone.now.beginning_of_hour - 2.hour
    missing_hours = []
    found_hours   = []

    (0..(how_many_hours -1)).each do |num|
      hour   = last_hour - num.hours
      result = TdWfEvent.where("`dd` = ? AND `request` > ? AND `load` > ? AND `config` > ? AND `imp` > ?", hour, 0, 0, 0, 0).limit(1)
      if result.empty?
        missing_hours << hour.strftime('%Y-%m-%d %l:%M %P')
      else
        found_hours << hour.strftime('%Y-%m-%d %l:%M %P')
      end
    end
    [found_hours, missing_hours]
  end

  def self.td_as_events_job(how_many_hours)
    # Treasure hourly job runs at 50 minutes past the hour and takes seconds to run.
    # Schedule to run after the first of the hour, such that last_hour is 2 hours earlier.
    last_hour     = Time.zone.now.beginning_of_hour - 2.hour
    missing_hours = []
    found_hours   = []

    (0..(how_many_hours -1)).each do |num|
      hour   = last_hour - num.hours
      result = TdAsEvent.where('dd  = ?', hour).limit(1)
      if result.empty?
        missing_hours << hour.strftime('%Y-%m-%d %l:%M %P')
      else
        found_hours << hour.strftime('%Y-%m-%d %l:%M %P')
      end
    end

    [found_hours, missing_hours]
  end

end