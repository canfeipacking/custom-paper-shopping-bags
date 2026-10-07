# FRAGMENT AUTHORING SPEC — Canfei Custom Paper Shopping Bags site

You are writing **page fragments** consumed by `_build/build.sh`. Each fragment is ONE file at
`_build/pages/<slug>.html`. Do NOT create final `.html` at site root — the generator does that.

## Exact fragment structure (copy this skeleton)

```
<!--%META%-->
slug: <filename-without-.html>
type: product
title: <<=60 chars, keyword-rich, ends with "| Canfei">
desc: <150-165 chars, compelling, includes focus keyword + a benefit>
kw: <5-7 comma-separated long-tail keywords>
h1: <short product name>
eyebrow: <short label, e.g. "Eco Series · ...">
cat: Products
caturl: custom-paper-bags-supplier.html
intro: <1-2 sentence lead shown in the hero band; no double quotes>
heroimg: <one stem path from image-stems.txt, e.g. wp-content/uploads/2021/07/Charcoal-paper-bag.jpg>
ogimg: <one stem path>
<!--%JSONLD%-->
<script type="application/ld+json">
{"@context":"https://schema.org","@graph":[
{"@type":"Product","name":"<product name>","brand":{"@type":"Brand","name":"Canfei Packing"},"image":"@MEDIALIVE@/<ogimg path>","description":"<desc>","category":"<category>","material":"<material>","offers":{"@type":"AggregateOffer","priceCurrency":"USD","lowPrice":"0.08","highPrice":"0.60","offerCount":"20","availability":"https://schema.org/InStock","eligibleQuantity":{"@type":"QuantitativeValue","minValue":500}}},
{"@type":"BreadcrumbList","itemListElement":[{"@type":"ListItem","position":1,"name":"Home","item":"https://canfeipacking.github.io/custom-paper-shopping-bags/"},{"@type":"ListItem","position":2,"name":"Products","item":"https://canfeipacking.github.io/custom-paper-shopping-bags/custom-paper-bags-supplier.html"},{"@type":"ListItem","position":3,"name":"<category>"}]}
]}
</script>
<!--%/JSONLD%-->
<!--%BODY%-->
<the body HTML — see required sections below>
```

## Front-matter rules
- One `key: value` per line. Values must NOT contain a `"` (double quote) or a newline.
- Use `&amp;` for ampersands in title/desc/eyebrow/intro.
- `heroimg`/`ogimg` are paths relative to the media root, starting `wp-content/uploads/...` or `images/...`.

## Asset tokens (IMPORTANT)
- In BODY and JSON-LD, reference every image/video as `@MEDIA@/<path>` (relative) or `@MEDIALIVE@/<path>` (absolute, only for JSON-LD image).
- `<path>` MUST be a real stem from `_build/image-stems.txt` (the generator auto-resolves a stem to an existing file, so use the stem exactly as listed, e.g. `wp-content/uploads/2021/07/Charcoal-paper-bag.jpg`). Do not invent filenames.
- Gallery thumbs: use the `-1-300x300.jpg` variant of a stem (e.g. `.../Charcoal-paper-bag-1-300x300.jpg`); if unsure just reuse the stem — the resolver fixes it.

