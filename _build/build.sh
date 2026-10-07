#!/usr/bin/env bash
# ============================================================================
# Canfei — Custom Paper Shopping Bags · static site generator
# Reads _build/pages/*.html fragments (front-matter + JSON-LD + body),
# wraps them in the shared chrome, and writes flat *.html pages + sitemap.
#
# Re-base assets for a standalone deploy:
#   MEDIA_REL=../paper-bags-supplier  (default: local preview beside source)
#   For GitHub Pages that ships its own media, export MEDIA_REL="" and copy
#   wp-content/ + images/ + video/ into this folder, then re-run this script.
# ============================================================================
set -euo pipefail

SITE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$SITE_ROOT/_build/pages"
OUT="$SITE_ROOT"

# ---- Config (override via environment) -------------------------------------
BASE="${BASE:-https://canfeipacking.github.io/custom-paper-shopping-bags}"
MEDIA_REL="${MEDIA_REL:-../paper-bags-supplier}"                       # prefix for in-body <img>/<video>
MEDIA_LIVE="${MEDIA_LIVE:-https://www.canfeicn.com/paper-bags-supplier}" # absolute for og:image / jsonld
STAMP="${STAMP:-2026-10-06}"

BRAND="Canfei Packing"
PHONE="18938035880"
PHONE_D="+86-189-3803-5880"
EMAIL="sophie@canfeicn.com"
WA_TEXT="Hello%21%20I%20am%20interested%20in%20your%20custom%20paper%20shopping%20bags"
ADDR="No.1204 Xiashuijing Building, No.250 Jihua Road, Longgang District, Shenzhen, Guangdong, China"
COMPANY="Shenzhen Canfei Packing Co., Ltd."

# ---- External link destinations (verified live) ----------------------------
CANFEI="https://www.canfeicn.com"
PAPERBOX="https://www.paperboxsupply.com"
ALIBABA="https://canfeipacking.en.alibaba.com"

# ---- helpers ---------------------------------------------------------------
m()    { printf '%s/%s' "$MEDIA_REL" "$1"; }        # relative media src
mlive(){ printf '%s/%s' "$MEDIA_LIVE" "$1"; }       # absolute media url
slug_of(){ basename "$1" .html; }

# absolute on-disk path to the existing media library (source folder)
SRC_DISK="${SRC_DISK:-D:/123/canfeicn/paper-bags-supplier}"

# resolve a source-relative media path to a file that actually exists.
# Prefers full-size (stem-1.jpg / stem.jpg), then any size variant, else keeps input.
resolve(){
  local p="$1" dir base stem cand
  [ -f "$SRC_DISK/$p" ] && { printf '%s' "$p"; return; }
  dir="$(dirname "$p")"; base="$(basename "$p")"
  stem="${base%.*}"
  # strip trailing -<WxH> and -<gallery#> to recover the true product stem
  stem="$(printf '%s' "$stem" | sed -E 's/-[0-9]+x[0-9]+$//; s/-[0-9]+$//')"
  for cand in "$stem-1-300x300.jpg" "$stem-1.jpg" "$stem.jpg" "$stem-300x300.jpg" \
              "$stem-1.png" "$stem.png" "$stem-1-400x400.jpg" "$stem.webp"; do
    [ -f "$SRC_DISK/$dir/$cand" ] && { printf '%s/%s' "$dir" "$cand"; return; }
  done
  cand="$(ls "$SRC_DISK/$dir/" 2>/dev/null | grep -m1 -E "^${stem}([-.]|$)" || true)"
  [ -n "$cand" ] && { printf '%s/%s' "$dir" "$cand"; return; }
  # wrong month? search all upload folders
  cand="$(find "$SRC_DISK/wp-content/uploads" -type f \( -iname "${stem}-1-300x300.jpg" -o -iname "${stem}.jpg" -o -iname "${stem}-1.jpg" -o -iname "${stem}*.jpg" \) 2>/dev/null | head -1)"
  [ -n "$cand" ] && { printf '%s' "${cand#"$SRC_DISK"/}"; return; }
  printf '%s' "$p"
}

