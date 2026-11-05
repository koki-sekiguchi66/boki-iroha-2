#!/usr/bin/env bash
# スマホ幅（390px）で横にはみ出す要素を探す。スクロール容器（overflow-x:auto/scroll）の中は除外
# usage: ovf.sh <public のフォルダ> page.html [page.html ...]
# 出力: 「sw=横幅 vw=画面幅 n=はみ出し要素数 先頭4件」。n=0 なら問題なし
# 検出力の確認：わざと whitespace-nowrap の長いリンクを入れたコピーで n>0 になることを確かめてある
PUB=$(cd "$1" && { pwd -W 2>/dev/null || pwd; }); shift
CHROME="${CHROME:-/c/Program Files/Google/Chrome/Application/chrome.exe}"
WD="${TMPDIR:-/tmp}/kb-ovf"; mkdir -p "$WD"
W=$(cygpath -m "$WD" 2>/dev/null || echo "$WD")
for P in "$@"; do
cat > "$WD/wrap.html" <<EOT
<!DOCTYPE html><html><body style="margin:0"><div id="out">pending</div>
<iframe id="f" src="file:///${PUB}/${P}" style="border:0;width:390px;height:900px"></iframe>
<script>
document.getElementById('f').addEventListener('load', () => setTimeout(() => {
  const w = document.getElementById('f').contentWindow, d = w.document, vw = d.documentElement.clientWidth;
  const bad = [];
  d.querySelectorAll('body *').forEach((el) => {
    const r = el.getBoundingClientRect();
    if (r.width === 0 || r.right <= vw + 1) return;
    for (let a = el.parentElement; a; a = a.parentElement) {
      const ox = w.getComputedStyle(a).overflowX;
      if (ox === 'auto' || ox === 'scroll') return;
    }
    if (w.getComputedStyle(el).position === 'fixed') return;
    bad.push(el.tagName + '.' + String(el.className.baseVal ?? el.className).split(' ').slice(0, 2).join('.') + ' [' + (el.textContent || '').trim().slice(0, 24) + '] right=' + Math.round(r.right));
  });
  document.getElementById('out').textContent = 'sw=' + d.documentElement.scrollWidth + ' vw=' + vw + ' n=' + bad.length + ' ' + bad.slice(0, 4).join(' | ');
}, 2500));
</script></body></html>
EOT
R=$("$CHROME" --headless=new --disable-gpu --allow-file-access-from-files \
  --user-data-dir="$W/prof" --window-size=430,900 --virtual-time-budget=15000 \
  --dump-dom "file:///$W/wrap.html" 2>/dev/null | grep -o '<div id="out">[^<]*' | sed 's/<[^>]*>//')
printf '%-12s %s\n' "$P" "$R"
done
