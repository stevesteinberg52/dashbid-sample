class HealthCheckWorker

  class TdAsEvents
    include Sidekiq::Worker

    def perform
      found, missing = HealthCheck.td_as_events_job(48)
      HealthCheckMailer.td_as_events(missing).deliver! if missing.any?
    end
  end

  class TdWfEvents
    include Sidekiq::Worker

    def perform
      found, missing = HealthCheck.td_wf_events_job(48)
      HealthCheckMailer.td_wf_events(missing).deliver! if missing.any?
    end
  end

end
