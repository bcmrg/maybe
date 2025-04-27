class BancolombiaCreditCardImport < Import
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
      Número de Autorización;Fecha de Transacción;Descripción;Valor Original;Tasa Pactada;Tasa EA Facturada;Cargos y Abonos;Saldo a Diferir;Cuotas;Notes
      329462;30/01/2025;POSTMAN BASIC ANNUAL;178,969.97;1.8646;24.8186;4,971.39;173,998.58;1/36;VR MONEDA ORIG 42.0 US
      000000;30/01/2025;CUOTA DE MANEJO;40,990.00;;;40,990.00;0.00;;
      107220;29/01/2025;RAPPI*RAPPI COLOMBIA;58,900.00;0.0000;00.0000;58,900.00;0.00;1/1;
    CSV

    CSV.parse(template, headers: true, col_sep: ";")
  end

  private

  def set_mappings
    self.signage_convention = "inflows_negative" # Negative values in CSV are credits
    self.date_col_label = "Fecha de Transacción"
    self.date_format = "%d/%m/%Y"
    self.name_col_label = "Descripción"
    self.amount_col_label = "Valor Original"
    self.col_sep = ";"
    self.number_format = "1,234.56" # Uses commas for thousands, dot for decimals

    save!
  end

  def default_currency
    "COP" # Colombian Peso is the default currency for Bancolombia
  end
end 