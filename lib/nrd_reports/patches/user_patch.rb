module NrdReports
  module Patches
    module UserPatch
      def self.included(base)
        base.class_eval do
          unloadable
          has_many :time_entries, :dependent => :destroy
        end
      end
    end
  end
end

unless User.included_modules.include?(NrdReports::Patches::UserPatch)
  User.send(:include, NrdReports::Patches::UserPatch)
end