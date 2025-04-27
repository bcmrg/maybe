class BancolombiaImport < Import
  after_create :set_mappings

  def generate_rows_from_csv
    rows.destroy_all

    mapped_rows = csv_rows.map do |row|
      {
        date: row[date_col_label].to_s,
        name: row[name_col_label].to_s,
        amount: sanitize_number(row[amount_col_label]).to_s,
        currency: default_currency
      }
    end

    rows.insert_all!(mapped_rows)
  end

  def import!
    transaction do
      mappings.each(&:create_mappable!)

      rows.each do |row|
        account = mappings.accounts.mappable_for(row.account)
        category = mappings.categories.mappable_for(row.category)
        tags = row.tags_list.map { |tag| mappings.tags.mappable_for(tag) }.compact

        entry = account.entries.build \
          date: row.date_iso,
          amount: row.signed_amount,
          name: row.name,
          currency: row.currency,
          notes: row.notes,
          entryable: Transaction.new(category: category, tags: tags),
          import: self

        entry.save!
      end
    end
  end

  def mapping_steps
    [ Import::CategoryMapping, Import::TagMapping, Import::AccountMapping ]
  end

  def required_column_keys
    %i[date amount]
  end

  def column_keys
    %i[date amount name]
  end

  def csv_template
    template = <<-CSV
      FECHA;DESCRIPCIÓN;VALOR
      01/01/2024;ABONO INTERESES AHORROS;26.13
      01/01/2024;PAGO AUTOM TC VISA;-40000.00
    CSV

    CSV.parse(template, headers: true, col_sep: ";")
  end

  private

  def set_mappings
    self.signage_convention = "inflows_positive" # Positive values in CSV are credits
    self.date_col_label = "FECHA"
    self.date_format = "%d/%m/%Y"
    self.name_col_label = "DESCRIPCIÓN"
    self.amount_col_label = "VALOR"
    self.col_sep = ";"
    self.number_format = "1,234.56" # Uses commas for thousands, dot for decimals

    save!
  end

  def default_currency
    "COP" # Colombian Peso is the default currency for Bancolombia
  end
end 