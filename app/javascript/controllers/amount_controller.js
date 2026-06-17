import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["preset", "custom", "total", "comment", "commentField"]

  connect() {
    this.updateTotal()
  }

  selectPreset() {
    this.customTarget.disabled = true
    this.customTarget.value = ""
    this.updateTotal()
  }

  selectCustom() {
    this.presetTargets.forEach((preset) => { preset.checked = false })
    this.customTarget.disabled = false
    this.customTarget.focus()
    this.updateTotal()
  }

  updateTotal() {
    if (!this.hasTotalTarget) return
    const checked = this.presetTargets.find(p => p.checked)
    const value = checked ? checked.value : (this.customTarget.value || "0")
    this.totalTarget.textContent = `₪${Number(value).toLocaleString()}`
  }

  toggleComment() {
    this.commentFieldTarget.classList.toggle("hidden")
  }
}
