class Order < ActiveRecord::Base
  belongs_to :crawler
  enum status: [:created, :enqueued, :processed, :failed]
  validates_presence_of :wordpress_reference, :status
  validates_uniqueness_of :aliexpress_number, unless: Proc.new { |o| o.aliexpress_number.nil? }

  scope :tracked, -> { where(tracked: true) }
  scope :untracked, -> { where(tracked: false) }

  def mark_as_tracked(tracking_number)
    return true if self.tracked

    self.tracking_number = tracking_number
    self.tracked = true
    self.save
    notify_wordpress
  end

  def notify_wordpress
    self.crawler.wordpress.update_tracking_number_note self.wordpress_reference, self.tracking_number
  end

  def metadata
    crawler.wordpress.get_order wordpress_reference
  end
end
