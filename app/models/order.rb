class Order < ActiveRecord::Base
  belongs_to :crawler

  scope :tracked, -> { where(tracked: true) }
  scope :untracked, -> { where(tracked: false) }

  def mark_as_tracked(tracking_number)
    self.tracking_number = tracking_number
    self.tracked = true
    self.save
  end

  def self.track(params={})
    create params
  end

  def self.track!(params={})
    create! params
  end
end
