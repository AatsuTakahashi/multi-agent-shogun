#!/usr/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

# しりとりゲーム
# 動物・食べ物・地名等の名詞を中心にした単語リスト（50語以上）
WORDS = %w[
  あひる あさり あじ あわび あまだい
  いのしし いか いくら いちご いわし
  うさぎ うなぎ うめ うに うずら
  えび えんどう えいが えぼだい
  おおかみ おにぎり おくら おいも おこのみやき
  かめ かに からあげ かぼちゃ かつお かわはぎ
  きつね きのこ きゅうり きじ きびなご
  くじら くり くだもの くるみ くわがた
  こあら こめ こんにゃく こい こかげ
  さる さけ さんま さくら さざえ さわら
  しか しじみ しいたけ しらす しらうお
  すずめ すいか すし すだち すずき
  そば そりゃ そで
  たぬき たこ たまご たけのこ たい たちうお
  つばめ つな つくし つくだに つきみそう
  てんぷら てまり てるてるぼうず
  とら とうもろこし とまと とびうお とびきり
  なまず なす なると なべ なつめ
  にわとり にんじん にんにく にしん にぎり
  ねこ ねぎ ねずみ ねりきり
  はくちょう はと はまち はも はぜ はたはた
  ひよこ ひらめ ひまわり ひいらぎ
  ふぐ ふき ふきのとう ふなずし
  へび へちま へらぶな
  ほたて ほうれんそう ほっけ ほや
  まぐろ まつたけ まんじゅう まいたけ まだい
  みかん みずたこ みそ みつば みかわ
  めだか めかぶ めばち めざし
  もも もち もずく もんじゃ
  やぎ やまめ やつめうなぎ やきとり
  ゆず ゆり ゆきかに
  よもぎ よこはま よこなが
  らっきょ らくだ らいちょう
  りんご りす りゅうぐうのつかい
  れんこん れもん れいか れいぞうこ
  わし わかめ わさび わに わかさぎ
  るりかわせみ るびー
  ろばた ろこく
].freeze

# カタカナ→ひらがな変換
def to_hiragana(str)
  str.chars.map do |c|
    code = c.ord
    (code >= 0x30A1 && code <= 0x30F6) ? (code - 0x60).chr(Encoding::UTF_8) : c
  end.join
end

# 単語の末尾ひらがな文字を取得
def last_hiragana_char(word)
  to_hiragana(word).chars.last
end

# 単語の先頭ひらがな文字を取得
def first_hiragana_char(word)
  to_hiragana(word).chars.first
end

def print_separator
  puts '─' * 40
end

def play_game
  used_words = []

  print_separator
  puts '　しりとりゲームへようこそ！'
  print_separator
  puts 'ルール:'
  puts '  ・前の単語の最後の文字で始まる単語を入力'
  puts '  ・「ん」で終わる単語はあなたの負け'
  puts '  ・同じ単語は使えません'
  puts '  ・「quit」で終了'
  print_separator
  puts

  # システムが先攻
  available = WORDS.reject { |w| w.end_with?('ん') }
  first_word = available.sample
  used_words << first_word
  current_char = last_hiragana_char(first_word)

  puts "システム:「#{first_word}」"
  puts "  → 「#{current_char}」で始まる単語をどうぞ"
  puts

  loop do
    print 'あなた: '
    input = $stdin.gets&.chomp&.strip

    # EOF対応
    if input.nil?
      puts "\nゲームを終了します。"
      break
    end

    if input.downcase == 'quit'
      puts 'ゲームを終了します。またね！'
      break
    end

    next puts('単語を入力してください。') if input.empty?

    input_h = to_hiragana(input)
    input_first = input_h.chars.first
    input_last  = input_h.chars.last

    # ① 前の単語の末尾文字で始まっているか
    unless input_first == current_char
      puts "✗ 「#{current_char}」で始まる単語を言ってください！"
      puts "  → あなたの負けです"
      puts "使用した単語: #{used_words.join(' → ')}"
      return ask_restart
    end

    # ② 重複チェック
    if used_words.any? { |w| to_hiragana(w) == input_h }
      puts "✗ 「#{input}」はすでに使われています！"
      puts "  → あなたの負けです"
      puts "使用した単語: #{used_words.join(' → ')}"
      return ask_restart
    end

    # ③ 「ん」終わりチェック
    if input_last == 'ん'
      puts "✗ 「ん」で終わる単語はアウト！"
      puts "  → あなたの負けです"
      puts "使用した単語: #{used_words.join(' → ')}"
      return ask_restart
    end

    used_words << input
    current_char = input_last
    puts "  OK！（ターン: #{used_words.size}）"
    puts

    # システムの応答
    candidates = WORDS.select do |w|
      first_hiragana_char(w) == current_char &&
        !w.end_with?('ん') &&
        used_words.none? { |u| to_hiragana(u) == w }
    end

    if candidates.empty?
      puts "システム: ......「#{current_char}」で始まる単語が見つかりません"
      puts '  → システムの負けです！あなたの勝ち！'
      puts "使用した単語: #{used_words.join(' → ')}"
      return ask_restart
    end

    system_word = candidates.sample
    used_words << system_word
    current_char = last_hiragana_char(system_word)

    puts "システム:「#{system_word}」"
    puts "  → 「#{current_char}」で始まる単語をどうぞ"
    puts
  end
end

def ask_restart
  puts
  print 'もう一度プレイしますか？ (y/n): '
  answer = $stdin.gets&.chomp&.downcase
  puts
  if answer == 'y' || answer == 'yes'
    play_game
  else
    puts 'ありがとうございました！'
  end
end

play_game
