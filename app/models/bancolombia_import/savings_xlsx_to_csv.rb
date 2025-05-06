require 'roo'
require 'csv'
require 'zip'


def fix_missing_leading_zero(value)
  return value.gsub(/(?<!\d)\.(\d+)/, '0.\1') if value.is_a?(String)
  value
end

def append_year_to_date(value, year = '2025')
  return "#{value}/#{year}" if value.is_a?(String) && value.count("/") == 1
  value
end

def extract_savings_transactions(file_path)
  xlsx = Roo::Excelx.new(file_path)  
  sheet = xlsx.sheet(0)

  rows = []
  sheet.each do |row|
    rows << row    
  end

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

  transactions
end

def export_to_csv(transactions, output_path)
  CSV.open(output_path, "w", col_sep: ";") do |csv|
    headers = transactions.first.keys
    csv << headers
    transactions.each { |row| csv << headers.map { |h| row[h] } }
  end
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


# Example usage
if __FILE__ == $0 
  puts "🚀 Script started..."
  input_path = File.expand_path("../../../../test/fixtures/files/extracto_202503_cuenta_de_ahorros_4554.xlsx", __FILE__)
  output_path = "savings_transactions_cleaned.csv"
  repaired_path = repair_xlsx_styles(input_path)
  puts "repaired_path: #{repaired_path}"
  transactions = extract_savings_transactions(repaired_path)  
  export_to_csv(transactions, output_path)
  puts "✅ Exported to #{output_path}"
end