namespace :crawler do
  desc "Runs Crawler.rb"
  task run: :environment do
    # When run straight from command line, @crawlers won't be set so
    @crawlers ||= Crawler.where(enabled: true)

    @crawlers.each do |crawler|
      amount = crawler.max_amount_of_orders
      page = crawler.orders_starting_from_page
      orders = crawler.wordpress.get_orders(amount, page)
      crawler.run orders
    end
  end

  desc "Runs every 10 minutes"
  task tenminutes: :environment do
    @crawlers = Crawler.where(schedule: 'ten_minutes',enabled: true)
    unless @crawlers.nil?
      Rake::Task['crawler:run'].execute
    end
  end

  desc "Runs every hour"
  task hourly: :environment do
    @crawlers = Crawler.where(schedule: 'hourly',enabled: true)
    unless @crawlers.nil?
      Rake::Task['crawler:run'].execute
    end
  end

  desc "Runs every day"
  task daily: :environment do
    @crawlers = Crawler.where(schedule: 'daily',enabled: true)
    unless @crawlers.nil?
      Rake::Task['crawler:run'].execute
    end
  end
end