# rewrite every @MEDIA@/<path> and @MEDIALIVE@/<path> token in $1 to a resolved,
# correctly-prefixed URL.  Handles quoted HTML attributes and CSS url().
finalize_media(){
  local s="$1" tok path res
  # resolve @MEDIA@/... tokens one at a time (first match), replacing in place
  while [[ "$s" == *"@MEDIA@/"* ]]; do
    tok="${s#*@MEDIA@/}"; path="${tok%%\"*}"; path="${path%%)*}"; path="${path%% *}"
    res="$(resolve "$path")"
    s="${s/@MEDIA@\/$path/$MEDIA_REL/$res}"
  done
  # resolve @MEDIALIVE@/... tokens
  while [[ "$s" == *"@MEDIALIVE@/"* ]]; do
    tok="${s#*@MEDIALIVE@/}"; path="${tok%%\"*}"; path="${path%%)*}"; path="${path%% *}"
    res="$(resolve "$path")"
    s="${s/@MEDIALIVE@\/$path/$MEDIA_LIVE/$res}"
  done
  printf '%s' "$s"
}

# ---- Global navigation model: slug|Label -----------------------------------
PRODUCTS=(
"paper-shopping-bags-manufacturers|Custom Paper Shopping Bags"
"custom-kraft-paper-bags-wholesale|Kraft Paper Bags"
"luxury-white-paper-bags|Luxury White Paper Bags"
"matte-black-paper-bags|Matte Black Paper Bags"
"custom-printed-paper-bags|Printed Paper Bags"
"printed-paper-carry-bags|Paper Carry Bags"
"custom-gift-paper-bags|Paper Gift Bags"
"kraft-paper-grocery-bags|Grocery Paper Bags"
"paper-wine-bottle-bags|Wine Paper Bags"
"food-safe-kraft-paper-bags|Food Paper Bags"
"sos-string-handle-paper-bags|SOS String-Handle Bags"
"flat-handle-paper-bags|Flat-Handle Bags"
"kraft-paper-pouch-bags|Paper Pouch Bags"
"christmas-gift-paper-bags|Christmas Paper Bags"
"natural-brown-kraft-paper-bags|Natural Brown Kraft Bags"
"white-kraft-paper-bags|White Kraft Paper Bags"
"square-bottom-paper-bags|Square-Bottom Bags"
"charcoal-black-paper-bags|Charcoal Paper Bags"
"paper-bags-without-handles|Bags Without Handles"
"greaseproof-wax-paper-bags|Grease-Proof Wax Bags"
"paper-mailing-shipping-bags|Paper Mailing Bags"
"paper-potato-french-fry-bags|Potato & Fry Bags"
"multiwall-kraft-paper-sacks|Multiwall Paper Sacks"
"luxury-gift-paper-boxes|Gift Paper Boxes"
)
CUSTOMIZE=(
"how-to-customize-paper-shopping-bags|How to Customize"
"paper-bag-materials-guide|Materials & Colors"
"paper-bag-sizes-chart|Sizes & Dimensions"
"custom-paper-bag-printing|Printing & Finishes"
"paper-bag-handle-styles|Handles & Ropes"
"paper-bag-pricing-factors|Pricing & MOQ Factors"
)
GUIDES=(
"types-of-custom-paper-bags|Types of Custom Paper Bags"
"benefits-of-paper-bags-vs-plastic|Paper vs Plastic Bags"
"how-to-choose-paper-bag-material|Choosing Bag Material"
"kraft-paper-bag-characteristics|Kraft Bag Characteristics"
"eco-friendly-paper-bags-fsc|FSC & Eco Certifications"
)
ALLNAV=("${PRODUCTS[@]}" "${CUSTOMIZE[@]}" "${GUIDES[@]}")

# ---- Build reusable chrome blocks ------------------------------------------
brand_svg='<svg viewBox="0 0 32 32" fill="none" aria-hidden="true"><path d="M9 11V9a7 7 0 0 1 14 0v2" stroke="#C89B6D" stroke-width="2.1" stroke-linecap="round"/><path d="M6.5 11h19l-1.3 15.2A2.6 2.6 0 0 1 21.6 28.5H10.4a2.6 2.6 0 0 1-2.6-2.3L6.5 11Z" fill="#FAF6EE" stroke="#fff" stroke-width="2"/><path d="M12.5 11a3.5 3.5 0 0 0 7 0" stroke="#fff" stroke-width="1.7"/></svg>'

