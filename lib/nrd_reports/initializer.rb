# encoding: utf-8

module NrdReports
  class Initializer
    unloadable

    include Redmine::I18n
    I18n.locale = 'ru-RU'

    CONFIG_DIR  = 'nrd_reports/config'
    LOG_DIR     = 'log/nrd_reports.log'

    def initialize
      @logger = Logger.new(File.open(Rails.root.join(LOG_DIR), 'a', sync: true))
      @logger.formatter = Logger::Formatter.new
    end

    def init
      @logger.info "Инициализация начата"

      Setting.plugin_nrd_reports ||= {}

      init_default_settings
      init_auto_estimations
      init_resources_fields
      init_release_calendar

      @logger.info "Инициализация закончена\n"
    end

    private

    def init_default_settings
      defaults = YAML.load_file(File.join(Redmine::Plugin.directory, CONFIG_DIR, 'default_settings.yml'))
      update_settings(defaults)
    end

    def init_auto_estimations
      tracker = Tracker.find_by_id(Setting.plugin_nrd_reports[:estimation_tracker])
      tracker_ids = tracker ? tracker.id : []
      project_ids = tracker ? tracker.project_ids : []

      params = { field_format: 'bool', default_value: 0, tracker_ids: tracker_ids, project_ids: project_ids }
      fields = [
        { name: l(:flag_dev_estimation_field),    setting: :req_dev_estimation_field },
        { name: l(:flag_tester_estimation_field), setting: :req_tester_estimation_field },
      ]

      fields.each do |f|
        field = CustomField.new_subclass_instance('IssueCustomField', params)
        field.name = f[:name]

        if field.save
          update_settings(f[:setting] => field.id)
        end
      end
    end

    def init_resources_fields
      new_settings = {}
      tracker = Tracker.find(Setting.plugin_nrd_reports[:resource_tracker])

      field = create_field(tracker, l(:field_date_admission), 'date', false, false)
      new_settings[:date_admission_field] = field.try(:id)

      field = create_field(tracker, l(:field_date_dismissal), 'date', false, false)
      new_settings[:date_dismissal_field] = field.try(:id)

      field = create_field(tracker, l(:field_fio), 'user', true, false)
      new_settings[:resource_fio_field] = field.try(:id)

      create_field(tracker, l(:field_date_privilege_end), 'date', false, false)
      create_field(tracker, l(:field_department), 'list', false, true)
      create_field(tracker, l(:field_administration), 'list', false, true)
      create_field(tracker, l(:field_section), 'list', false, true)
      create_field(tracker, l(:field_appointment), 'list', false, true)
      create_field(tracker, l(:field_curator), 'user', false, true)
      field = create_field(tracker, l(:field_rework_availability), 'int', false, false, regexp: '^[0-9]{1,3}$')
      new_settings[:rework_availability_field] = field.try(:id)

      categories = ['Аналитик', 'Разработчик', 'Тестировщик']
      field = create_field(tracker, l(:field_category), 'list', false, false, values: categories)
      new_settings[:resource_category_field] = field.try(:id)

      company_field = CustomField.find_by_name_and_type(l(:field_company), 'IssueCustomField')
      if company_field
        company_field.update_attribute(:is_required, true)
        @logger.info "Поле '#{company_field.name}' установлено как обязательное для заполнения"
      else
        create_field(tracker, l(:field_company), 'list', true, false)
      end

      update_settings(new_settings)
    end

    def init_release_calendar
      new_settings = {}

      tracker = Tracker.find(Setting.plugin_nrd_reports[:release_tracker])

      field = create_field(tracker, l(:field_release_start), 'date', false, false)
      new_settings[:release_start_field] = field.try(:id)
      new_settings[:release_analytics_start_field] = field.try(:id)

      field = create_field(tracker, l(:field_work_days_analytics), 'int', false, false)
      new_settings[:work_days_analytics_field] = field.try(:id)

      field = create_field(tracker, l(:field_work_days_dev), 'int', false, false)
      new_settings[:work_days_dev_field] = field.try(:id)

      field = create_field(tracker, l(:field_work_days_test), 'int', false, false)
      new_settings[:work_days_test_field] = field.try(:id)

      field = create_field(tracker, l(:field_work_days_btest), 'int', false, false)
      new_settings[:work_days_btest_field] = field.try(:id)

      update_settings(new_settings)
    end

    def create_field(tracker, name, field_format, is_required, is_nrd_required, options = {})
      common_params = { tracker_ids: [tracker.id], project_ids: tracker.project_ids }

      field = CustomField.find_by_name_and_type(name, 'IssueCustomField')
      if field
        @logger.error "Поле '#{field.name}' не добавлено. Причины: такое поле уже существует"
        return field
      end

      field = CustomField.new_subclass_instance('IssueCustomField', common_params.merge(
        name:             name,
        field_format:     field_format,
        is_required:      is_required,
        is_nrd_required:  is_nrd_required
      ))
      field.regexp          = options[:regexp]      if options[:regexp]
      field.possible_values = [l(:possible_value)]  if field_format == 'list'
      field.possible_values = options[:values]      if options[:values]

      if field.save
        @logger.info "Поле '#{field.name}' успешно добавлено"
      else
        @logger.error "Поле '#{field.name}' не добавлено. Причины: #{field.errors.full_messages.join(', ')}"
      end

      field
    end

    def update_settings(new_settings)
      Setting.plugin_nrd_reports = new_settings.with_indifferent_access.merge(Setting.plugin_nrd_reports)
    end
  end
end
