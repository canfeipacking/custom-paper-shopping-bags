/* ==========================================================================
   Canfei — Custom Paper Shopping Bags · site.js  (vanilla, no deps)
   ========================================================================== */
(function () {
  "use strict";
  var reduce = window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  document.addEventListener("DOMContentLoaded", function () {
    initHeader();
    initNav();
    initFaq();
    initGallery();
    initFloat();
    initBackTop();
    initReveal();
    setYear();
  });

  /* Sticky header shadow */
  function initHeader() {
    var h = document.querySelector(".site-header");
    if (!h) return;
    var on = function () { h.classList.toggle("scrolled", window.pageYOffset > 8); };
    on();
    window.addEventListener("scroll", on, { passive: true });
  }

  /* Mobile menu + dropdown toggles */
  function initNav() {
    var toggle = document.querySelector(".nav-toggle");
    var menu = document.querySelector(".menu");
    if (!toggle || !menu) return;
    toggle.addEventListener("click", function () {
      var open = menu.classList.toggle("open");
      toggle.setAttribute("aria-expanded", open ? "true" : "false");
    });
    // On mobile, tapping a parent item toggles its submenu instead of navigating
    var isMobile = function () { return window.matchMedia("(max-width: 860px)").matches; };
    menu.querySelectorAll(".has-sub > a").forEach(function (a) {
      a.addEventListener("click", function (e) {
        if (isMobile()) {
          e.preventDefault();
          a.parentNode.classList.toggle("open");
        }
      });
    });
  }

  /* FAQ accordion */
  function initFaq() {
    document.querySelectorAll(".faq-q").forEach(function (btn) {
      btn.addEventListener("click", function () {
        var item = btn.closest(".faq-item");
        var box = item.parentNode;
        var isOpen = item.classList.contains("open");
        // single-open behaviour within a group
        box.querySelectorAll(".faq-item.open").forEach(function (o) {
          if (o !== item) { o.classList.remove("open"); o.querySelector(".faq-q").setAttribute("aria-expanded", "false"); }
        });
        item.classList.toggle("open", !isOpen);
        btn.setAttribute("aria-expanded", !isOpen ? "true" : "false");
      });
    });
  }

  /* Gallery main/thumbnail swap */
  function initGallery() {
    var main = document.querySelector(".g-main img");
    if (!main) return;
    document.querySelectorAll(".g-thumbs button").forEach(function (b) {
      b.addEventListener("click", function () {
        var full = b.getAttribute("data-full") || b.querySelector("img").src;
        main.src = full;
        main.alt = b.getAttribute("data-alt") || main.alt;
        b.parentNode.querySelectorAll("button").forEach(function (x) { x.setAttribute("aria-current", "false"); });
        b.setAttribute("aria-current", "true");
      });
    });
  }

  /* Floating contact panel */
  function initFloat() {
    var fc = document.querySelector(".float-contact");
    if (!fc) return;
    var tab = fc.querySelector(".float-tab");
    tab.addEventListener("click", function (e) { e.stopPropagation(); fc.classList.toggle("open"); });
    document.addEventListener("click", function (e) { if (!fc.contains(e.target)) fc.classList.remove("open"); });
  }

  /* Back to top */
  function initBackTop() {
    var bt = document.querySelector(".back-top");
    if (!bt) return;
    var on = function () { bt.classList.toggle("show", window.pageYOffset > 500); };
    on();
    window.addEventListener("scroll", on, { passive: true });
    bt.addEventListener("click", function () { window.scrollTo({ top: 0, behavior: reduce ? "auto" : "smooth" }); });
  }

  /* Reveal on scroll */
  function initReveal() {
    var els = document.querySelectorAll(".reveal");
    if (!els.length) return;
    if (reduce || !("IntersectionObserver" in window)) {
      els.forEach(function (e) { e.classList.add("in"); });
      return;
    }
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (en) { if (en.isIntersecting) { en.target.classList.add("in"); io.unobserve(en.target); } });
    }, { rootMargin: "0px 0px -8% 0px", threshold: 0.08 });
    els.forEach(function (e) { io.observe(e); });
  }

  function setYear() {
    document.querySelectorAll("[data-year]").forEach(function (el) { el.textContent = new Date().getFullYear(); });
  }
})();