build_topbar(){ cat <<HTML
<div class="topbar"><div class="container">
  <div class="topbar-left">
    <a href="tel:+$PHONE" class="tel"><i class="fas fa-phone-alt"></i>$PHONE_D</a>
    <a href="mailto:$EMAIL" class="email"><i class="fas fa-envelope"></i>$EMAIL</a>
    <span><i class="fas fa-clock"></i> Mon–Sat · Reply within 12h</span>
  </div>
  <div class="topbar-right social">
    <a href="#" aria-label="Facebook"><i class="fab fa-facebook-f"></i></a>
    <a href="#" aria-label="Instagram"><i class="fab fa-instagram"></i></a>
    <a href="#" aria-label="YouTube"><i class="fab fa-youtube"></i></a>
    <a href="#" aria-label="Pinterest"><i class="fab fa-pinterest-p"></i></a>
    <a href="#" aria-label="LinkedIn"><i class="fab fa-linkedin-in"></i></a>
  </div>
</div></div>
HTML
}

build_header(){ cat <<HTML
<header class="site-header"><div class="container"><nav class="nav" aria-label="Primary">
  <a class="brand" href="index.html" aria-label="$BRAND home">
    <span class="brand-mark">$brand_svg</span>
    <span class="brand-txt"><b>Canfei</b><span>Paper Bags</span></span>
  </a>
  <ul class="menu" id="menu">
    <li><a href="index.html">Home</a></li>
    <li class="has-sub"><a href="custom-paper-bags-supplier.html">Products <i class="fas fa-chevron-down caret"></i></a>
      <ul class="sub">
        <li class="sub-title">Shopping &amp; Carry</li>
$(products_sub)
      </ul>
    </li>
    <li class="has-sub"><a href="how-to-customize-paper-shopping-bags.html">Customize <i class="fas fa-chevron-down caret"></i></a>
      <ul class="sub">
        <li class="sub-title">Make It Yours</li>
$(customize_sub)
      </ul>
    </li>
    <li class="has-sub"><a href="types-of-custom-paper-bags.html">Guides <i class="fas fa-chevron-down caret"></i></a>
      <ul class="sub">
        <li class="sub-title">Buying Guides &amp; FAQ</li>
$(guides_sub)
      </ul>
    </li>
    <li><a href="video-showcase.html">Video</a></li>
    <li><a href="about-canfei-packing.html">About</a></li>
    <li><a href="contact-us.html">Contact</a></li>
  </ul>
  <div class="nav-cta">
    <a class="btn btn-primary btn-sm" href="contact-us.html"><i class="fas fa-pen-nib"></i> Get a Free Quote</a>
    <button class="nav-toggle" aria-expanded="false" aria-controls="menu" aria-label="Menu"><i class="fas fa-bars"></i></button>
  </div>
</nav></div></header>
HTML
}
products_sub(){ local e; for e in "${PRODUCTS[@]}"; do printf '        <li><a href="%s.html">%s</a></li>\n' "${e%%|*}" "${e#*|}"; done; }
customize_sub(){ local e; for e in "${CUSTOMIZE[@]}"; do printf '        <li><a href="%s.html">%s</a></li>\n' "${e%%|*}" "${e#*|}"; done; }
guides_sub(){ local e; for e in "${GUIDES[@]}"; do printf '        <li><a href="%s.html">%s</a></li>\n' "${e%%|*}" "${e#*|}"; done; }

