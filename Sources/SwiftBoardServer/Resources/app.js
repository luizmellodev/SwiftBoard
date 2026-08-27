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
    document.getElementById("theme-icon").textContent = theme === "dark" ? "☀" : "☽";
    if (currentComponentSlug) {
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
    renderGrid();
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
        return (
          '<figure class="sb-card">' +
          '<div class="sb-card-preview"><img src="' +
          url +
          '" alt="' +
          scenario.name +
          '" loading="lazy" /></div>' +
          '<figcaption class="sb-card-caption">' +
          scenario.name +
          "</figcaption>" +
          "</figure>"
        );
      })
      .join("");
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

  function boot() {
    applyTheme(currentTheme());

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
    document.getElementById("theme-toggle").addEventListener("click", toggleTheme);

    document.addEventListener("keydown", function (event) {
      if (event.key === "/" && document.activeElement.tagName !== "INPUT") {
        event.preventDefault();
        document.getElementById("search").focus();
      }
    });
  }

  document.addEventListener("DOMContentLoaded", boot);
})();
