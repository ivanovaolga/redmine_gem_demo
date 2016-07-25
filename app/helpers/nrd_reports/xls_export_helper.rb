module NrdReports
  module XlsExportHelper
    def minor_header_style
      { sz: 9 }.merge(centered_cell_style).merge(black_border_style)
    end

    def header_style
      minor_header_style.merge(b: true)
    end

    def centered_cell_style
      { alignment: { wrap_text: true, horizontal: :center, vertical: :center } }
    end

    def black_border_style
      { border: { style: :thin, color: '00' } }
    end

    def data_row_style
      centered_cell_style.merge(black_border_style)
    end

  end
end
