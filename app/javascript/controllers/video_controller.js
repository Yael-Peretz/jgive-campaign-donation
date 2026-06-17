import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "iframe"]

  open() {
    this.iframeTarget.src = this.iframeTarget.dataset.src
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
    this.iframeTarget.src = ""
  }

  closeBackdrop(event) {
    if (event.target === this.dialogTarget) this.close()
  }
}