build_sidebar(){ cat <<HTML
<aside class="aside-sticky">
  <div class="card quote-cta">
    <h3><i class="fas fa-tags"></i> Factory-Direct Quote</h3>
    <p>Send your artwork &amp; size — free design, sample in 5–8 days.</p>
    <div class="btn-row" style="margin-top:.9rem">
      <a class="btn btn-kraft" href="contact-us.html"><i class="fas fa-envelope"></i> Request a Quote</a>
      <a class="btn btn-light" href="https://wa.me/$PHONE?text=$WA_TEXT" target="_blank" rel="noopener"><i class="fab fa-whatsapp"></i> WhatsApp</a>
    </div>
  </div>
  <div class="card">
    <h3><i class="fas fa-layer-group"></i> Shop by Type</h3>
    <ul class="cat-list">
$(sidebar_products)
    </ul>
  </div>
  <div class="card">
    <h3><i class="fas fa-headset"></i> Talk to Us</h3>
    <div class="contact-rows">
      <p><i class="fas fa-phone-alt"></i><span><a href="tel:+$PHONE">$PHONE_D</a></span></p>
      <p><i class="fas fa-envelope"></i><span><a href="mailto:$EMAIL">$EMAIL</a></span></p>
      <p><i class="fab fa-whatsapp"></i><span><a href="https://wa.me/$PHONE?text=$WA_TEXT" target="_blank" rel="noopener">+86 $PHONE_D</a></span></p>
      <p><i class="fas fa-store"></i><span>$BRAND · Shenzhen, China</span></p>
    </div>
  </div>
  <div class="card">
    <h3><i class="fas fa-award"></i> Why Canfei</h3>
    <ul class="cat-list">
      <li style="list-style:none;margin:.4rem 0"><i class="fas fa-check" style="color:var(--pine)"></i> FSC®-certified kraft options</li>
      <li style="list-style:none;margin:.4rem 0"><i class="fas fa-check" style="color:var(--pine)"></i> Low MOQ — small wholesale OK</li>
      <li style="list-style:none;margin:.4rem 0"><i class="fas fa-check" style="color:var(--pine)"></i> Free design &amp; sampling</li>
      <li style="list-style:none;margin:.4rem 0"><i class="fas fa-check" style="color:var(--pine)"></i> 15+ yrs export experience</li>
    </ul>
  </div>
</aside>
HTML
}
sidebar_products(){ local e s l; for e in "${PRODUCTS[@]}"; do s="${e%%|*}"; l="${e#*|}"; printf '      <li><a href="%s.html">%s</a></li>\n' "$s" "$l"; done; }

