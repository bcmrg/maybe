module Utilities
  class ExcelConversionsController < ApplicationController
    layout "imports"

    def index
    end

    def convert
      file = params[:excel_file]
      file_type = params[:file_type]

      unless file && file_type
        render json: { error: "File and file type are required" }, status: :unprocessable_entity
        return
      end

      begin
        case file_type
        when "bancolombia_savings"
          csv_data = Utilities::ExcelConversionService.convert_bancolombia_savings(file)
          send_data csv_data,
                    filename: "bancolombia_savings_#{Time.current.strftime('%Y%m%d_%H%M%S')}.csv",
                    type: "text/csv",
                    disposition: "attachment"
        when "bancolombia_credit_card"
          csv_data = Utilities::ExcelConversionService.convert_bancolombia_credit_card(file)
          send_data csv_data,
                    filename: "bancolombia_credit_card_#{Time.current.strftime('%Y%m%d_%H%M%S')}.csv",
                    type: "text/csv",
                    disposition: "attachment"
        else
          render json: { error: "Unsupported file type" }, status: :unprocessable_entity
        end
      rescue Utilities::ExcelConversionService::Error => e
        render json: { error: e.message }, status: :unprocessable_entity
      rescue StandardError => e
        Rails.logger.error "Excel conversion error: #{e.message}\n#{e.backtrace.join("\n")}"
        render json: { error: "An error occurred while converting the file" }, status: :internal_server_error
      end
    end
  end
end 