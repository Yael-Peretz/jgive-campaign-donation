import { Controller } from "@hotwired/stimulus"

// Wraps the native <dialog> element, so focus trapping, Esc-to-close, and the
// backdrop come from the browser for free instead of a hand-rolled JS modal.
export default class extends Controller {
  static targets = ["dialog"]

  open() {
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
  }

  closeBackdrop(event) {
    if (event.target === this.dialogTarget) this.close()
  }
}
