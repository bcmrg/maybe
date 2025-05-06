require 'roo'
require 'csv'
require 'zip'

module Utilities
  class ExcelConversionService
    class Error < StandardError; end

    def self.convert_bancolombia_savings(file)
      new.convert_bancolombia_savings(file)
    end

    def self.convert_bancolombia_credit_card(file)
      new.convert_bancolombia_credit_card(file)
    end

    def convert_bancolombia_savings(file)
      # Ensure file is present
      raise Error, "No file provided" if file.nil?

      # Create a temporary file to store the Excel file
      temp_file = Tempfile.new(['bancolombia_savings', '.xlsx'])
      temp_file.binmode
      temp_file.write(file.read)
      temp_file.close

      begin
        # Repair Excel file if needed
        repaired_path = repair_xlsx_styles(temp_file.path)
        
        # Extract transactions
        transactions = extract_savings_transactions(repaired_path)
        
        # Convert to CSV
        csv_data = generate_csv(transactions)
        
        # Return the CSV data
        csv_data
      ensure
        # Clean up temporary files
        temp_file.unlink
        File.unlink(repaired_path) if repaired_path != temp_file.path && File.exist?(repaired_path)
      end
    end

    def convert_bancolombia_credit_card(file)
      Rails.logger.info "Starting bancolombia credit card conversion"
      
      # Ensure file is present
      raise Error, "No file provided" if file.nil?
      Rails.logger.info "File received: #{file.original_filename}"

      # Create a temporary file
      temp_file = Tempfile.new(['bancolombia_credit_card', '.xlsx'])
      temp_file.binmode
      temp_file.write(file.read)
      temp_file.close
      Rails.logger.info "Temporary file created at: #{temp_file.path}"

      begin
        # Repair Excel file if needed
        Rails.logger.info "Starting Excel file repair"
        repaired_path = repair_xlsx_styles(temp_file.path)
        Rails.logger.info "Excel file repaired, new path: #{repaired_path}"
        
        # Extract transactions
        Rails.logger.info "Starting transaction extraction"
        transactions = extract_credit_card_transactions(repaired_path)
        Rails.logger.info "Extracted #{transactions.size} transactions"
        
        # Convert to CSV
        Rails.logger.info "Converting to CSV format"
        csv_data = generate_csv(transactions)
        Rails.logger.info "CSV conversion completed"
        
        csv_data
      rescue StandardError => e
        Rails.logger.error "Credit card conversion error: #{e.class} - #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        raise
      ensure
        Rails.logger.info "Cleaning up temporary files"
        temp_file.unlink
        File.unlink(repaired_path) if repaired_path != temp_file.path && File.exist?(repaired_path)
      end
    end

    private

    def generate_csv(transactions)
      CSV.generate(col_sep: ";") do |csv|
        # Add headers
        csv << transactions.first.keys if transactions.any?
        # Add data rows
        transactions.each do |transaction|
          csv << transaction.values
        end
      end
    end

    def fix_missing_leading_zero(value)
      return value.gsub(/(?<!\d)\.(\d+)/, '0.\1') if value.is_a?(String)
      value
    end

    def append_year_to_date(value, year = Date.current.year.to_s)
      return "#{value}/#{year}" if value.is_a?(String) && value.count("/") == 1
      value
    end

    def extract_savings_transactions(file_path)
      puts "Starting extraction..."

      xlsx = Roo::Excelx.new(file_path)  
      sheet = xlsx.sheet(0)
      
      rows = []
      sheet.each do |row|
        rows << row    
      end

      puts "Rows extracted: #{rows.size}"


      start_indices = rows.each_index.select { |i| rows[i].join.downcase.include?("movimientos:") }
      end_indices = rows.each_index.select { |i| rows[i].join.downcase.include?("información cliente:") || rows[i].join.downcase.include?("fin estado de cuenta") }
      
      transactions = []

      start_indices.each do |start_idx|
        end_idx = end_indices.find { |ei| ei > start_idx }
        next unless end_idx

        header = rows[start_idx + 1]
        data_rows = rows[(start_idx + 2)...end_idx].reject { |row| row.compact.empty? }

        data_rows.each do |row|
          row_hash = Hash[header.zip(row)]
          row_hash["FECHA"] = append_year_to_date(row_hash["FECHA"])
          row_hash.each { |k, v| row_hash[k] = fix_missing_leading_zero(v.to_s) if v }
          transactions << row_hash
        end
      end

      puts "Transactions extracted: #{transactions.size}"
      transactions
    end

    def repair_xlsx_styles(xlsx_path)
      repaired_path = xlsx_path.sub(/\.xlsx$/, '_repaired.xlsx')
      

      has_styles = false

      # Read existing xlsx
      Zip::File.open(xlsx_path) do |zip_file|
        has_styles = zip_file.find_entry('xl/styles.xml')
      end

      if has_styles
        puts "✅ styles.xml found. No repair needed."
        return xlsx_path
      end

      puts "⚡ styles.xml missing. Repairing..."

      # Copy and patch the zip
      Zip::File.open(xlsx_path) do |zip_file|
        Zip::File.open(repaired_path, Zip::File::CREATE) do |new_zip|
          # Copy all original entries
          zip_file.each do |entry|
            new_zip.get_output_stream(entry.name) do |out|
              out.write(entry.get_input_stream.read)
            end
          end

          # Add dummy styles.xml
          new_zip.get_output_stream("xl/styles.xml") do |out|
            out.write <<~XML
              <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
              <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
              </styleSheet>
            XML
          end
        end
      end

      puts "✅ Repair done → #{repaired_path}"
      repaired_path
    end

    def fix_trailing_negative_raw(value)
      return value.gsub(/(\d+,\d+\-)/) { |m| "-#{m[0..-2]}" } if value.is_a?(String)
      value
    end

    def extract_credit_card_transactions(file_path)
      puts "Starting extraction..."

      xlsx = Roo::Excelx.new(file_path)  
      sheet = xlsx.sheet(0)
      
      rows = []
      sheet.each do |row|
        rows << row    
      end

      puts "Rows extracted: #{rows.size}"

      start_indices = rows.each_index.select { |i| rows[i].join.downcase.include?("titulos de transacciones") }
      transactions = []

      start_indices.each do |start_idx|
        header = rows[start_idx + 1]
        data_rows = []
        idx = start_idx + 2

        while idx < rows.size && !rows[idx].compact.empty?
          data_rows << rows[idx]
          idx += 1
        end

        data_rows.each do |row|
          row_hash = Hash[header.zip(row)]
          row_hash["Notes"] = nil
          transactions << row_hash
        end
      end

      # Handle VR MONEDA ORIG rows
      cleaned_transactions = []
      transactions.each_with_index do |row, i|
        if row["Descripción"].to_s.downcase.include?("vr moneda orig")
          cleaned_transactions[-1]["Notes"] = row["Descripción"] if cleaned_transactions.any?
        else
          cleaned_transactions << row
        end
      end

      # Fix trailing negatives in specific columns
      ["Valor Original", "Cargos y Abonos"].each do |col|
        cleaned_transactions.each do |row|
          if row[col]
            row[col] = fix_trailing_negative_raw(row[col].to_s)
          end
        end
      end

      puts "Transactions extracted: #{cleaned_transactions.size}"
      cleaned_transactions
    end
  end
end 