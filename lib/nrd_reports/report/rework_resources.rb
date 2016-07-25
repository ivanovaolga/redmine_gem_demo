module NrdReports
  module Report
    class ReworkResources
      unloadable
      include Redmine::I18n
      include NrdReports::Settings

      attr_accessor :rows

      def initialize(releases, options = {})
        @releases = releases
        @options  = options

        create_rows
      end

      private

      def create_rows
        @rows = {}

        @releases.each do |release|
          @rows[release.id] = { name: release.name, data: {} }

          release_start = release_start_day(release)
          next unless release_start

          resources(release.id).each do |resource|
            return unless valid_dismissal_date?(resource, release_start)

            category = category_type(resource)
            @rows[release.id][:data][category] ||= []
            @rows[release.id][:data][category].push(row_data(resource, release, release_start))
          end
        end
      end

      def resources(release_id)
        quantum = Issue.fixed_version(release_id).where(tracker_id: settings[:resource_quantum_tracker])

        issues = Issue.includes(:custom_values, :resource_category, :resource_company)
          .where(
            tracker_id: settings[:resource_tracker],
            id:         quantum.pluck(:parent_id)
          )
        issues = issues.where(resource_categories_issues: { value: @options[:categories] }) if @options[:categories]
        issues = issues.where(resource_companies_issues: { value: @options[:companies] })   if @options[:companies]

        issues.order('resource_categories_issues.value', 'resource_companies_issues.value')
      end

      def row_data(resource, release, release_start)
        category = resource.resource_category.try(:value)
        company  = company_type(resource)

        familiarization      = calc_familiarization(resource, release_start)
        rework_availability  = calc_rework_availability(resource)
        availability         = calc_availability(rework_availability, familiarization)
        holidays             = calc_holidays(resource, release)
        work_days            = calc_work_days(release, category)
        availability_mh      = calc_availability_man_hour(work_days, holidays, rework_availability)
        availability_ni      = calc_availability_non_incident(availability_mh)

        {
          fio:             resource_fio(resource),
          category:        category,
          company:         company,
          familiarization: familiarization,
          availability:    availability,
          systems:         systems_availability(resource, availability),
          holidays:        holidays,
          work_days:       work_days,
          availability_mh: availability_mh,
          availability_ni: availability_ni,
          resource:        resource
        }
      end

      def release_start_day(release)
        release_task = Issue.fixed_version(release).includes(:custom_values)
          .where(
            tracker_id:    settings[:release_tracker],
            custom_values: { custom_field_id: settings[:release_start_field] }
          )
          .order('custom_values.value')
          .first

        start_day = release_task.try(:custom_field_value, settings[:release_start_field])
        Date.parse(start_day) if start_day.present?
      end

      def calc_familiarization(resource, release_start)
        admission = resource.custom_field_value(settings[:date_admission_field])
        if admission.present?
          check_date      = release_start + 2.week
          admission_date  = Date.parse(admission)
          if admission_date < check_date
            month = ((check_date - admission_date) / 30).ceil
            Competence.find_by_months(month, resource.custom_field_value(settings[:system_field])).try(:value)
          else
            0
          end
        end
      end

      def calc_rework_availability(resource)
        rework_availability = resource.custom_field_value(settings[:rework_availability_field])
        rework_availability.to_f / 100
      end

      def calc_availability(rework_availability, familiarization)
        familiarization * rework_availability unless familiarization.blank?
      end

      def systems_availability(resource, availability)
        values = {}

        resource_knowledge = SystemKnowledge.where(issue_id: resource.id)
        report_systems     = CustomField.find(settings[:system_field]).possible_values

        report_systems.each do |system|
          system_knowledge = resource_knowledge.detect { |k| k.system == system }
          if system_knowledge && availability.present?
            values[system] = (availability * system_knowledge.value / 100).round(2)
          else
            values[system] = ''
          end
        end

        values
      end

      def calc_holidays(resource, release)
        hours = 0
        release_quantum(resource, release).where(
          custom_values: { value: settings[:quantum_type_holiday] }
        ).each { |r| hours += r.custom_field_value(settings[:resource_value]).to_f }

        (hours / 8).round
      end

      def calc_work_days(release, category)
        field = case category
          when settings[:category_analytics]
            settings[:work_days_analytics_field]
          when settings[:category_dev]
            settings[:work_days_dev_field]
          when settings[:category_test]
            settings[:work_days_test_field]
          end

        days = 0
        versions = Issue.fixed_version(release).includes(:custom_values).where(tracker_id: settings[:release_tracker])
        versions.each do |r|
          days += r.custom_field_value(field).to_i
        end

        days
      end

      def calc_availability_man_hour(work_days, holidays, rework_availability)
        (work_days - holidays) * rework_availability * 8
      end

      def calc_availability_non_incident(availability_mh)
        availability_mh * 0.8
      end

      def valid_dismissal_date?(resource, release_start)
        date = resource.custom_field_value(settings[:date_dismissal_field])
        date.blank? || Date.parse(date) < release_start
      end

      def resource_fio(resource)
        c_value = resource.custom_value_for(settings[:resource_fio_field])
        c_value.custom_field.format.cast_custom_value(c_value).try(:name) if c_value
      end

      def release_quantum(resource, release)
        resource.descendants.fixed_version(release).joins(:custom_values)
          .where(
            tracker_id:       settings[:resource_quantum_tracker],
            custom_values:    { custom_field_id: settings[:quantum_type_field] }
          )
      end

      def company_type(resource)
        resource.internal_resource? ? l(:resource_internal_company) : l(:resource_externall_company)
      end

      def category_type(resource)
        category = resource.resource_category.try(:value)
        if category == settings[:category_analytics]
          :an
        elsif category == settings[:category_dev]
          :dev
        elsif category == settings[:category_test]
          :test
        else
          'empty'
        end
      end

    end
  end
end
