class GenerateOutdatedDaysDataWorker
  include Sidekiq::Worker

  def perform
    @outdated_dates = OutdatedDatesForMarginReport.new.run

    @outdated_dates.each do |date|
      HourlyMarginProcess.run_all(start_dd=date, end_dd=date)
    end

    DeriveMarginDataProcessGenerateWorker.perform_async if run_derive_process?
  end

  private

  def run_derive_process?
    @outdated_dates.any? || outdated_margin_by_date
  end

  def outdated_margin_by_date
    last_reconciliation = HourlyMarginDate.select(:created_at).where(event: 'calculate_m2').order('created_at desc').first
    MarginByDate.run_at < last_reconciliation.created_at if last_reconciliation.present?
  end
end