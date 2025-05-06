require 'roo'
require 'csv'

# Fix misplaced trailing negative signs (e.g., "27970.00-" → "-27970.00")
def fix_trailing_negative_raw(value)
  return value.gsub(/(\d+,\d+\-)/) { |m| "-#{m[0..-2]}" } if value.is_a?(String)
  value
end

# Extract and clean transactions
def extract_credit_card_transactions(file_path)
  xlsx = Roo::Excelx.new(file_path)
  sheet = xlsx.sheet(0)
  rows = sheet.parse(headers: false)

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

    data_rows.each_with_index do |row, i|
      row_hash = Hash[header.zip(row)]
      row_hash["Notes"] = nil
      transactions << row_hash
    end
  end

  # Handle VR MONEDA ORIG rows
  cleaned_transactions = []
  transactions.each_with_index do |row, i|
    if row["Descripción"].to_s.downcase.include?("vr moneda orig")
      cleaned_transactions[-1]["Notes"] = row["Descripción"]
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

  cleaned_transactions
end

def export_to_csv(transactions, output_path)
  CSV.open(output_path, "w", col_sep: ";") do |csv|
    headers = transactions.first.keys
    csv << headers
    transactions.each do |row|
      csv << headers.map { |h| row[h] }
    end
  end
end

# Example usage
if __FILE__ == $0
  input_path = "extracto_202501_tarjeta_visa_7024.xlsx"
  output_path = "bancolombia_credit_card_cleaned.csv"

  transactions = extract_credit_card_transactions(input_path)
  export_to_csv(transactions, output_path)
  puts "✅ Exported to #{output_path}"
end