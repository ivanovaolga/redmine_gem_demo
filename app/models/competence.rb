class Competence < ActiveRecord::Base
  validates_presence_of     :month, :system, :value
  validates_uniqueness_of   :month, scope: :system
  validates_numericality_of :month, only_integer: true, greater_than: 0
  validates_numericality_of :value, greater_than: 0

  class << self
    def find_by_months(work_month, system)
      all = self.where(system: system).order('month desc')
      (all.detect { |c| c.month <= work_month } || all.last) if all
    end
  end
end
