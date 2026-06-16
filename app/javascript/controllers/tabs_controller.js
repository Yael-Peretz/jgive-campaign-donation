import { Controller } from "@hotwired/stimulus"

// Pure client-side show/hide — every panel is already server-rendered, so there's
// no extra round-trip. The first tab/panel pair is active by default in the markup
// itself, so the page is correct even before this controller connects.
export default class extends Controller {
  static targets = ["tab", "panel"]
  static classes = ["active", "inactive"]

  select(event) {
    const name = event.params.name

    this.tabTargets.forEach((tab) => {
      const isActive = tab.dataset.name === name

      tab.classList.remove(...(isActive ? this.inactiveClasses : this.activeClasses))
      tab.classList.add(...(isActive ? this.activeClasses : this.inactiveClasses))
      tab.setAttribute("aria-selected", isActive)
    })

    this.panelTargets.forEach((panel) => {
      panel.classList.toggle("hidden", panel.dataset.name !== name)
    })
  }
}