build_footer(){ cat <<HTML
<footer class="site-footer"><div class="container">
  <div class="footer-grid">
    <div>
      <div class="fbrand"><span class="brand-mark">$brand_svg</span><span class="brand-txt"><b>Canfei Packing</b><span>Custom Paper Bags</span></span></div>
      <p>A specialist <strong style="color:#fff">custom paper shopping bag manufacturer</strong> in Shenzhen, China. Factory-direct kraft, white &amp; luxury shopping bags with your logo, low MOQ and free design.</p>
      <div class="footer-social">
        <a href="#" aria-label="Facebook"><i class="fab fa-facebook-f"></i></a>
        <a href="#" aria-label="Instagram"><i class="fab fa-instagram"></i></a>
        <a href="#" aria-label="YouTube"><i class="fab fa-youtube"></i></a>
        <a href="#" aria-label="Pinterest"><i class="fab fa-pinterest-p"></i></a>
        <a href="#" aria-label="LinkedIn"><i class="fab fa-linkedin-in"></i></a>
      </div>
    </div>
    <div><h4>Shopping Bags</h4><ul>
      <li><a href="paper-shopping-bags-manufacturers.html">Custom Shopping Bags</a></li>
      <li><a href="custom-kraft-paper-bags-wholesale.html">Kraft Paper Bags</a></li>
      <li><a href="luxury-white-paper-bags.html">Luxury White Bags</a></li>
      <li><a href="matte-black-paper-bags.html">Matte Black Bags</a></li>
      <li><a href="custom-printed-paper-bags.html">Printed Paper Bags</a></li>
      <li><a href="custom-gift-paper-bags.html">Gift Paper Bags</a></li>
    </ul></div>
    <div><h4>Customize &amp; Guides</h4><ul>
      <li><a href="how-to-customize-paper-shopping-bags.html">How to Customize</a></li>
      <li><a href="paper-bag-materials-guide.html">Materials &amp; Colors</a></li>
      <li><a href="paper-bag-sizes-chart.html">Size Chart</a></li>
      <li><a href="custom-paper-bag-printing.html">Printing &amp; Finishes</a></li>
      <li><a href="paper-bag-pricing-factors.html">Pricing &amp; MOQ</a></li>
      <li><a href="types-of-custom-paper-bags.html">Types of Paper Bags</a></li>
    </ul></div>
    <div class="fcontact"><h4>Get in Touch</h4>
      <p><i class="fas fa-map-marker-alt"></i> $ADDR</p>
      <p><i class="fas fa-phone-alt"></i> <a href="tel:+$PHONE">$PHONE_D</a></p>
      <p><i class="fas fa-envelope"></i> <a href="mailto:$EMAIL">$EMAIL</a></p>
      <p><i class="fab fa-whatsapp"></i> <a href="https://wa.me/$PHONE?text=$WA_TEXT" target="_blank" rel="noopener">$PHONE_D</a></p>
    </div>
  </div>
  <div class="footer-bar">
    <div class="footer-legal">
      <span>Copyright © 2008–<span data-year>2026</span> $COMPANY. All Rights Reserved.</span>
      <span><a href="about-canfei-packing.html">About</a> · <a href="contact-us.html">Contact</a> · <a href="eco-friendly-paper-bags-fsc.html">Sustainability</a></span>
    </div>
  </div>
</div></footer>
<div class="float-contact">
  <div class="float-panel">
    <a href="https://wa.me/$PHONE?text=$WA_TEXT" target="_blank" rel="noopener"><i class="fab fa-whatsapp"></i> WhatsApp</a>
    <a href="tel:+$PHONE"><i class="fas fa-phone-alt"></i> $PHONE_D</a>
    <a href="mailto:$EMAIL"><i class="fas fa-envelope"></i> $EMAIL</a>
    <a href="$ALIBABA/" target="_blank" rel="noopener"><i class="fas fa-store"></i> Visit Alibaba Store</a>
  </div>
  <button class="float-tab" aria-label="Contact us"><i class="fas fa-comment-dots"></i></button>
</div>
<button class="back-top" aria-label="Back to top"><i class="fas fa-chevron-up"></i></button>
<nav class="mobar" aria-label="Mobile">
  <a href="index.html"><i class="fas fa-house"></i>Home</a>
  <a href="custom-paper-bags-supplier.html"><i class="fas fa-bag-shopping"></i>Products</a>
  <a href="how-to-customize-paper-shopping-bags.html"><i class="fas fa-pen-ruler"></i>Custom</a>
  <a href="video-showcase.html"><i class="fas fa-video"></i>Video</a>
  <a href="contact-us.html"><i class="fas fa-phone"></i>Contact</a>
</nav>
<script src="site/site.js" defer></script>
HTML
}

build_cta(){ cat <<HTML
<section class="section section-tight section--cream"><div class="container">
  <div class="cta-band">
    <div><h2>Bring your shopping bag idea to life</h2>
      <p>Free design, low MOQ and factory-direct pricing. Share your logo and size today — get a sample in 5–8 working days.</p></div>
    <div class="btn-row"><a class="btn btn-kraft btn-lg" href="contact-us.html"><i class="fas fa-envelope"></i> Request a Quote</a>
      <a class="btn btn-light btn-lg" href="https://wa.me/$PHONE?text=$WA_TEXT" target="_blank" rel="noopener"><i class="fab fa-whatsapp"></i> Chat Now</a></div>
  </div>
</div></section>
HTML
}

