// Three-state theme toggle: system -> light -> dark -> system. Mirrors the
// app's AppThemeMode (see presentation/providers/theme_mode_providers.dart)
// for a consistent choice across web and app, per the user's request.
//
// The attribute this sets (data-theme on <html>) is applied *before* this
// file loads, by a small blocking inline script in <head> — see
// index.html/privacy.html/terms.html. That's what avoids a flash of the
// wrong theme on load; this file only handles the button afterwards.
(function () {
  "use strict";

  var STORAGE_KEY = "theme-preference";
  var root = document.documentElement;

  var ICONS = {
    system:
      '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="3" y="4" width="18" height="13" rx="1.5"></rect><path d="M8 21h8M12 17v4"></path></svg>',
    light:
      '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="4.5"></circle><path d="M12 2.5v2.5M12 19v2.5M4.6 4.6l1.8 1.8M17.6 17.6l1.8 1.8M2.5 12h2.5M19 12h2.5M4.6 19.4l1.8-1.8M17.6 6.4l1.8-1.8"></path></svg>',
    dark: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20 14.5A8.5 8.5 0 1 1 9.5 4a6.5 6.5 0 0 0 10.5 10.5Z"></path></svg>',
  };

  var LABELS = {
    system: "Tema: automático (sigue el sistema)",
    light: "Tema: claro",
    dark: "Tema: oscuro",
  };

  var ORDER = ["system", "light", "dark"];

  function currentPreference() {
    var stored = localStorage.getItem(STORAGE_KEY);
    return ORDER.indexOf(stored) === -1 ? "system" : stored;
  }

  function apply(preference) {
    if (preference === "system") {
      root.removeAttribute("data-theme");
    } else {
      root.setAttribute("data-theme", preference);
    }
  }

  function render(button, preference) {
    button.innerHTML = ICONS[preference];
    button.setAttribute("aria-label", LABELS[preference]);
    button.setAttribute("title", LABELS[preference]);
  }

  function init() {
    var button = document.getElementById("theme-toggle");
    if (!button) return;

    var preference = currentPreference();
    render(button, preference);

    button.addEventListener("click", function () {
      preference = ORDER[(ORDER.indexOf(preference) + 1) % ORDER.length];
      localStorage.setItem(STORAGE_KEY, preference);
      apply(preference);
      render(button, preference);
    });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
