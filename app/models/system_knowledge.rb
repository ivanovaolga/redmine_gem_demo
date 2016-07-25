class SystemKnowledge < ActiveRecord::Base
  validates_presence_of     :system, :value
  validates_numericality_of :value, only_integer: true, greater_than: 0, less_than_or_equal_to: 100

  belongs_to :issue

end
