import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="bill-form"
export default class extends Controller {
  static targets = ["billTypeSelect", "debtAccountField"];

  connect() {
    this.toggleDebtAccountField();
  }

  toggleDebtAccountField() {
    if (this.billTypeSelectTarget.value === "debt") {
      this.debtAccountFieldTarget.style.display = "block";
    } else {
      this.debtAccountFieldTarget.style.display = "none";
    }
  }
} 