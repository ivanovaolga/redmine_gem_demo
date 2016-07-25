# encoding: utf-8

namespace :nrd_reports do
  namespace :resources do
    desc 'Initialization'
    task init: :environment do
      NrdReports::Initializer.new.init
    end
  end
end
