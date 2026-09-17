(function () {
  "use strict";

  var manifest = null;
  var currentCategorySlug = null;
  var currentComponentSlug = null;

  function currentTheme() {
    var stored = localStorage.getItem("sb-theme");
    if (stored === "light" || stored === "dark") return stored;
    return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
  }

  function applyTheme(theme) {
    document.documentElement.setAttribute("data-theme", theme);
    var icon = document.getElementById("theme-icon");
    if (icon) icon.textContent = theme === "dark" ? "☀" : "☽";
    if (document.getElementById("grid") && currentComponentSlug) {
      renderDocs();
      renderGrid();
    }
  }

  function toggleTheme() {
    var next = currentTheme() === "dark" ? "light" : "dark";
    localStorage.setItem("sb-theme", next);
    applyTheme(next);
  }

  function findComponent(categorySlug, componentSlug) {
    var category = manifest.categories.find(function (c) { return c.slug === categorySlug; });
    if (!category) return null;
    var component = category.components.find(function (c) { return c.slug === componentSlug; });
    return component ? { category: category, component: component } : null;
  }

  function selectComponent(categorySlug, componentSlug) {
    currentCategorySlug = categorySlug;
    currentComponentSlug = componentSlug;
    document.querySelectorAll(".sb-nav-item").forEach(function (el) {
      el.classList.toggle(
        "active",
        el.dataset.category === categorySlug && el.dataset.component === componentSlug
      );
    });
    renderBreadcrumb();
    renderDocs();
    renderGrid();
  }

  function escapeHtml(value) {
    return String(value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  function renderDocs() {
    var panel = document.getElementById("component-docs");
    var found = findComponent(currentCategorySlug, currentComponentSlug);
    if (!found) {
      panel.hidden = true;
      panel.innerHTML = "";
      return;
    }

    var component = found.component;
    var summary = component.summary || "";
    var parameters = component.parameters || [];
    var html = "";
    if (summary) {
      html += "<p>" + escapeHtml(summary) + "</p>";
    }
    if (parameters.length > 0) {
      html += "<table class=\"sb-params\"><thead><tr><th>Parameter</th><th>Type</th><th>Default</th><th>Notes</th></tr></thead><tbody>";
      parameters.forEach(function (parameter) {
        html +=
          "<tr><td><code>" +
          escapeHtml(parameter.name) +
          "</code></td><td><code>" +
          escapeHtml(parameter.type) +
          "</code></td><td>" +
          escapeHtml(parameter.defaultValue || "—") +
          "</td><td>" +
          escapeHtml(parameter.description || "") +
          "</td></tr>";
      });
      html += "</tbody></table>";
    } else {
      html += "<p class=\"sb-docs-hint\">No initializer docs yet. When you register this component, pass <code>summary</code> and <code>parameters</code>, and <code>docs: ScenarioDocs(snippet:)</code> on each state.</p>";
    }
    panel.innerHTML = html;
    panel.hidden = false;
  }

  function renderBreadcrumb() {
    var found = findComponent(currentCategorySlug, currentComponentSlug);
    var breadcrumb = document.getElementById("breadcrumb");
    if (!found) {
      breadcrumb.textContent = "";
      return;
    }
    breadcrumb.innerHTML =
      found.category.name + " / <strong>" + found.component.name + "</strong>";
  }

  function renderGrid() {
    var grid = document.getElementById("grid");
    var emptyState = document.getElementById("empty-state");
    var found = findComponent(currentCategorySlug, currentComponentSlug);

    if (!found) {
      grid.innerHTML = "";
      return;
    }

    emptyState.hidden = true;
    var theme = currentTheme();

    grid.innerHTML = found.component.scenarios
      .map(function (scenario) {
        var url = scenario.snapshots[theme]["2x"];
        var full = scenario.snapshots[theme]["3x"] || url;
        var snippet = scenario.snippet
          ? '<pre class="sb-card-snippet"><code>' + escapeHtml(scenario.snippet) + "</code></pre>"
          : "";
        var summary = scenario.summary
          ? '<p class="sb-card-caption">' + escapeHtml(scenario.summary) + "</p>"
          : "";
        return (
          '<figure class="sb-card">' +
          '<button type="button" class="sb-card-preview" data-full="' +
          full +
          '" data-caption="' +
          escapeHtml(scenario.name) +
          '"><img src="' +
          url +
          '" alt="' +
          escapeHtml(scenario.name) +
          '" loading="lazy" /></button>' +
          '<figcaption class="sb-card-caption">' +
          escapeHtml(scenario.name) +
          "</figcaption>" +
          summary +
          snippet +
          "</figure>"
        );
      })
      .join("");

    grid.querySelectorAll(".sb-card-preview").forEach(function (button) {
      button.addEventListener("click", function () {
        openLightbox(button.dataset.full, button.dataset.caption);
      });
    });
  }

  function renderSidebar() {
    var nav = document.getElementById("sidebar-nav");
    nav.innerHTML = manifest.categories
      .map(function (category) {
        var items = category.components
          .map(function (component) {
            return (
              '<button class="sb-nav-item" data-category="' +
              category.slug +
              '" data-component="' +
              component.slug +
              '" data-search="' +
              (category.name + " " + component.name).toLowerCase() +
              '">' +
              component.name +
              "</button>"
            );
          })
          .join("");
        return (
          '<div class="sb-nav-category" data-category-search="' +
          category.name.toLowerCase() +
          '">' +
          '<div class="sb-nav-category-title">' +
          category.name +
          "</div>" +
          items +
          "</div>"
        );
      })
      .join("");

    nav.querySelectorAll(".sb-nav-item").forEach(function (button) {
      button.addEventListener("click", function () {
        selectComponent(button.dataset.category, button.dataset.component);
      });
    });
  }

  function renderActions() {
    var container = document.getElementById("sidebar-actions");
    var actions = manifest.actions || [];

    if (actions.length === 0) {
      container.hidden = true;
      return;
    }

    container.hidden = false;
    container.innerHTML = actions
      .map(function (action) {
        return (
          '<button class="sb-action-button" data-action-id="' +
          action.id +
          '"><span>' +
          action.title +
          '</span><span class="sb-action-status" data-status-for="' +
          action.id +
          '"></span></button>'
        );
      })
      .join("");

    container.querySelectorAll(".sb-action-button").forEach(function (button) {
      button.addEventListener("click", function () {
        runAction(button.dataset.actionId, button);
      });
    });
  }

  function runAction(id, button) {
    var status = document.querySelector('[data-status-for="' + id + '"]');
    button.disabled = true;
    status.classList.remove("error");
    status.textContent = "Running…";

    fetch("/actions/" + id, { method: "POST" })
      .then(function (response) {
        if (!response.ok) throw new Error("Failed (" + response.status + ")");
        status.textContent = "Done";
      })
      .catch(function (error) {
        status.classList.add("error");
        status.textContent = error.message;
      })
      .finally(function () {
        button.disabled = false;
        setTimeout(function () { status.textContent = ""; }, 4000);
      });
  }

  function onSearch(event) {
    var query = event.target.value.trim().toLowerCase();
    document.querySelectorAll(".sb-nav-category").forEach(function (categoryEl) {
      var anyVisible = false;
      categoryEl.querySelectorAll(".sb-nav-item").forEach(function (item) {
        var matches = query === "" || item.dataset.search.indexOf(query) !== -1;
        item.hidden = !matches;
        if (matches) anyVisible = true;
      });
      categoryEl.hidden = !anyVisible;
    });
  }

  function openLightbox(src, caption) {
    var lightbox = document.getElementById("lightbox");
    document.getElementById("lightbox-img").src = src;
    document.getElementById("lightbox-img").alt = caption;
    document.getElementById("lightbox-caption").textContent = caption;
    lightbox.hidden = false;
  }

  function closeLightbox() {
    document.getElementById("lightbox").hidden = true;
    document.getElementById("lightbox-img").src = "";
  }

  function boot() {
    applyTheme(currentTheme());

    var toggle = document.getElementById("theme-toggle");
    if (toggle) toggle.addEventListener("click", toggleTheme);

    if (!document.getElementById("sidebar-nav")) return;

    fetch("/manifest.json")
      .then(function (response) { return response.json(); })
      .then(function (data) {
        manifest = data;
        renderSidebar();
        renderActions();

        var firstCategory = manifest.categories[0];
        var firstComponent = firstCategory && firstCategory.components[0];
        if (firstComponent) {
          selectComponent(firstCategory.slug, firstComponent.slug);
        } else {
          document.getElementById("empty-state").hidden = false;
        }
      });

    document.getElementById("search").addEventListener("input", onSearch);
    document.getElementById("lightbox").addEventListener("click", function (event) {
      if (event.target.id === "lightbox" || event.target.id === "lightbox-close") {
        closeLightbox();
      }
    });

    document.addEventListener("keydown", function (event) {
      if (event.key === "Escape") closeLightbox();
      if (event.key === "/" && document.activeElement.tagName !== "INPUT") {
        event.preventDefault();
        document.getElementById("search").focus();
      }
    });
  }

  document.addEventListener("DOMContentLoaded", boot);
})();
