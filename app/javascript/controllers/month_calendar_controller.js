import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["day"]

  connect() {
    this.highlightCurrentWeek()
  }

  highlightCurrentWeek() {
    // Group days by week
    const weekGroups = new Map()

    this.dayTargets.forEach(day => {
      const weekStart = day.dataset.weekStart
      if (!weekGroups.has(weekStart)) {
        weekGroups.set(weekStart, [])
      }
      weekGroups.get(weekStart).push(day)
    })

    // Add hover behavior for each week
    weekGroups.forEach((days, weekStart) => {
      days.forEach(day => {
        day.addEventListener('mouseenter', () => this.highlightWeek(days))
        day.addEventListener('mouseleave', () => this.unhighlightWeek(days))
      })
    })
  }

  highlightWeek(days) {
    days.forEach(day => {
      if (!day.classList.contains('month-calendar-day-selected-week')) {
        day.classList.add('bg-blue-50')
      }
    })
  }

  unhighlightWeek(days) {
    days.forEach(day => {
      if (!day.classList.contains('month-calendar-day-selected-week')) {
        day.classList.remove('bg-blue-50')
      }
    })
  }
}
