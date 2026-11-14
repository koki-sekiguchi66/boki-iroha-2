# ケースで学ぶ簿記2級（boki-iroha-2）

日商簿記2級の「物語で学ぶ」インタラクティブ教科書。静的サイトとして `public/` に生成し、完成後に GitHub（公開リポジトリ）→ Cloudflare Pages で公開する。姉妹作は 3級（`C:\Users\sekig\textbooks\bookkeeping`、GitHub `koki-sekiguchi66/boki-iroha-3`）。

## 作業を始める前に必ず読むもの

1. スキル `boki-textbook`（`.claude/skills/boki-textbook/SKILL.md`）：手順・品質基準・記法・検証の方法。教科書の執筆・修正では最初にこのスキルを使う
2. `_notes/story-bible.md`：主人公・人物・舞台・年表・章の地図・**進捗**（どこまで書いたか）
3. `_notes/research.md`：出題区分表（2027年度適用）、試験の形式、合格率、実際にあった話の候補と出典の確認状況

## 決まっていること

- 出題範囲は **2027年度適用の出題区分表（2026年7月31日公表の確定版）**。2027年3月までの試験との違いは各章で注記する。工業簿記の区分は変更なし
- 物語：新潟の酒蔵「汐見酒造」（架空）の跡取り・汐見澪（28歳）が、蔵を立て直す1年。3級（大川ひより）とは別の世界
- 事例の書き方：実際の事例はコラム（::real の箱）にせず、登場人物が持ち込む物語の場面として書く（2026-11-06 ユーザーの指示）
- 構成：序章＋第1部 工業簿記（第1〜11章）＋第2部 商業簿記（第12〜22章）＋第3部 株式会社・本支店・連結（第23〜26章）＋終章＋付録4本
- 実在の蔵・銘柄と名前が重ならないように、新しい固有名詞は検索で確かめる（「春日酒造」は実在、「澪」は宝酒造の銘柄なので使わない）
- 進め方：2026-11-05 に、ユーザーの指示（「2級のテキストを作成して。Anthropic の巨額赤字を、簿記の計上の仕方で読み解く事例を物語に織り込んで」）で全章を執筆。序章〜終章（ch00〜ch27）と付録A〜Dが完成。通しのテーマは「赤字の中身を読む」

## よく使うコマンド（Git Bash）

```sh
perl build.pl                                                        # 生成と自動検証（貸借一致・縦計・列数）
bash .claude/skills/boki-textbook/scripts/st.sh public ch01.html     # 自己テスト（演習・THINK）
bash .claude/skills/boki-textbook/scripts/st.sh public all.html      # 全章一気読み版（時間がかかる）
bash .claude/skills/boki-textbook/scripts/ovf.sh public $(cd public && ls *.html | grep -v all.html)   # 390px のはみ出し
bash .claude/skills/boki-textbook/scripts/shot.sh public ch01.html 'table' name 1500 390            # スクリーンショット（PNG を Read で見る）
perl .claude/skills/boki-textbook/scripts/rep.pl _src/ch01.txt edits.txt   # 日本語の一括置換（<<<<旧====新>>>>）
```

このPCには Python と Node がない。Perl（Git Bash 同梱）とヘッドレス Chrome を使う。日本語の置換を長いシェルの1行に書かない（スクリプトをファイルに書いて実行する）。

## Git と公開

- ブランチは `main`。改行は LF（`.gitattributes`）。2〜4章ごとにコミットする
- コミットメッセージの末尾には、会話で指示された帰属表示（Co-Authored-By と Claude-Session の行）を付ける
- **push は確認なしで自律的に行ってよい**（2026-11-14 ユーザーの指示）。コミットしたら `GCM_INTERACTIVE=never git push -q origin main` まで続けて実行する。強制 push・履歴の書き換え・リポジトリの削除はしない
- GitHub CLI（`gh`）はログイン済み（koki-sekiguchi66）。PATH に無いときは `"/c/Program Files/GitHub CLI/gh.exe"` で呼ぶ。トークンは表示しない
- 公開リポジトリ `boki-iroha-2` の作成は本の完成時に行うことでユーザーが了承済み（2026-11-05）。作成だけは初回に一言確認する
- Cloudflare Pages の設定（ユーザーが行う）：Framework なし、Build command 空欄、Build output directory `public`