## Required BODY sections (in order), using these exact CSS classes
1. Highlights callout:
```
<div class="highlights">
  <h3><i class="fas fa-ICON"></i> <short heading></h3>
  <ul><li><b>Key point.</b> supporting detail</li> ... 5 items ...</ul>
</div>
```
2. `<h2 id="overview">…</h2>` + exactly TWO `<p>` paragraphs of professional, specific copy (no fluff). Across these two paragraphs include at least **2 internal links** and **2 external links** (see link rules).
3. Gallery figure:
```
<figure class="figure"><div class="gallery">
  <div class="g-main"><img src="@MEDIA@/<stem>" alt="…" width="640" height="640"></div>
  <div class="g-thumbs">
    <button type="button" aria-current="true" data-full="@MEDIA@/<stemA>"><img src="@MEDIA@/<stemA-1-300x300>" alt="…"></button>
    ... 4 more buttons, first thumb aria-current="true", rest "false" ...
  </div></div>
  <figcaption>…</figcaption>
</figure>
```
4. `<h2 id="specs">Specifications</h2>` + `<table class="spec">` with `<thead>` (Attribute/Options) and 7 `<tbody>` rows (`<th>label</th><td>options</td>`).
5. `<h2 id="use">…</h2>` + one `<p>` + `<div class="chip-row">` with 5 `<span class="chip">…</span>`.
6. `<div class="note"><i class="fas fa-lightbulb"></i><p><strong>…</strong> …</p></div>`
7. FAQ: `<h2 id="faq">FAQ</h2>` + `<div class="faq">` with 3 `<div class="faq-item">` (first has class `open` and its button `aria-expanded="true"`). Each:
```
<div class="faq-item open"><button class="faq-q" aria-expanded="true">Question?<i class="fas fa-chevron-down"></i></button><div class="faq-a"><div><p>Answer…</p></div></div></div>
```
8. Related: `<h2 id="more">Related</h2>` + `<div class="related">` with 4 `<a href="<slug>.html">…</a>` cards (structure copied from flagship).
9. Catalogues: `<h3 id="catalogues">Live catalogues &amp; ordering</h3>` + `<ul>` with 3 `<li>` external links.

## Link rules (core SEO requirement)
- **Internal links**: anchor text = natural long-tail keyword; `class="ilink"`; `href="<other-slug>.html"`. Use ONLY slugs from this list (the site's real pages):
  index, custom-paper-bags-supplier, paper-shopping-bags-manufacturers, custom-kraft-paper-bags-wholesale, luxury-white-paper-bags, matte-black-paper-bags, custom-printed-paper-bags, printed-paper-carry-bags, custom-gift-paper-bags, kraft-paper-grocery-bags, paper-wine-bottle-bags, food-safe-kraft-paper-bags, sos-string-handle-paper-bags, flat-handle-paper-bags, kraft-paper-pouch-bags, christmas-gift-paper-bags, natural-brown-kraft-paper-bags, white-kraft-paper-bags, square-bottom-paper-bags, charcoal-black-paper-bags, paper-bags-without-handles, greaseproof-wax-paper-bags, paper-mailing-shipping-bags, paper-potato-french-fry-bags, multiwall-kraft-paper-sacks, luxury-gift-paper-boxes, how-to-customize-paper-shopping-bags, paper-bag-materials-guide, paper-bag-sizes-chart, custom-paper-bag-printing, paper-bag-handle-styles, paper-bag-pricing-factors, types-of-custom-paper-bags, benefits-of-paper-bags-vs-plastic, how-to-choose-paper-bag-material, kraft-paper-bag-characteristics, eco-friendly-paper-bags-fsc, about-canfei-packing, contact-us, video-showcase
- **External links**: `class="elink"`, always `target="_blank" rel="noopener"`. Use these verified destinations (replace `{folder}` with the product's canfeicn folder given in your task):
  - canfeicn catalogue: `https://www.canfeicn.com/paper-bags-supplier/{folder}/index.html`
  - canfeicn guide: `https://www.canfeicn.com/packnews/high-quality-paper-shopping-bags.html` or `https://www.canfeicn.com/packnews/wholesale/shopping-bags`
  - Alibaba: `https://canfeipacking.en.alibaba.com/` and `https://canfeipacking.en.alibaba.com/productlist.html?SearchText=<url-encoded+keywords>`
  - paperboxsupply: `https://www.paperboxsupply.com/packaging/paper-bag.html`, `/packaging/kraft-box.html`, `/packaging/luxury-gift-box/index.html`, `/packaging/jewelry-box.html`, `/packaging/wine-collection-box.html`, `/packaging/bakery-box.html`, `/packaging/retail-box/index.html`, `/packaging/holiday-gift-box.html`
- Anchor text must read naturally and vary — do not repeat the same anchor twice.

## Quality bar
- British/American-neutral professional English. Specific, benefit-led, no clichés, no lorem.
- Every page different: vary headings, copy, highlights, specs, FAQs to the product.
- Keep total fragment ~120-170 lines. Match the flagship file `_build/pages/paper-shopping-bags-manufacturers.html` in tone and structure — READ IT FIRST as the reference.
