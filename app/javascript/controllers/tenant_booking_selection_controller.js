import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "cell",
    "bookButton",
    "form",
    "availabilityInput"
  ]

  connect() {
    this.selectedCell = null
  }

  selectCell(event) {
    const cell = event.currentTarget

    // Don't allow selection of disabled cells
    if (cell.classList.contains('week-calendar-hour-cell-disabled')) {
      return
    }

    // Clear previous selection
    if (this.selectedCell) {
      this.selectedCell.classList.remove('week-calendar-hour-cell-selected')
    }

    // Set new selection
    this.selectedCell = cell
    cell.classList.add('week-calendar-hour-cell-selected')

    // Enable book button and update hidden input
    if (this.hasBookButtonTarget) {
      this.bookButtonTarget.disabled = false
    }

    if (this.hasAvailabilityInputTarget) {
      this.availabilityInputTarget.value = cell.dataset.availabilityId
    }
  }

  makeBooking() {
    if (!this.selectedCell) return

    // Submit form
    this.formTarget.requestSubmit()
  }
}
