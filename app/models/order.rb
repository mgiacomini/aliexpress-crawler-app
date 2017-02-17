class Order < ActiveRecord::Base
  belongs_to :crawler
  validates_uniqueness_of :aliexpress_number

  scope :tracked, -> { where(tracked: true) }
  scope :untracked, -> { where(tracked: false) }

  def mark_as_tracked(tracking_number)
    self.tracking_number = tracking_number
    self.tracked = true
    self.save

    notify_wordpress
  end

  def self.track(params={})
    create params
  end

  def self.track!(params={})
    create! params
  end

  def notify_wordpress
    self.crawler.wordpress.update_tracking_number_note self.wordpress_reference, self.tracking_number
  end
end
