class CrawlerLog < ActiveRecord::Base
  belongs_to :crawler

  def add_processed(message)
    self.add_message(message)
    self.processed+=1
  end

  def add_message(message)
    if self.message.nil?
      self.update(message: "#{message}|")
    else
      self.message.concat("#{message}|")
    end
  end

  def get_message
    self.message.split("|")
  end
end