# ---- head ------------------------------------------------------------------
build_head(){ # $1 title $2 desc $3 canonical $4 ogimgpath $5 jsonld $6 type $7 keywords
  local title="$1" desc="$2" canon="$3" ogp="$4" jsonld="$5" ptype="$6" kw="$7"
  local ogimg; ogimg="$(mlive "$ogp")"
  cat <<HEAD
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="theme-color" content="#2F6B4F">
<title>$title</title>
<meta name="description" content="$desc">
<meta name="keywords" content="$kw">
<meta name="author" content="$COMPANY">
<meta name="robots" content="index,follow,max-image-preview:large,max-snippet:-1,video-preview">
<link rel="canonical" href="$canon">
<link rel="alternate" hreflang="en" href="$canon">
<link rel="alternate" hreflang="x-default" href="$canon">
<link rel="icon" type="image/png" href="$(m 'wp-content/uploads/2021/06/paper-bag-icon.png')">
<meta property="og:type" content="$ptype">
<meta property="og:site_name" content="$BRAND — Custom Paper Shopping Bags">
<meta property="og:locale" content="en_US">
<meta property="og:title" content="$title">
<meta property="og:description" content="$desc">
<meta property="og:url" content="$canon">
<meta property="og:image" content="$ogimg">
<meta property="og:image:alt" content="$title">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="$title">
<meta name="twitter:description" content="$desc">
<meta name="twitter:image" content="$ogimg">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,500;9..144,600;9..144,700&family=Manrope:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
<link rel="stylesheet" href="site/shopping-bags.css">
$jsonld
</head>
HEAD
}

# ---- breadcrumb ------------------------------------------------------------
build_crumb(){ # $1 cat $2 caturl $3 h1
  local cat="$1" caturl="$2" h1="$3"
  if [ -n "$caturl" ]; then
    printf '<div class="breadcrumb"><a href="index.html">Home</a> <span class="sep">/</span> <a href="%s">%s</a> <span class="sep">/</span> <span class="current">%s</span></div>\n' "$caturl" "$cat" "$h1"
  else
    printf '<div class="breadcrumb"><a href="index.html">Home</a> <span class="sep">/</span> <span class="current">%s</span></div>\n' "$h1"
  fi
}

# ---- assemble one page -----------------------------------------------------
SLUGS_DONE=()
build_page(){
  local f="$1" name meta slug type title desc kw h1 eyebrow ogimg cat caturl intro sidebar cta body jsonld
  name="$(basename "$f")"
  meta="$(awk 'f&&/^<!--%\/META%-->/{exit} f{print} /^<!--%META%-->/{f=1}' "$f")"
  jsonld="$(awk 'f&&/^<!--%\/JSONLD%-->/{exit} f{print} /^<!--%JSONLD%-->/{f=1}' "$f")"
  body="$(awk 'f{print} /^<!--%BODY%-->/{f=1}' "$f")"
  getm(){ printf '%s\n' "$meta" | awk -v k="$1" 'index($0,k": "){print substr($0,index($0,k": ")+length(k)+2); exit}'; }
  # resolve + re-base every asset token in body and JSON-LD
  body="$(finalize_media "$body")"
  jsonld="$(finalize_media "$jsonld")"
  slug="$(getm slug)";   type="$(getm type)";   title="$(getm title)"; desc="$(getm desc)"
  kw="$(getm kw)";       h1="$(getm h1)";       eyebrow="$(getm eyebrow)"
  ogimg="$(getm ogimg)"; cat="$(getm cat)";     caturl="$(getm caturl)"
  intro="$(getm intro)"; sidebar="$(getm sidebar)"; cta="$(getm cta)"
  local heroimg; heroimg="$(getm heroimg)"; [ -n "$heroimg" ] && heroimg="$(resolve "$heroimg")"
  [ -z "$ogimg" ] && ogimg="wp-content/uploads/2021/06/Custom-printed-matte-luxury-paper-shopping-bags-1-300x300.jpg"
  ogimg="$(resolve "$ogimg")"
  [ "$sidebar" = "none" ] || sidebar="yes"
  local canon out ogt
  case "$type" in guide|info) ogt="article";; *) ogt="website";; esac
  if [ "$type" = "home" ] || [ "$slug" = "index" ]; then canon="$BASE/"; else canon="$BASE/$slug.html"; fi
  out="$OUT/$slug.html"

  {
    build_head "$title" "$desc" "$canon" "$ogimg" "$jsonld" "$ogt" "$kw"
    printf '<body>\n<a class="skip-link" href="#main">Skip to content</a>\n'
    build_topbar
    build_header
    printf '<main id="main">\n'
    if [ "$type" = "home" ]; then
      printf '%s\n' "$body"
    else
      # page hero band
      if [ -n "$heroimg" ]; then
        printf '<section class="page-hero"><div class="container"><div class="hero-grid"><div>\n'
        build_crumb "$cat" "$caturl" "$h1"
        [ -n "$eyebrow" ] && printf '<span class="eyebrow">%s</span>\n' "$eyebrow"
        printf '<h1>%s</h1>\n' "$h1"
        [ -n "$intro" ] && printf '<p class="lead">%s</p>\n' "$intro"
        printf '<div class="btn-row"><a class="btn btn-primary" href="contact-us.html"><i class="fas fa-envelope"></i> Get a Quote</a><a class="btn btn-ghost" href="https://wa.me/%s?text=%s" target="_blank" rel="noopener"><i class="fab fa-whatsapp"></i> WhatsApp</a></div>\n' "$PHONE" "$WA_TEXT"
        printf '</div><div class="hero-figure"><img src="%s" alt="%s" width="560" height="620" loading="eager"></div>\n' "$(m "$heroimg")" "$h1"
        printf '</div></div></section>\n'
      else
        printf '<section class="page-hero"><div class="container">\n'
        build_crumb "$cat" "$caturl" "$h1"
        [ -n "$eyebrow" ] && printf '<span class="eyebrow">%s</span>\n' "$eyebrow"
        printf '<h1>%s</h1>\n' "$h1"
        [ -n "$intro" ] && printf '<p class="lead" style="max-width:760px">%s</p>\n' "$intro"
        printf '</div></section>\n'
      fi
      # content
      if [ "$sidebar" = "yes" ]; then
        printf '<section class="section section--cream"><div class="container"><div class="layout">\n<div class="prose">\n'
        printf '%s\n' "$body"
        printf '</div>\n'; build_sidebar; printf '</div></div></section>\n'
      else
        printf '%s\n' "$body"
      fi
      [ "$cta" = "no" ] || build_cta
    fi
    printf '</main>\n'
    build_footer
    printf '</body>\n</html>\n'
  } > "$out"

  SLUGS_DONE+=("$slug|$type")
  printf '  built  %-44s -> %s.html\n' "$name" "$slug"
}

