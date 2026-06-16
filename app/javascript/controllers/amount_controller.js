import { Controller } from "@hotwired/stimulus"

// Keeps the preset amount radios and the custom amount field mutually exclusive.
// Both share name="donation[amount]"; disabling the inactive one is what keeps
// the form from submitting two values for the same param.
export default class extends Controller {
  static targets = ["preset", "custom"]

  selectPreset() {
    this.customTarget.disabled = true
    this.customTarget.value = ""
  }

  selectCustom() {
    this.presetTargets.forEach((preset) => { preset.checked = false })
    this.customTarget.disabled = false
  }
}
