# Rails wraps invalid form fields in a <div class="field_with_errors">, which breaks
# sibling-based CSS selectors (Tailwind's peer-checked:) used throughout the donation form.
# Errors are already surfaced via a full message list above the form, so the wrapper adds
# no information — just disable it.
ActionView::Base.field_error_proc = proc { |html_tag, _instance| html_tag }