# ---- sitemap ---------------------------------------------------------------
build_sitemap(){
  local sm="$OUT/sitemap.xml" pri
  {
    printf '<?xml version="1.0" encoding="UTF-8"?>\n'
    printf '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
    for e in "${SLUGS_DONE[@]}"; do
      local s="${e%%|*}" t="${e#*|}"
      if [ "$s" = "index" ]; then printf '  <url><loc>%s/</loc><lastmod>%s</lastmod><changefreq>weekly</changefreq><priority>1.0</priority></url>\n' "$BASE" "$STAMP"; continue; fi
      case "$t" in product) pri="0.9";; guide) pri="0.8";; *) pri="0.7";; esac
      printf '  <url><loc>%s/%s.html</loc><lastmod>%s</lastmod><changefreq>weekly</changefreq><priority>%s</priority></url>\n' "$BASE" "$s" "$STAMP" "$pri"
    done
    printf '</urlset>\n'
  } > "$sm"
  printf '  sitemap.xml  (%d urls)\n' "${#SLUGS_DONE[@]}"
}

# ---- run -------------------------------------------------------------------
echo "== Building Canfei Custom Paper Shopping Bags site =="
echo "   BASE=$BASE"
echo "   MEDIA_REL=$MEDIA_REL"
echo "-----------------------------------------------------------------"
shopt -s nullglob
for f in "$SRC"/*.html; do build_page "$f"; done
build_sitemap

# robots + nojekyll + 404
printf 'User-agent: *\nAllow: /\n\nSitemap: %s/sitemap.xml\n' "$BASE" > "$OUT/robots.txt"
: > "$OUT/.nojekyll"
printf '<h1 style="font-family:sans-serif">404 — page not found</h1><p><a href="index.html">Back to home</a></p>\n' > "$OUT/404.html" 2>/dev/null || true
echo "-----------------------------------------------------------------"
echo "== Done. Pages written to: $OUT =="
