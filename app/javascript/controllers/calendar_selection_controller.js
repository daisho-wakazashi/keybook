import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "cell",
    "saveButton",
    "selectionCount",
    "form",
    "availabilitiesInput"
  ]

  connect() {
    this.selecting = false
    this.selectedCells = new Set()
    this.startCell = null
    this.currentSelection = []

    // Add mouseup listener to document to handle drag end
    this.handleMouseUp = this.endSelection.bind(this)
    document.addEventListener('mouseup', this.handleMouseUp)

    // Prevent text selection during drag
    this.element.addEventListener('selectstart', (e) => {
      if (this.selecting) {
        e.preventDefault()
      }
    })
  }

  disconnect() {
    document.removeEventListener('mouseup', this.handleMouseUp)
  }

  startSelection(event) {
    event.preventDefault()
    this.selecting = true
    this.startCell = event.currentTarget
    this.currentSelection = []

    // Clear previous temporary selection visual
    this.cellTargets.forEach(cell => {
      cell.classList.remove('week-calendar-hour-cell-selecting')
    })

    // Add selecting class to start cell
    this.startCell.classList.add('week-calendar-hour-cell-selecting')
    this.currentSelection.push(this.startCell)
  }

  updateSelection(event) {
    if (!this.selecting) return

    const currentCell = event.currentTarget

    // Get all cells in the rectangular selection area (across days and hours)
    const cells = this.getCellsInRange(this.startCell, currentCell)

    // Clear previous temporary selection visual
    this.cellTargets.forEach(cell => {
      cell.classList.remove('week-calendar-hour-cell-selecting')
    })

    // Add selecting class to cells in range
    this.currentSelection = cells
    cells.forEach(cell => {
      cell.classList.add('week-calendar-hour-cell-selecting')
    })
  }

  endSelection() {
    if (!this.selecting) return

    this.selecting = false

    // Move selecting cells to selected
    this.currentSelection.forEach(cell => {
      this.selectedCells.add(cell)
      cell.classList.remove('week-calendar-hour-cell-selecting')
      cell.classList.add('week-calendar-hour-cell-selected')
    })

    this.updateSelectionInfo()
    this.currentSelection = []
  }

  getCellsInRange(startCell, endCell) {
    const startDate = startCell.dataset.date
    const endDate = endCell.dataset.date
    const startHour = parseInt(startCell.dataset.hour)
    const endHour = parseInt(endCell.dataset.hour)

    const minDate = startDate <= endDate ? startDate : endDate
    const maxDate = startDate <= endDate ? endDate : startDate
    const minHour = Math.min(startHour, endHour)
    const maxHour = Math.max(startHour, endHour)

    // Select all cells within the rectangular range (across days and hours)
    return this.cellTargets.filter(cell => {
      const cellDate = cell.dataset.date
      const cellHour = parseInt(cell.dataset.hour)

      return cellDate >= minDate && cellDate <= maxDate &&
             cellHour >= minHour && cellHour <= maxHour
    })
  }

  clearSelection() {
    this.selectedCells.forEach(cell => {
      cell.classList.remove('week-calendar-hour-cell-selected')
    })
    this.selectedCells.clear()
    this.updateSelectionInfo()
  }

  updateSelectionInfo() {
    const count = this.selectedCells.size
    this.selectionCountTarget.textContent = count

    // Enable/disable save button
    if (this.hasSaveButtonTarget) {
      this.saveButtonTarget.disabled = count === 0
    }
  }

  saveSelection() {
    if (this.selectedCells.size === 0) return

    // Collect all selected cell datetimes as individual elements
    const selectedDatetimes = Array.from(this.selectedCells).map(cell => cell.dataset.datetime)

    // Set the datetimes as JSON in the hidden input
    this.availabilitiesInputTarget.value = JSON.stringify(selectedDatetimes)

    // Submit form
    this.formTarget.requestSubmit()
  }
}
