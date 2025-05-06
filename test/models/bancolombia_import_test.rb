require "test_helper"

class BancolombiaImportTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup
    @family = families(:one)
    @account = accounts(:checking)
    @import = imports(:bancolombia)
  end

  test "sets correct mappings on create" do
    import = BancolombiaImport::Savings.create!(family: @family)

    assert_equal "inflows_positive", import.signage_convention
    assert_equal "FECHA", import.date_col_label
    assert_equal "%d/%m/%Y", import.date_format
    assert_equal "DESCRIPCIÓN", import.name_col_label
    assert_equal "VALOR", import.amount_col_label
    assert_equal ";", import.col_sep
    assert_equal "1,234.56", import.number_format
  end

  test "generates rows from valid CSV" do
    csv_content = <<~CSV
      FECHA;DESCRIPCIÓN;VALOR
      01/01/2024;ABONO INTERESES AHORROS;26.13
      01/01/2024;PAGO AUTOM TC VISA;-40000.00
    CSV

    import = BancolombiaImport::Savings.create!(family: @family, raw_file_str: csv_content)
    import.generate_rows_from_csv

    assert_equal 2, import.rows.count

    row = import.rows.first
    assert_equal "2024-01-01", row.date_iso
    assert_equal "ABONO INTERESES AHORROS", row.name
    assert_equal "26.13", row.amount
    assert_equal "COP", row.currency

    row = import.rows.last
    assert_equal "2024-01-01", row.date_iso
    assert_equal "PAGO AUTOM TC VISA", row.name
    assert_equal "-40000.00", row.amount
    assert_equal "COP", row.currency
  end

  test "imports rows and creates entries" do
    csv_content = <<~CSV
      FECHA;DESCRIPCIÓN;VALOR
      01/01/2024;ABONO INTERESES AHORROS;26.13
    CSV

    import = BancolombiaImport::Savings.create!(family: @family, raw_file_str: csv_content)
    import.generate_rows_from_csv

    # Create account mapping
    Import::AccountMapping.create!(
      import: import,
      mappable: @account,
      pattern: ".*"
    )

    assert_difference "@account.entries.count" do
      import.import!
    end

    entry = @account.entries.last
    assert_equal Date.new(2024, 1, 1), entry.date
    assert_equal 26.13, entry.amount
    assert_equal "COP", entry.currency
    assert_equal "ABONO INTERESES AHORROS", entry.name
    assert_instance_of Transaction, entry.entryable
  end

  test "handles numbers with thousands separators" do
    csv_content = <<~CSV
      FECHA;DESCRIPCIÓN;VALOR
      01/01/2024;LARGE DEPOSIT;1,234,567.89
    CSV

    import = BancolombiaImport::Savings.create!(family: @family, raw_file_str: csv_content)
    import.generate_rows_from_csv

    row = import.rows.first
    assert_equal "1234567.89", row.amount
  end

  test "validates required columns" do
    csv_content = <<~CSV
      DESCRIPCIÓN;VALOR
      ABONO INTERESES AHORROS;26.13
    CSV

    import = BancolombiaImport::Savings.create(family: @family, raw_file_str: csv_content)
    refute import.valid?
    assert_includes import.errors.full_messages, "Required columns missing: date"
  end

  test "imports transactions successfully" do
    @import.generate_rows_from_csv
    @import.save!

    assert_difference -> { Entry.count } => @import.rows.count,
                    -> { Transaction.count } => @import.rows.count do
      @import.publish
    end

    assert_equal "complete", @import.status
  end
end 