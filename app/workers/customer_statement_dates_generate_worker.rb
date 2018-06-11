class CustomerStatementDatesGenerateWorker
  include Sidekiq::Worker

  def perform(start_date, end_date)
    CustomerStatement.generate_customers_data(start_date, end_date)
  end
end
