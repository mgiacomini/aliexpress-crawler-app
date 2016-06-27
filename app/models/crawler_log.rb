class CrawlerLog < ActiveRecord::Base
  belongs_to :crawler

  def add_processed(message)
    self.add_message(message)
    self.update(processed: self.processed+=1)
  end

  def add_message(message)
    self.message.concat("#{message}|")
    self.save!
  end

  def get_message
    self.message.split("|")
  end
end
