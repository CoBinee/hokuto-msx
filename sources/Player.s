; Player.s : プレイヤ
;


; モジュール宣言
;
    .module Player

; 参照ファイル
;
    .include    "bios.inc"
    .include    "vdp.inc"
    .include    "System.inc"
    .include    "Sound.inc"
    .include    "App.inc"
    .include    "Code.inc"
    .include    "Game.inc"
    .include    "Enemy.inc"
    .include	"Player.inc"

; 外部変数宣言
;
    .globl  _patternTable

; マクロの定義
;


; CODE 領域
;
    .area   _CODE

; プレイヤを初期化する
;
_PlayerInitialize::
    
    ; レジスタの保存
    
    ; プレイヤの初期化
    ld      hl, #playerDefault
    ld      de, #_player
    ld      bc, #PLAYER_LENGTH
    ldir

    ; パターンジェネレータの転送
    ld      hl, #(_patternTable + 0x1000)
    ld      de, #(APP_PATTERN_GENERATOR_TABLE + 0x0600)
    ld      bc, #0x01c0
    call    LDIRVM

    ; カラーテーブルの設定
    ld      a, #VDP_COLOR_CYAN
    call    PlayerSetColor

    ; 処理の設定
    ld      hl, #PlayerPlay
    ld      (_player + PLAYER_PROC_L), hl
    xor     a
    ld      (_player + PLAYER_STATE), a
    
    ; レジスタの復帰
    
    ; 終了
    ret

; プレイヤを更新する
;
_PlayerUpdate::
    
    ; レジスタの保存

    ; 状態別の処理
    ld      hl, #10$
    push    hl
    ld      hl, (_player + PLAYER_PROC_L)
    jp      (hl)
;   pop     hl
10$:

    ; 防御の更新
    ld      hl, #(_player + PLAYER_GUARD)
    ld      a, (_input + INPUT_KEY_DOWN)
    dec     a
    jr      z, 20$
    ld      a, (hl)
    cp      #0xff
    jr      nc, 20$
    inc     a
20$:
    ld      (hl), a

    ; レジスタの復帰
    
    ; 終了
    ret

; プレイヤを描画する
;
_PlayerRender::

    ; レジスタの保存

    ; パターンの描画
    ld      hl, (_player + PLAYER_PATTERN_L)
    ld      de, (_player + PLAYER_POSITION_X)
    ld      a, h
    or      l
    call    nz, _GamePrintPattern

    ; 台詞の描画
    ld      hl, (_player + PLAYER_SPEECH_L)
    ld      de, (_player + PLAYER_SPEECH_X)
    ld      a, h
    or      l
    call    nz, _GamePrintString

    ; レジスタの復帰

    ; 終了
    ret

; 何もしない
;
PlayerNull:

    ; レジスタの保存

    ; レジスタの復帰

    ; 終了
    ret

; プレイヤを操作する
;
PlayerPlay:

    ; レジスタの保存

    ; 初期化
    ld      a, (_player + PLAYER_STATE)
    or      a
    jr      nz, 09$

    ; フラグの設定
    ld      hl, #(_player + PLAYER_FLAG)
    set     #PLAYER_FLAG_ACTIVE_BIT, (hl)

    ; アニメーションの設定
    xor     a
    ld      (_player + PLAYER_ANIMATION), a

    ; パターンの設定
    ld      hl, #playerPatternStand
    ld      (_player + PLAYER_PATTERN_L), hl

    ; 台詞の消去
    call    _PlayerClearSpeech

    ; カラーテーブルの設定
    ld      a, #VDP_COLOR_CYAN
    call    PlayerSetColor

    ; 初期化の完了
    ld      hl, #(_player + PLAYER_STATE)
    inc     (hl)
09$:

    ; アニメーションの更新
    ld      hl, #(_player + PLAYER_ANIMATION)
    inc     (hl)

    ; エネミーとの接触
    call    PlayerContact
    jr      nc, 100$
    ld      hl, (_player + PLAYER_PROC_L)
    jp      (hl)
;   jr      90$

    ; 操作の開始

    ; 技の選択
100$:
    ld      a, (_input + INPUT_KEY_DOWN)
    dec     a
    jr      nz, 109$
    ld      hl, #(_player + PLAYER_SPECIAL)
    ld      a, (hl)
    inc     a
    cp      #PLAYER_SPECIAL_LENGTH
    jr      c, 101$
    xor     a
101$:
    ld      (hl), a
109$:

    ; 技を繰り出す
110$:
    ld      a, (_input + INPUT_BUTTON_SHIFT)
    dec     a
    jr      nz, 120$
    ld      a, (_player + PLAYER_POWER)
    cp      #PLAYER_POWER_MAXIMUM
    jr      c, 120$
    ld      a, (_player + PLAYER_SPECIAL)
    add     a, a
    ld      e, a
    ld      d, #0x00
    ld      hl, #playerSpecialProc
    add     hl, de
    ld      e, (hl)
    inc     hl
    ld      d, (hl)
    ex      de, hl
    ld      (_player + PLAYER_PROC_L), hl
    xor     a
    ld      (_player + PLAYER_STATE), a
    jp      (hl)
;   jr      190$

    ; 攻撃
120$:
    ld      a, (_input + INPUT_BUTTON_SPACE)
    dec     a
    jr      nz, 130$
    ld      a, (_input + INPUT_KEY_UP)
    or      a
    jr      nz, 121$
    ld      hl, #PlayerSeikenduki
    jr      122$
121$:
    ld      hl, #PlayerAshigeri
;   jr      122$
122$:
    ld      (_player + PLAYER_PROC_L), hl
    xor     a
    ld      (_player + PLAYER_STATE), a
    jp      (hl)
;   jr      190$

    ; ジャンプ
130$:
    ld      a, (_input + INPUT_KEY_UP)
    or      a
    jr      z, 140$
    ld      a, (_input + INPUT_KEY_LEFT)
    or      a
    jr      z, 131$
    ld      hl, #PlayerJumpFront
    jr      132$
131$:
    ld      a, (_input + INPUT_KEY_RIGHT)
    or      a
    jr      z, 140$
    ld      hl, #PlayerJumpBack
;   jr      132$
132$:
    ld      (_player + PLAYER_PROC_L), hl
    xor     a
    ld      (_player + PLAYER_STATE), a
    jp      (hl)
;   jr      190$

    ; 移動
140$:
    ld      a, (_player + PLAYER_ANIMATION)
    and     #0x01
    jr      z, 149$
    ld      a, (_input + INPUT_KEY_LEFT)
    or      a
    jr      z, 141$
    ld      de, #0x00ff
    jr      142$
141$:
    ld      a, (_input + INPUT_KEY_RIGHT)
    or      a
    jr      z, 149$
    ld      de, #0x0001
142$:
    call    _PlayerMove
;   jr      149$
149$:

    ; 操作の完了
190$:

    ; 処理の完了
90$:

    ; レジスタの復帰

    ; 終了
    ret

; プレイヤが前にジャンプする
;
PlayerJumpFront:

    ; レジスタの保存

    ; 初期化
    ld      a, (_player + PLAYER_STATE)
    or      a
    jr      nz, 09$

    ; フラグの設定
    ld      hl, #(_player + PLAYER_FLAG)
    res     #PLAYER_FLAG_ACTIVE_BIT, (hl)

    ; 位置の更新
    ld      de, #0xfeff
    call    _PlayerMove

    ; アニメーションの設定
    ld      a, #PLAYER_ANIMATION_JUMP
    ld      (_player + PLAYER_ANIMATION), a

    ; パターンの設定
    ld      hl, #playerPatternJumpFront_0
    ld      (_player + PLAYER_PATTERN_L), hl

    ; 初期化の完了
    ld      hl, #(_player + PLAYER_STATE)
    inc     (hl)
09$:

    ; 0x01 : ジャンプの開始
10$:
    ld      a, (_player + PLAYER_STATE)
    dec     a
    jr      nz, 20$

    ; アニメーションの更新
    ld      hl, #(_player + PLAYER_ANIMATION)
    dec     (hl)
    jr      nz, 19$

    ; 位置の更新
    ld      de, #0xfefc
    call    _PlayerMove

    ; アニメーションの設定
    ld      a, #PLAYER_ANIMATION_JUMP
    ld      (_player + PLAYER_ANIMATION), a

    ; パターンの設定
    ld      hl, #playerPatternJumpFront_1
    ld      (_player + PLAYER_PATTERN_L), hl

    ; 処理の更新
    ld      hl, #(_player + PLAYER_STATE)
    inc     (hl)
19$:
    jr      90$

    ; 0x02 : ジャンプ中
20$:
    dec     a
    jr      nz, 30$

    ; アニメーションの更新
    ld      hl, #(_player + PLAYER_ANIMATION)
    dec     (hl)
    jr      nz, 29$

    ; フラグの設定
    ld      hl, #(_player + PLAYER_FLAG)
    set     #PLAYER_FLAG_ACTIVE_BIT, (hl)

    ; 位置の更新
    ld      de, #0x04fe
    call    _PlayerMove

    ; アニメーションの設定
    ld      a, #PLAYER_ANIMATION_LAND
    ld      (_player + PLAYER_ANIMATION), a

    ; パターンの設定
    ld      hl, #playerPatternStand
    ld      (_player + PLAYER_PATTERN_L), hl

    ; 処理の更新
    ld      hl, #(_player + PLAYER_STATE)
    inc     (hl)
29$:
    jr      90$

    ; 0x03 : 着地
30$:
;   dec     a
;   jr      nz, 90$

    ; アニメーションの更新
    ld      hl, #(_player + PLAYER_ANIMATION)
    dec     (hl)
    jr      nz, 39$

    ; 処理の更新
    ld      hl, #PlayerPlay
    ld      (_player + PLAYER_PROC_L), hl
    xor     a
    ld      (_player + PLAYER_STATE), a
39$:
;   jr      90$

    ; ジャンプの完了
90$:

    ; レジスタの復帰

    ; 終了
    ret

; プレイヤが後ろにジャンプする
;
PlayerJumpBack:

    ; レジスタの保存

    ; 初期化
    ld      a, (_player + PLAYER_STATE)
    or      a
    jr      nz, 09$

    ; フラグの設定
    ld      hl, #(_player + PLAYER_FLAG)
    res     #PLAYER_FLAG_ACTIVE_BIT, (hl)

    ; 位置の更新
    ld      de, #0xfe02
    call    _PlayerMove

    ; アニメーションの設定
    ld      a, #PLAYER_ANIMATION_JUMP
    ld      (_player + PLAYER_ANIMATION), a

    ; パターンの設定
    ld      hl, #playerPatternJumpBack_0
    ld      (_player + PLAYER_PATTERN_L), hl

    ; 初期化の完了
    ld      hl, #(_player + PLAYER_STATE)
    inc     (hl)
09$:

    ; 0x01 : ジャンプの開始
10$:
    ld      a, (_player + PLAYER_STATE)
    dec     a
    jr      nz, 20$

    ; アニメーションの更新
    ld      hl, #(_player + PLAYER_ANIMATION)
    dec     (hl)
    jr      nz, 19$

    ; 位置の更新
    ld      de, #0xfe02
    call    _PlayerMove

    ; アニメーションの設定
    ld      a, #PLAYER_ANIMATION_JUMP
    ld      (_player + PLAYER_ANIMATION), a

    ; パターンの設定
    ld      hl, #playerPatternJumpBack_1
    ld      (_player + PLAYER_PATTERN_L), hl

    ; 処理の更新
    ld      hl, #(_player + PLAYER_STATE)
    inc     (hl)
19$:
    jr      90$

    ; 0x02 : ジャンプ中
20$:
    dec     a
    jr      nz, 30$

    ; アニメーションの更新
    ld      hl, #(_player + PLAYER_ANIMATION)
    dec     (hl)
    jr      nz, 29$

    ; フラグの設定
    ld      hl, #(_player + PLAYER_FLAG)
    set     #PLAYER_FLAG_ACTIVE_BIT, (hl)

    ; 位置の更新
    ld      de, #0x0404
    call    _PlayerMove

    ; アニメーションの設定
    ld      a, #PLAYER_ANIMATION_LAND
    ld      (_player + PLAYER_ANIMATION), a

    ; パターンの設定
    ld      hl, #playerPatternStand
    ld      (_player + PLAYER_PATTERN_L), hl

    ; 処理の更新
    ld      hl, #(_player + PLAYER_STATE)
    inc     (hl)
29$:
    jr      90$

    ; 0x03 : 着地
30$:
;   dec     a
;   jr      nz, 90$

    ; アニメーションの更新
    ld      hl, #(_player + PLAYER_ANIMATION)
    dec     (hl)
    jr      nz, 39$

    ; 処理の更新
    ld      hl, #PlayerPlay
    ld      (_player + PLAYER_PROC_L), hl
    xor     a
    ld      (_player + PLAYER_STATE), a
39$:
;   jr      90$

    ; ジャンプの完了
90$:

    ; レジスタの復帰

    ; 終了
    ret

; プレイヤが正拳突きで攻撃する
;
PlayerSeikenduki:

    ; レジスタの保存

    ; 初期化
    ld      a, (_player + PLAYER_STATE)
    or      a
    jr      nz, 09$

    ; パターンの設定
    ld      hl, #playerPatternSeikenduki
    ld      (_player + PLAYER_PATTERN_L), hl

    ; 台詞の設定
    ld      hl, #playerSpeechSeikenduki
    ld      a, #PLAYER_ANIMATION_ATTACK
    call    PlayerSetSpeechOwner

    ; ヒット判定
    ld      de, #0xfefd
    call    PlayerAttack
    jr      nc, 00$
    ld      de, #40
    call    _EnemyTakeDamage
    call    PlayerAddPower
    ld      hl, #GAME_SCORE_SEIKENDUKI
    call    _GameAddScore
00$:

    ; SE の再生
    ld      a, #SOUND_SE_ATTACK
    call    _SoundPlaySe

    ; 初期化の完了
    ld      hl, #(_player + PLAYER_STATE)
    inc     (hl)
09$:

    ; 台詞の更新
    call    PlayerSpeechOwner
    jr      c, 19$

    ; 処理の更新
    ld      hl, #PlayerPlay
    ld      (_player + PLAYER_PROC_L), hl
    xor     a
    ld      (_player + PLAYER_STATE), a
19$:

    ; 攻撃の完了
90$:

    ; レジスタの復帰

    ; 終了
    ret

; プレイヤが足蹴りで攻撃する
;
PlayerAshigeri:

    ; レジスタの保存

    ; 初期化
    ld      a, (_player + PLAYER_STATE)
    or      a
    jr      nz, 09$

    ; パターンの設定
    ld      hl, #playerPatternAshigeri
    ld      (_player + PLAYER_PATTERN_L), hl

    ; 台詞の設定
    ld      hl, #playerSpeechAshigeri
    ld      a, #PLAYER_ANIMATION_ATTACK
    call    PlayerSetSpeechOwner

    ; ヒット判定
    ld      de, #0xfcfb
    call    PlayerAttack
    jr      nc, 00$
    ld      de, #80
    call    _EnemyTakeDamage
    call    PlayerAddPower
    ld      hl, #GAME_SCORE_ASHIGERI
    call    _GameAddScore
00$:

    ; SE の再生
    ld      a, #SOUND_SE_ATTACK
    call    _SoundPlaySe

    ; 初期化の完了
    ld      hl, #(_player + PLAYER_STATE)
    inc     (hl)
09$:

    ; 台詞の更新
    call    PlayerSpeechOwner
    jr      c, 19$

    ; 処理の更新
    ld      hl, #PlayerPlay
    ld      (_player + PLAYER_PROC_L), hl
    xor     a
    ld      (_player + PLAYER_STATE), a
19$:

    ; 攻撃の完了
90$:

    ; レジスタの復帰

    ; 終了
    ret

; プレイヤが秘孔をつく
;
PlayerHiko:

    ; レジスタの保存

    ; 初期化
    ld      a, (_player + PLAYER_STATE)
    or      a
    jr      nz, 09$

    ; 秘孔の選択
00$:
    call    _SystemGetRandom
    and     #0x03
    cp      #0x03
    jr      nc, 00$
    ld      (_player + PLAYER_PARAM_0), a

    ; アニメーションの設定
    ld      a, #PLAYER_ANIMATION_ATTACK
    ld      (_player + PLAYER_ANIMATION), a

    ; パターンの設定
    ld      hl, #playerPatternHiko_0
    ld      a, (_player + PLAYER_PARAM_0)
    call    PlayerSelectPattern

    ; ヒット判定
    ld      de, #0xfdfd
    call    PlayerAttack

    ; 力の使用
    call    PlayerUsePower

    ; SE の再生
    ld      a, #SOUND_SE_ATTACK
    call    _SoundPlaySe

    ; 初期化の完了
    ld      hl, #(_player + PLAYER_STATE)
    inc     (hl)
09$:

    ; 0x01 : 攻撃の開始
10$:
    ld      a, (_player + PLAYER_STATE)
    dec     a
    jr      nz, 20$

    ; アニメーションの更新
    ld      hl, #(_player + PLAYER_ANIMATION)
    dec     (hl)
    jr      nz, 19$

    ; ヒットしたかどうか
    ld      a, (_player + PLAYER_FLAG)
    bit     #PLAYER_FLAG_HIT_BIT, a
    jp      z, 90$

    ; 台詞の設定
    ld      hl, #playerSpeechHiko_0
    ld      a, (_player + PLAYER_PARAM_0)
    ld      c, a
    ld      a, #PLAYER_ANIMATION_SPEECH
    call    PlayerSelectSpeechOwner

    ; 状態の更新
    ld      hl, #(_player + PLAYER_STATE)
    inc     (hl)
19$:
    jp      99$

    ; 0x02 : 会話０
20$:
    dec     a
    jr      nz, 30$

    ; 台詞の更新
    call    PlayerSpeechOwner
    jr      c, 29$

    ; 技の効果
    call    _EnemyGetType
    cp      #ENEMY_TYPE_RAOH
    jr      z, 22$
    cp      #ENEMY_TYPE_HEART
    jr      nz, 21$
    ld      a, (_player + PLAYER_PARAM_0)
    cp      #0x02
    jr      z, 22$
21$:

    ; パターンの設定
    ld      hl, #playerPatternHiko_1
    ld      (_player + PLAYER_PATTERN_L), hl

    ; 会話の選択
    ld      hl, #playerTalkHiko_1
    ld      a, (_player + PLAYER_PARAM_0)
    ld      c, a
    call    PlayerSelectTalk

    ; 状態の更新
    ld      hl, #(_player + PLAYER_STATE)
    inc     (hl)
    jr      29$

    ; 技が効かない
22$:
    ld      hl, #PlayerNoEffect
    ld      (_player + PLAYER_PROC_L), hl
    xor     a
    ld      (_player + PLAYER_STATE), a
29$:
    jr      99$

    ; 0x03 ; 会話１
30$:
    dec     a
    jr      nz, 40$

    ; 会話の更新
    call    PlayerTalk
    jr      c, 39$

    ; 会話の選択
31$:
    call    _SystemGetRandom
    and     #0x07
    cp      #0x05
    jr      nc, 31$
    ld      (_player + PLAYER_PARAM_0), a
    ld      c, a
    ld      hl, #playerTalkHiko_2
    call    PlayerSelectTalk

    ; 状態の更新
    ld      hl, #(_player + PLAYER_STATE)
    inc     (hl)
39$:
    jr      99$

    ; 0x04 ; 会話２
40$:
    dec     a
    jr      nz, 50$

    ; 会話の更新
    call    PlayerTalk
    jr      c, 49$

    ; パターンの設定
    ld      a, (_player + PLAYER_PARAM_0)
    add     a, #ENEMY_PATTERN_HIKO_0
    call    _EnemySetPattern

    ; 台詞の選択
    ld      hl, #playerSpeechHiko_3
    ld      a, (_player + PLAYER_PARAM_0)
    ld      c, a
    ld      a, #PLAYER_ANIMATION_SPEECH
    call    PlayerSelectSpeechOther

    ; 状態の更新
    ld      hl, #(_player + PLAYER_STATE)
    inc     (hl)
49$:
    jr      99$

    ; 0x05 ; 会話３
50$:
;   dec     a
;   jr      nz, 60$

    ; 台詞の更新
    call    PlayerSpeechOther
    jr      c, 59$

    ; エネミーへのダメージ
    call    _EnemyTakeSpecial
    jr      90$
59$:
    jr      99$

    ; 攻撃の完了
90$:
    call    PlayerClearPower
    ld      hl, #PlayerPlay
    ld      (_player + PLAYER_PROC_L), hl
    xor     a
    ld      (_player + PLAYER_STATE), a
99$:

    ; レジスタの復帰

    ; 終了
    ret

; プレイヤが北斗残悔拳で攻撃する
;
PlayerZankaiken:

    ; レジスタの保存

    ; 初期化
    ld      a, (_player + PLAYER_STATE)
    or      a
    jr      nz, 09$

    ; アニメーションの設定
    ld      a, #PLAYER_ANIMATION_ATTACK
    ld      (_player + PLAYER_ANIMATION), a

    ; パターンの設定
    ld      hl, #playerPatternZankaiken
    ld      (_player + PLAYER_PATTERN_L), hl

    ; ヒット判定
    ld      de, #0xfdfd
    call    PlayerAttack

    ; 力の使用
    call    PlayerUsePower

    ; SE の再生
    ld      a, #SOUND_SE_ATTACK
    call    _SoundPlaySe

    ; 初期化の完了
    ld      hl, #(_player + PLAYER_STATE)
    inc     (hl)
09$:

    ; 0x01 : 攻撃の開始
10$:
    ld      a, (_player + PLAYER_STATE)
    dec     a
    jr      nz, 20$

    ; アニメーションの更新
    ld      hl, #(_player + PLAYER_ANIMATION)
    dec     (hl)
    jr      nz, 19$

    ; ヒットしたかどうか
    ld      a, (_player + PLAYER_FLAG)
    bit     #PLAYER_FLAG_HIT_BIT, a
    jr      z, 90$

    ; 会話の設定
    ld      hl, #playerTalkZankaiken_0
    call    PlayerSetTalk

    ; 状態の更新
    ld      hl, #(_player + PLAYER_STATE)
    inc     (hl)
19$:
    jr      99$

    ; 0x02 : 会話０
20$:
    dec     a
    jr      nz, 30$

    ; 会話の更新
    call    PlayerTalk
    jr      c, 29$

    ; 技の効果
    call    _EnemyGetType
    cp      #ENEMY_TYPE_HEART
    jr      z, 21$
    cp      #ENEMY_TYPE_REI
    jr      z, 21$
    cp      #ENEMY_TYPE_RAOH
    jr      z, 21$

    ; パターンの設定
    ld      hl, #playerPatternStand
    ld      (_player + PLAYER_PATTERN_L), hl

    ; 会話の設定
    ld      hl, #playerTalkZankaiken_1
    call    PlayerSetTalk

    ; 状態の更新
    ld      hl, #(_player + PLAYER_STATE)
    inc     (hl)
    jr      29$

    ; 技が効かない
21$:
    ld      hl, #PlayerNoEffect
    ld      (_player + PLAYER_PROC_L), hl
    xor     a
    ld      (_player + PLAYER_STATE), a
29$:
    jr      99$

    ; 0x03 ; 会話１
30$:
;   dec     a
;   jr      nz, 40$

    ; 会話の更新
    call    PlayerTalk
    jr      c, 39$

    ; エネミーへのダメージ
    call    _EnemyTakeSpecial
    jr      90$
39$:
    jr      99$

    ; 攻撃の完了
90$:
    call    PlayerClearPower
    ld      hl, #PlayerPlay
    ld      (_player + PLAYER_PROC_L), hl
    xor     a
    ld      (_player + PLAYER_STATE), a
99$:

    ; レジスタの復帰

    ; 終了
    ret

; プレイヤが北斗百裂拳で攻撃する
;
PlayerHyakuretsuken:

    ; レジスタの保存

    ; 初期化
    ld      a, (_player + PLAYER_STATE)
    or      a
    jr      nz, 09$

    ; アニメーションの設定
    ld      a, #0x60
    ld      (_player + PLAYER_ANIMATION), a

    ; 台詞の設定
    ld      hl, #playerSpeechHyakuretsuken_0
    call    _PlayerSetSpeech

    ; ヒット判定
    ld      de, #0xfdfd
    call    PlayerAttack

    ; 力の使用
    call    PlayerUsePower

    ; 初期化の完了
    ld      hl, #(_player + PLAYER_STATE)
    inc     (hl)
09$:

    ; 0x01 : 攻撃０
10$:
    ld      a, (_player + PLAYER_STATE)
    dec     a
    jr      nz, 20$

    ; パターンの設定
    ld      a, (_player + PLAYER_ANIMATION)
    and     #0x03
    ld      hl, #playerPatternHyakuretsuken_0
    call    PlayerSelectPattern

    ; SE の再生
    ld      a, (_player + PLAYER_ANIMATION)
    and     #0x03
    ld      a, #SOUND_SE_ATTACK
    call    z, _SoundPlaySe

    ; アニメーションの更新
    ld      hl, #(_player + PLAYER_ANIMATION)
    dec     (hl)
    jr      nz, 19$

    ; 台詞の消去
    call    _PlayerClearSpeech

    ; ヒットしたかどうか
    ld      a, (_player + PLAYER_FLAG)
    bit     #PLAYER_FLAG_HIT_BIT, a
    jp      z, 90$

    ; 技の効果
    call    _EnemyGetType
    cp      #ENEMY_TYPE_HEART
    jr      z, 11$
    cp      #ENEMY_TYPE_SHEW
    jr      z, 11$
    cp      #ENEMY_TYPE_RAOH
    jr      z, 11$

    ; 位置の更新
    ld      de, #0x00ff
    call    _PlayerMove
    ld      de, #0xff00
    call    _EnemyMove

    ; アニメーションの設定
    ld      a, #0x60
    ld      (_player + PLAYER_ANIMATION), a

    ; 台詞の設定
    ld      hl, #playerSpeechHyakuretsuken_1
    call    _PlayerSetSpeech

    ; 状態の更新
    ld      hl, #(_player + PLAYER_STATE)
    inc     (hl)
    jr      19$

    ; 技が効かない
11$:
    ld      hl, #PlayerNoEffect
    ld      (_player + PLAYER_PROC_L), hl
    xor     a
    ld      (_player + PLAYER_STATE), a
19$:
    jp      99$

    ; 0x02 : 攻撃１
20$:
    dec     a
    jr      nz, 30$

    ; パターンの設定
    ld      a, (_player + PLAYER_ANIMATION)
    and     #0x03
    ld      hl, #playerPatternHyakuretsuken_1
    call    PlayerSelectPattern

    ; SE の再生
    ld      a, (_player + PLAYER_ANIMATION)
    and     #0x03
    ld      a, #SOUND_SE_ATTACK
    call    z, _SoundPlaySe

    ; アニメーションの更新
    ld      hl, #(_player + PLAYER_ANIMATION)
    dec     (hl)
    jr      nz, 29$

    ; 台詞の消去
    call    _PlayerClearSpeech
    
    ; 位置の更新
    ld      de, #0x01ff
    call    _EnemyMove

    ; アニメーションの設定
    ld      a, #PLAYER_ANIMATION_JUMP
    ld      (_player + PLAYER_ANIMATION), a

    ; パターンの設定
    ld      a, #ENEMY_PATTERN_HYAKURETSUKEN_0
    call    _EnemySetPattern

    ; 状態の更新
    ld      hl, #(_player + PLAYER_STATE)
    inc     (hl)
29$:
    jr      99$

    ; 0x03 : やられ０
30$:
    dec     a
    jr      nz, 40$

    ; アニメーションの更新
    ld      hl, #(_player + PLAYER_ANIMATION)
    dec     (hl)
    jr      nz, 39$

    ; 位置の更新
    ld      de, #0x00ff
    call    _EnemyMove

    ; パターンの設定
    ld      a, #ENEMY_PATTERN_HYAKURETSUKEN_1
    call    _EnemySetPattern

    ; 台詞の設定
    ld      hl, #playerSpeechHyakuretsuken_2
    ld      a, #PLAYER_ANIMATION_SPEECH
    call    PlayerSetSpeechOther

    ; 状態の更新
    ld      hl, #(_player + PLAYER_STATE)
    inc     (hl)
39$:
    jr      99$

    ; 0x04 : やられ１
40$:
    dec     a
    jr      nz, 50$

    ; 台詞の更新
    call    PlayerSpeechOther
    jr      c, 49$

    ; 会話の設定
    ld      hl, #playerTalkHyakuretsuken_3
    call    PlayerSetTalk

    ; 状態の更新
    ld      hl, #(_player + PLAYER_STATE)
    inc     (hl)
;   jr      49$
49$:
    jr      99$

    ; 0x05 : 会話０
50$:
    dec     a
    jr      nz, 60$

    ; 会話の更新
    call    PlayerTalk
    jr      c, 59$

    ; パターンの設定
    ld      a, #ENEMY_PATTERN_STAND
    call    _EnemySetPattern

    ; 会話の設定
51$:
    call    _SystemGetRandom
    and     #0x07
    cp      #0x06
    jr      nc, 51$
    ld      c, a
    ld      hl, #playerTalkHyakuretsuken_4
    call    PlayerSelectTalk

    ; 状態の更新
    ld      hl, #(_player + PLAYER_STATE)
    inc     (hl)
59$:
    jr      99$

    ; 0x06 : 会話１
60$:
;   dec     a
;   jr      nz, 70$

    ; 会話の更新
    call    PlayerTalk
    jr      c, 69$

    ; エネミーへのダメージ
    call    _EnemyTakeSpecial
    jr      90$
69$:
    jr      99$

    ; 攻撃の完了
90$:
    call    PlayerClearPower
    ld      hl, #PlayerPlay
    ld      (_player + PLAYER_PROC_L), hl
    xor     a
    ld      (_player + PLAYER_STATE), a
99$:

    ; レジスタの復帰

    ; 終了
    ret

; プレイヤが交首破顔拳で攻撃する
;
PlayerHaganken:

    ; レジスタの保存

    ; 初期化
    ld      a, (_player + PLAYER_STATE)
    or      a
    jr      nz, 09$

    ; パターンの設定
    ld      hl, #playerPatternHaganken_0
    ld      (_player + PLAYER_PATTERN_L), hl

    ; 台詞の設定
    ld      hl, #playerSpeechHaganken_0
    ld      a, #PLAYER_ANIMATION_ATTACK
    call    PlayerSetSpeechOwner

    ; ヒット判定
    ld      de, #0xfdfd
    call    PlayerAttack

    ; 力の使用
    call    PlayerUsePower

    ; SE の再生
    ld      a, #SOUND_SE_ATTACK
    call    _SoundPlaySe

    ; 初期化の完了
    ld      hl, #(_player + PLAYER_STATE)
    inc     (hl)
09$:

    ; 0x01 : 攻撃０
10$:
    ld      a, (_player + PLAYER_STATE)
    dec     a
    jr      nz, 20$

    ; 台詞の更新
    call    PlayerSpeechOwner
    jr      c, 19$

    ; ヒットしたかどうか
    ld      a, (_player + PLAYER_FLAG)
    bit     #PLAYER_FLAG_HIT_BIT, a
    jp      z, 90$

    ; 位置の更新
    ld      de, #0xfd00
    call    _PlayerMove

    ; アニメーションの設定
    ld      a, #PLAYER_ANIMATION_JUMP
    ld      (_player + PLAYER_ANIMATION), a

    ; パターンの設定
    ld      hl, #playerPatternHaganken_1
    ld      (_player + PLAYER_PATTERN_L), hl

    ; 状態の更新
    ld      hl, #(_player + PLAYER_STATE)
    inc     (hl)
19$:
    jp      99$

    ; 0x02 : 攻撃１
20$:
    dec     a
    jr      nz, 30$

    ; アニメーションの更新
    ld      hl, #(_player + PLAYER_ANIMATION)
    dec     (hl)
    jr      nz, 29$

    ; 位置の更新
    ld      de, #0x00fd
    call    _PlayerMove

    ; アニメーションの設定
    ld      a, #PLAYER_ANIMATION_JUMP
    ld      (_player + PLAYER_ANIMATION), a

    ; パターンの設定
    ld      hl, #playerPatternHaganken_2
    ld      (_player + PLAYER_PATTERN_L), hl

    ; 状態の更新
    ld      hl, #(_player + PLAYER_STATE)
    inc     (hl)
29$:
    jr      99$

    ; 0x03 : 攻撃２
30$:
    dec     a
    jr      nz, 40$

    ; アニメーションの更新
    ld      hl, #(_player + PLAYER_ANIMATION)
    dec     (hl)
    jr      nz, 39$

    ; 位置の更新
    ld      de, #0x03fd
    call    _PlayerMove

    ; パターンの設定
    ld      hl, #playerPatternStand
    ld      (_player + PLAYER_PATTERN_L), hl

    ; 会話の設定
    ld      hl, #playerTalkHaganken_1
    call    PlayerSetTalk

    ; 状態の更新
    ld      hl, #(_player + PLAYER_STATE)
    inc     (hl)
39$:
    jr      99$

    ; 0x04 : 会話０
40$:
    dec     a
    jr      nz, 50$

    ; 会話の更新
    call    PlayerTalk
    jr      c, 49$

    ; 技の効果
    call    _EnemyGetType
    cp      #ENEMY_TYPE_HEART
    jr      z, 41$
    cp      #ENEMY_TYPE_REI
    jr      z, 41$
    cp      #ENEMY_TYPE_JAGI
    jr      z, 41$
    cp      #ENEMY_TYPE_JUDA
    jr      z, 41$
    cp      #ENEMY_TYPE_SHEW
    jr      z, 41$
    cp      #ENEMY_TYPE_RAOH
    jr      z, 41$

    ; 会話の設定
    ld      hl, #playerTalkHaganken_2
    call    PlayerSetTalk

    ; 状態の更新
    ld      hl, #(_player + PLAYER_STATE)
    inc     (hl)
    jr      49$

    ; 技が効かない
41$:
    ld      hl, #PlayerNoEffect
    ld      (_player + PLAYER_PROC_L), hl
    xor     a
    ld      (_player + PLAYER_STATE), a
49$:
    jr      99$

    ; 0x05 : 会話１
50$:
;   dec     a
;   jr      nz, 60$

    ; 会話の更新
    call    PlayerTalk
    jr      c, 59$

    ; エネミーへのダメージ
    call    _EnemyTakeSpecial
    jr      90$
59$:
    jr      99$

    ; 攻撃の完了
90$:
    call    PlayerClearPower
    ld      hl, #PlayerPlay
    ld      (_player + PLAYER_PROC_L), hl
    xor     a
    ld      (_player + PLAYER_STATE), a
99$:

    ; レジスタの復帰

    ; 終了
    ret

; プレイヤが北斗壊骨拳で攻撃する
;
PlayerKaikotsuken:

    ; レジスタの保存

    ; 初期化
    ld      a, (_player + PLAYER_STATE)
    or      a
    jr      nz, 09$

    ; アニメーションの設定
    ld      a, #PLAYER_ANIMATION_ATTACK
    ld      (_player + PLAYER_ANIMATION), a

    ; パターンの設定
    ld      hl, #playerPatternKaikotsuken_0
    ld      (_player + PLAYER_PATTERN_L), hl

    ; ヒット判定
    ld      de, #0xfdfd
    call    PlayerAttack

    ; 力の使用
    call    PlayerUsePower

    ; SE の再生
    ld      a, #SOUND_SE_ATTACK
    call    _SoundPlaySe

    ; 初期化の完了
    ld      hl, #(_player + PLAYER_STATE)
    inc     (hl)
09$:

    ; 0x01 : 攻撃０
10$:
    ld      a, (_player + PLAYER_STATE)
    dec     a
    jr      nz, 20$

    ; アニメーションの更新
    ld      hl, #(_player + PLAYER_ANIMATION)
    dec     (hl)
    jr      nz, 19$

    ; ヒットしたかどうか
    ld      a, (_player + PLAYER_FLAG)
    bit     #PLAYER_FLAG_HIT_BIT, a
    jr      z, 90$

    ; 会話の設定
    ld      hl, #playerTalkKaikotsuken_0
    call    PlayerSetTalk

    ; 状態の更新
    ld      hl, #(_player + PLAYER_STATE)
    inc     (hl)
19$:
    jr      99$

    ; 0x02 : 会話０
20$:
;   dec     a
;   jr      nz, 30$

    ; 会話の更新
    call    PlayerTalk
    jr      c, 29$

    ; 技の効果
    call    _EnemyGetType
    cp      #ENEMY_TYPE_HEART
    jr      z, 21$
    cp      #ENEMY_TYPE_REI
    jr      z, 21$
    cp      #ENEMY_TYPE_JAGI
    jr      z, 21$
    cp      #ENEMY_TYPE_JUDA
    jr      z, 21$
    cp      #ENEMY_TYPE_SHEW
    jr      z, 21$

    ; エネミーへのダメージ
    call    _EnemyTakeSpecial
    jr      90$

    ; 技が効かない
21$:
    ld      hl, #PlayerNoEffect
    ld      (_player + PLAYER_PROC_L), hl
    xor     a
    ld      (_player + PLAYER_STATE), a
29$:
    jr      99$

    ; 攻撃の完了
90$:
    call    PlayerClearPower
    ld      hl, #PlayerPlay
    ld      (_player + PLAYER_PROC_L), hl
    xor     a
    ld      (_player + PLAYER_STATE), a
99$:

    ; レジスタの復帰

    ; 終了
    ret

; プレイヤが北斗柔破斬で攻撃する
;
PlayerJuhazan:

    ; レジスタの保存

    ; 初期化
    ld      a, (_player + PLAYER_STATE)
    or      a
    jr      nz, 09$

    ; アニメーションの設定
    ld      a, #0x60
    ld      (_player + PLAYER_ANIMATION), a

    ; 台詞の設定
    ld      hl, #playerSpeechJuhazan_0
    call    _PlayerSetSpeech

    ; ヒット判定
    ld      de, #0xfcfc
    call    PlayerAttack

    ; 力の使用
    call    PlayerUsePower

    ; 初期化の完了
    ld      hl, #(_player + PLAYER_STATE)
    inc     (hl)
09$:

    ; 0x01 : 攻撃０
10$:
    ld      a, (_player + PLAYER_STATE)
    dec     a
    jr      nz, 20$

    ; パターンの設定
    ld      a, (_player + PLAYER_ANIMATION)
    and     #0x03
    ld      hl, #playerPatternJuhazan_0
    call    PlayerSelectPattern

    ; SE の再生
    ld      a, (_player + PLAYER_ANIMATION)
    and     #0x03
    ld      a, #SOUND_SE_ATTACK
    call    z, _SoundPlaySe

    ; アニメーションの更新
    ld      hl, #(_player + PLAYER_ANIMATION)
    dec     (hl)
    jr      nz, 19$

    ; 台詞の消去
    call    _PlayerClearSpeech

    ; ヒットしたかどうか
    ld      a, (_player + PLAYER_FLAG)
    bit     #PLAYER_FLAG_HIT_BIT, a
    jp      z, 90$

    ; 技の効果
    call    _EnemyGetType
    cp      #ENEMY_TYPE_REI
    jr      z, 11$
    cp      #ENEMY_TYPE_JUDA
    jr      z, 11$
    cp      #ENEMY_TYPE_RAOH
    jr      z, 11$
    cp      #ENEMY_TYPE_HEART
    jr      nz, 12$

    ; パターンの設定
    ld      hl, #playerPatternStand
    ld      (_player + PLAYER_PATTERN_L), hl
    ld      a, #ENEMY_PATTERN_JUHAZAN_0
    call    _EnemySetPattern

    ; 台詞の設定
    ld      hl, #playerSpeechJuhazan_1
    ld      a, #PLAYER_ANIMATION_SPEECH
    call    PlayerSetSpeechOther

    ; 状態の更新
    ld      hl, #(_player + PLAYER_STATE)
    inc     (hl)
    jr      19$

    ; 技が効かない
11$:
    ld      hl, #PlayerNoEffect
    ld      (_player + PLAYER_PROC_L), hl
    xor     a
    ld      (_player + PLAYER_STATE), a
    jr      19$

    ; ハート以外
12$:
    call    _EnemyTakeSpecial
    jr      90$
19$:
    jr      99$

    ; 0x02 : 攻撃１
20$:
    dec     a
    jr      nz, 30$

    ; 台詞の更新
    call    PlayerSpeechOther
    jr      c, 29$

    ; パターンの設定
    ld      hl, #playerPatternJuhazan_1
    ld      (_player + PLAYER_PATTERN_L), hl

    ; 台詞の設定
    ld      hl, #playerSpeechJuhazan_2
    ld      a, #PLAYER_ANIMATION_SPEECH
    call    PlayerSetSpeechOwner

    ; SE の再生
    ld      a, #SOUND_SE_ATTACK
    call    _SoundPlaySe

    ; 状態の更新
    ld      hl, #(_player + PLAYER_STATE)
    inc     (hl)
29$:
    jr      99$

    ; 0x03 : 攻撃２
30$:
    dec     a
    jr      nz, 40$

    ; 台詞の更新
    call    PlayerSpeechOwner
    jr      c, 39$

    ; パターンの設定
    ld      a, #ENEMY_PATTERN_JUHAZAN_1
    call    _EnemySetPattern

    ; 会話の設定
    ld      hl, #playerTalkJuhazan_3
    call    PlayerSetTalk

    ; 状態の更新
    ld      hl, #(_player + PLAYER_STATE)
    inc     (hl)
39$:
    jr      99$

    ; 0x04 : 会話０
40$:
;   dec     a
;   jr      nz, 50$

    ; 会話の更新
    call    PlayerTalk
    jr      c, 49$

    ; エネミーへのダメージ
    call    _EnemyTakeSpecial
    jr      90$
49$:
    jr      99$

    ; 攻撃の完了
90$:
    call    PlayerClearPower
    ld      hl, #PlayerPlay
    ld      (_player + PLAYER_PROC_L), hl
    xor     a
    ld      (_player + PLAYER_STATE), a
99$:

    ; レジスタの復帰

    ; 終了
    ret

; プレイヤが二指真空把で防御する
;
PlayerNishishinkuha:

    ; レジスタの保存

    ; 初期化
    ld      a, (_player + PLAYER_STATE)
    or      a
    jr      nz, 09$

    ; パターンの設定
    ld      hl, #playerPatternNishishinkuha
    ld      (_player + PLAYER_PATTERN_L), hl

    ; 会話の設定
    ld      hl, #playerTalkNishishinkuha
    call    PlayerSetTalk

    ; エネミーのロック
    call    _EnemyLock

    ; スコアの加算
    ld      hl, #GAME_SCORE_GUARD
    call    _GameAddScore

    ; SE の再生
    ld      a, #SOUND_SE_GUARD
    call    _SoundPlaySe

    ; 初期化の完了
    ld      hl, #(_player + PLAYER_STATE)
    inc     (hl)
09$:

    ; 0x01 : 会話
10$:
;   ld      a, (_player + PLAYER_STATE)
;   dec     a
;   jr      nz, 20$

    ; 会話の更新
    call    PlayerTalk
    jr      c, 19$

    ; エネミーのアンロック
    call    _EnemyUnlock
    jr      90$
19$:
    jr      99$

    ; 攻撃の完了
90$:
    ld      hl, #PlayerPlay
    ld      (_player + PLAYER_PROC_L), hl
    xor     a
    ld      (_player + PLAYER_STATE), a
99$:

    ; レジスタの復帰

    ; 終了
    ret

; プレイヤの技が効かない
;
PlayerNoEffect:

    ; レジスタの保存

    ; 初期化
    ld      a, (_player + PLAYER_STATE)
    or      a
    jr      nz, 09$

    ; パターンの設定
    ld      hl, #playerPatternStand
    ld      (_player + PLAYER_PATTERN_L), hl

    ; 台詞の設定
00$:
    call    _SystemGetRandom
    and     #0x07
    cp      #0x05
    jr      nc, 00$
    ld      hl, #playerSpeechNoEffect
    ld      c, a
    ld      a, #PLAYER_ANIMATION_SPEECH
    call    PlayerSelectSpeechOwner

    ; 初期化の完了
    ld      hl, #(_player + PLAYER_STATE)
    inc     (hl)
09$:

    ; アニメーションの更新
    ld      hl, #(_player + PLAYER_ANIMATION)
    dec     (hl)
    jr      nz, 19$

    ; エネミーのアンロック
    call    _EnemyUnlock

    ; 力のクリア
    call    PlayerClearPower

    ; 処理の更新
    ld      hl, #PlayerPlay
    ld      (_player + PLAYER_PROC_L), hl
    xor     a
    ld      (_player + PLAYER_STATE), a
19$:

    ; レジスタの復帰

    ; 終了
    ret

; プレイヤが待機する
;
PlayerIdle:

    ; レジスタの保存

    ; レジスタの復帰

    ; 終了
    ret

; プレイヤがダメージを受ける
;
PlayerDamage:

    ; レジスタの保存

    ; 初期化
    ld      a, (_player + PLAYER_STATE)
    or      a
    jr      nz, 09$

    ; フラグの設定
    ld      hl, #(_player + PLAYER_FLAG)
    res     #PLAYER_FLAG_ACTIVE_BIT, (hl)

    ; アニメーションの設定
    ld      a, #PLAYER_ANIMATION_DAMAGE
    ld      (_player + PLAYER_ANIMATION), a

    ; カラーテーブルの設定
    ld      a, #VDP_COLOR_MEDIUM_RED
    call    PlayerSetColor

    ; 体力の確認
    ld      hl, (_player + PLAYER_LIFE_L)
    ld      a, h
    or      l
    jr      z, 00$

    ; 体力あり

    ; 位置の更新
    ld      de, #0x0002
    ld      a, (_player + PLAYER_DAMAGE)
    cp      #ENEMY_ATTACK_ARROW
    call    nz, _PlayerMove

    ; パターンの選択
    ld      hl, #playerPatternDamageLive
    ld      a, (_player + PLAYER_DAMAGE)
    call    PlayerSelectPattern
    jr      01$

    ; 体力なし
00$:

    ; 位置の更新
    ld      de, #0x0001
    ld      a, (_player + PLAYER_DAMAGE)
    or      a
    call    z, _PlayerMove

    ; パターンの選択
    ld      hl, #playerPatternDamageDead
    ld      a, (_player + PLAYER_DAMAGE)
    call    PlayerSelectPattern
;   jr      01$
01$:

    ; 技のキャンセル
    ld      hl, #(_player + PLAYER_POWER)
    ld      a, (hl)
    cp      #(PLAYER_POWER_MAXIMUM + 0x01)
    jr      c, 02$
    ld      (hl), #0x00
02$:
    call    PlayerAddPower

    ; SE の再生
    ld      a, #SOUND_SE_DAMAGE
    call    _SoundPlaySe

    ; 初期化の完了
    ld      hl, #(_player + PLAYER_STATE)
    inc     (hl)
09$:

    ; アニメーションの更新
    ld      hl, #(_player + PLAYER_ANIMATION)
    dec     (hl)
    jr      nz, 19$

    ; 体力の確認
    ld      hl, (_player + PLAYER_LIFE_L)
    ld      a, h
    or      l
    jr      z, 10$

    ; 処理の更新
    ld      hl, #PlayerPlay
    ld      (_player + PLAYER_PROC_L), hl
    xor     a
    ld      (_player + PLAYER_STATE), a
    jr      19$

    ; 死亡
10$:
    ld      a, (_player + PLAYER_DAMAGE)
    add     a, a
    ld      e, a
    ld      d, #0x00
    ld      hl, #playerDeadProc
    add     hl, de
    ld      e, (hl)
    inc     hl
    ld      d, (hl)
    ld      (_player + PLAYER_PROC_L), de
    xor     a
    ld      (_player + PLAYER_STATE), a
    jr      19$
19$:

    ; レジスタの復帰

    ; 終了
    ret

; プレイヤが死亡する
;
PlayerDead_0:

    ; レジスタの保存

    ; 初期化
    ld      a, (_player + PLAYER_STATE)
    or      a
    jr      nz, 09$

    ; フラグの設定
    ld      hl, #(_player + PLAYER_FLAG)
    res     #PLAYER_FLAG_ACTIVE_BIT, (hl)

    ; パターンの設定
    ld      hl, #playerPatternDead_0
    ld      (_player + PLAYER_PATTERN_L), hl

    ; カラーテーブルの設定
    ld      a, #VDP_COLOR_MEDIUM_RED
    call    PlayerSetColor

    ; 会話の設定
    ld      hl, #playerTalkDead_0
    call    PlayerSetTalk

    ; エネミーをロック
    call    _EnemyLock
    call    _EnemyClearSpeech

    ; 初期化の完了
    ld      hl, #(_player + PLAYER_STATE)
    inc     (hl)
09$:

    ; 0x01 : 会話０
10$:
    ld      a, (_player + PLAYER_STATE)
    dec     a
    jr      nz, 20$

    ; 会話の更新
    call    PlayerTalk
    jr      c, 19$

    ; フラグの設定
    ld      hl, #(_player + PLAYER_FLAG)
    set     #PLAYER_FLAG_DEAD_BIT, (hl)

    ; 状態の更新
    ld      hl, #(_player + PLAYER_STATE)
    inc     (hl)
19$:
    jr      90$

    ; 0x02 : 待機
20$:
;   dec     a
;   jr      nz, 30$

    ; 死亡の完了
90$:

    ; レジスタの復帰

    ; 終了
    ret

PlayerDead_2:

    ; レジスタの保存

    ; 初期化
    ld      a, (_player + PLAYER_STATE)
    or      a
    jr      nz, 09$

    ; フラグの設定
    ld      hl, #(_player + PLAYER_FLAG)
    res     #PLAYER_FLAG_ACTIVE_BIT, (hl)

    ; パターンの設定
    ld      hl, #playerPatternDead_2_0
    ld      (_player + PLAYER_PATTERN_L), hl

    ; カラーテーブルの設定
    ld      a, #VDP_COLOR_MEDIUM_RED
    call    PlayerSetColor

    ; 台詞の設定
    ld      hl, #playerSpeechDead_2_0
    ld      a, #PLAYER_ANIMATION_DEAD
    call    PlayerSetSpeechOwner

    ; エネミーをロック
    call    _EnemyLock
    call    _EnemyClearSpeech

    ; 初期化の完了
    ld      hl, #(_player + PLAYER_STATE)
    inc     (hl)
09$:

    ; 0x01 : 会話０
10$:
    ld      a, (_player + PLAYER_STATE)
    dec     a
    jr      nz, 20$

    ; 台詞の更新
    call    PlayerSpeechOwner
    jr      c, 19$

    ; パターンの設定
    ld      hl, #playerPatternDead_2_1
    ld      (_player + PLAYER_PATTERN_L), hl

    ; 台詞の設定
    ld      hl, #playerSpeechDead_2_1
    ld      a, #PLAYER_ANIMATION_DEAD
    call    PlayerSetSpeechOwner

    ; 状態の更新
    ld      hl, #(_player + PLAYER_STATE)
    inc     (hl)
19$:
    jr      90$

    ; 0x02 : 会話１
20$:
    dec     a
    jr      nz, 30$

    ; 台詞の更新
    call    PlayerSpeechOwner
    jr      c, 29$

    ; フラグの設定
    ld      hl, #(_player + PLAYER_FLAG)
    set     #PLAYER_FLAG_DEAD_BIT, (hl)

    ; 状態の更新
    ld      hl, #(_player + PLAYER_STATE)
    inc     (hl)
29$:
    jr      90$

    ; 0x03 : 待機
30$:
;   dec     a
;   jr      nz, 40$

    ; 死亡の完了
90$:

    ; レジスタの復帰

    ; 終了
    ret

PlayerDead_3:

    jr      PlayerDead_4

PlayerDead_4:

    ; レジスタの保存

    ; 初期化
    ld      a, (_player + PLAYER_STATE)
    or      a
    jr      nz, 09$

    ; フラグの設定
    ld      hl, #(_player + PLAYER_FLAG)
    res     #PLAYER_FLAG_ACTIVE_BIT, (hl)

    ; 会話の設定
    ld      hl, #playerTalkDead_3_0
    call    PlayerSetTalk

    ; エネミーをロック
    call    _EnemyLock
    call    _EnemyClearSpeech

    ; 初期化の完了
    ld      hl, #(_player + PLAYER_STATE)
    inc     (hl)
09$:

    ; 0x01 : 会話０
10$:
    ld      a, (_player + PLAYER_STATE)
    dec     a
    jr      nz, 20$

    ; 会話の更新
    call    PlayerTalk
    jr      c, 19$

    ; アニメーションの設定
    ld      a, #PLAYER_ANIMATION_SPEECH
    ld      (_player + PLAYER_ANIMATION), a

    ; パターンの設定
    ld      hl, #playerPatternDead_3_0
    ld      (_player + PLAYER_PATTERN_L), hl

    ; カラーテーブルの設定
    ld      a, #VDP_COLOR_MEDIUM_RED
    call    PlayerSetColor

    ; 状態の更新
    ld      hl, #(_player + PLAYER_STATE)
    inc     (hl)
19$:
    jr      90$

    ; 0x02 : 死亡０
20$:
    dec     a
    jr      nz, 30$

    ; アニメーションの更新
    ld      hl, #(_player + PLAYER_ANIMATION)
    dec     (hl)
    jr      nz, 29$

    ; パターンの設定
    ld      hl, #playerPatternDead_3_1
    ld      (_player + PLAYER_PATTERN_L), hl

    ; 会話の設定
    ld      hl, (_player + PLAYER_PROC_L)
    ld      de, #PlayerDead_3
    or      a
    sbc     hl, de
    jr      nz, 21$
    ld      hl, #playerTalkDead_3_1
    jr      22$
21$:
    ld      hl, #playerTalkDead_4_1
22$:
    call    PlayerSetTalk

    ; 状態の更新
    ld      hl, #(_player + PLAYER_STATE)
    inc     (hl)
29$:
    jr      90$

    ; 0x03 : 会話１
30$:
    dec     a
    jr      nz, 40$

    ; 台詞の更新
    call    PlayerTalk
    jr      c, 39$

    ; フラグの設定
    ld      hl, #(_player + PLAYER_FLAG)
    set     #PLAYER_FLAG_DEAD_BIT, (hl)

    ; 状態の更新
    ld      hl, #(_player + PLAYER_STATE)
    inc     (hl)
39$:
    jr      90$

    ; 0x04 : 待機
40$:
;   dec     a
;   jr      nz, 50$

    ; 死亡の完了
90$:

    ; レジスタの復帰

    ; 終了
    ret

; プレイヤを移動させる
;
_PlayerMove::

    ; レジスタの保存
    push    hl

    ; de < Y/X 移動量

    ; 位置の更新
    ld      hl, (_player + PLAYER_POSITION_X)
    ld      a, e
    or      a
    jp      p, 11$
    add     a, l
    jp      m, 10$
    jr      nz, 12$
10$:
    ld      a, #0x01
    jr      12$
11$:
    add     a, l
    cp      #0x20
    jr      c, 12$
    ld      a, #(0x20 - 0x01)
;   jr      12$
12$:
    ld      l, a
    ld      a, d
    add     a, h
    ld      h, a
    ld      (_player + PLAYER_POSITION_X), hl

    ; レジスタの復帰
    pop     hl

    ; 終了
    ret

; 力をクリアする
;
PlayerClearPower:

    ; レジスタの保存

    ; 力の増加
    xor     a
    ld      (_player + PLAYER_POWER), a

    ; レジスタの復帰

    ; 終了
    ret

; 力を加える
;
PlayerAddPower:

    ; レジスタの保存
    push    hl

    ; 力の増加
    ld      hl, #(_player + PLAYER_POWER)
    ld      a, (hl)
    cp      #PLAYER_POWER_MAXIMUM
    jr      nc, 10$
    inc     (hl)
10$:

    ; レジスタの復帰
    pop     hl

    ; 終了
    ret

; 力を使う
;
PlayerUsePower:

    ; レジスタの保存

    ; 力の増加
    ld      a, #(PLAYER_POWER_MAXIMUM + 1)
    ld      (_player + PLAYER_POWER), a

    ; レジスタの復帰

    ; 終了
    ret

; プレイヤの体力を取得する
;
_PlayerGetLife::

    ; レジスタの保存

    ; hl > 体力

    ; 体力の取得
    ld      hl, (_player + PLAYER_LIFE_L)

    ; レジスタの復帰

    ; 終了
    ret

; プレイヤとの距離を測る
;
_PlayerGetDistance::

    ; レジスタの保存
    push    de

    ; a < X 位置
    ; a > 距離

    ld      e, a
    ld      a, (_player + PLAYER_POSITION_X)
    sub     e
    neg

    ; レジスタの復帰
    pop     de

    ; 終了
    ret

; 選択されている技の文字列を取得する
;
_PlayerGetSpecialString::

    ; レジスタの保存
    push    de

    ; hl > 文字列

    ; 力の判定
    ld      a, (_player + PLAYER_POWER)
    cp      #PLAYER_POWER_MAXIMUM
    jr      nc, 10$
    ld      hl, #playerPowerString
    jr      11$
10$:
    ld      hl, #playerSpecialString
    ld      a, (_player + PLAYER_SPECIAL)
11$:

    ; 文字列の取得
    ld      e, a
    add     a, a
    add     a, a
    add     a, a
    add     a, a
    add     a, e
    ld      e, a
    ld      d, #0x00
    add     hl, de

    ; レジスタの復帰
    pop     de

    ; 終了
    ret

; プレイヤの色を設定する
;
PlayerSetColor:

    ; レジスタの保存
    push    hl
    push    bc
    push    de

    ; a < 色

    ; 色の設定
    add     a, a
    add     a, a
    add     a, a
    add     a, a
    add     a, #VDP_COLOR_BLACK
    ld      hl, #(_appColorTable + 0x0018 + 0x0000)
    ld      de, #(_appColorTable + 0x0018 + 0x0001)
    ld      bc, #(0x0007 - 0x0001)
    ld      (hl), a
    ldir

    ; レジスタの復帰
    pop     de
    pop     bc
    pop     hl

    ; 終了
    ret

; プレイヤのパターンを選択する
;
PlayerSelectPattern:

    ; レジスタの保存
    push    hl
    push    de

    ; hl < パターンテーブル
    ; a  < インデックス

    ; パターンの取得
    add     a, a
    ld      e, a
    ld      d, #0x00
    add     hl, de
    ld      e, (hl)
    inc     hl
    ld      d, (hl)

    ; パターンの設定
    ld      (_player + PLAYER_PATTERN_L), de

    ; レジスタの復帰
    pop     de
    pop     hl

    ; 終了
    ret

; プレイヤの台詞の消去する
;
_PlayerClearSpeech::

    ; レジスタの保存
    push    hl

    ; 台詞の消去
    ld      hl, #0x0000
    ld      (_player + PLAYER_SPEECH_L), hl

    ; レジスタの復帰
    pop     hl

    ; 終了
    ret

; プレイヤの台詞を設定する
;
_PlayerSetSpeech::

    ; レジスタの保存
    push    de

    ; hl < 文字列

    ; 台詞の設定
    ld      a, h
    or      l
    jr      z, 10$
    ld      a, (_player + PLAYER_POSITION_X)
    ld      e, a
    ld      d, #12
    call    _GameGetSpeechPosition
    ld      (_player + PLAYER_SPEECH_L), hl
    ld      (_player + PLAYER_SPEECH_X), de
    jr      19$
10$:
    ld      (_player + PLAYER_SPEECH_L), hl
;   jr      19$
19$:

    ; レジスタの復帰
    pop     de

    ; 終了
    ret

PlayerSetSpeechOwner:

    ; レジスタの保存

    ; hl < 文字列
    ; a  < アニメーション

    ; アニメーションの設定
    ld      (_player + PLAYER_ANIMATION), a

    ; 台詞の設定
    call    _PlayerSetSpeech

    ; レジスタの復帰

    ; 終了
    ret

PlayerSetSpeechOther:

    ; レジスタの保存

    ; hl < 文字列
    ; a  < アニメーション

    ; アニメーションの設定
    ld      (_player + PLAYER_ANIMATION), a

    ; 台詞の設定
    call    _EnemySetSpeech

    ; レジスタの復帰

    ; 終了
    ret

; プレイヤの台詞を選択する
;
PlayerSelectSpeechOwner:

    ; レジスタの保存
    push    hl
    push    de

    ; hl < 文字列テーブル
    ; c  < インデックス
    ; a  < アニメーション

    ; アニメーションの設定
    ld      (_player + PLAYER_ANIMATION), a

    ; 文字列の取得
    ld      a, c
    add     a, a
    ld      e, a
    ld      d, #0x00
    add     hl, de
    ld      e, (hl)
    inc     hl
    ld      d, (hl)
    ex      de, hl

    ; 台詞の設定
    call    _PlayerSetSpeech

    ; レジスタの復帰
    pop     de
    pop     hl

    ; 終了
    ret

PlayerSelectSpeechOther:

    ; レジスタの保存
    push    hl
    push    de

    ; hl < 文字列テーブル
    ; c  < インデックス
    ; a  < アニメーション

    ; アニメーションの設定
    ld      (_player + PLAYER_ANIMATION), a

    ; 文字列の取得
    ld      a, c
    add     a, a
    ld      e, a
    ld      d, #0x00
    add     hl, de
    ld      e, (hl)
    inc     hl
    ld      d, (hl)
    ex      de, hl

    ; 台詞の設定
    call    _EnemySetSpeech

    ; レジスタの復帰
    pop     de
    pop     hl

    ; 終了
    ret

; プレイヤが台詞を言う
;
PlayerSpeechOwner:

    ; レジスタの保存

    ; cf > 1 = 台詞中
    push    hl

    ; アニメーションの更新
    ld      hl, #(_player + PLAYER_ANIMATION)
    dec     (hl)
    jr      nz, 18$

    ; 台詞の消去
    call    _PlayerClearSpeech
    or      a
    jr      19$
18$:
    scf
19$:

    ; レジスタの復帰
    pop     hl

    ; 終了
    ret

PlayerSpeechOther:

    ; レジスタの保存

    ; cf > 1 = 台詞中
    push    hl

    ; アニメーションの更新
    ld      hl, #(_player + PLAYER_ANIMATION)
    dec     (hl)
    jr      nz, 18$

    ; 台詞の消去
    call    _EnemyClearSpeech
    or      a
    jr      19$
18$:
    scf
19$:

    ; レジスタの復帰
    pop     hl

    ; 終了
    ret

; プレイヤの会話を設定する
;
PlayerSetTalk:

    ; レジスタの保存
    push    hl
    push    de

    ; hl < 会話

    ; 会話の設定
    ld      a, (hl)
    inc     hl
    cp      #PLAYER_TALK_SILENT
    jr      nz, 10$
    ld      (_player + PLAYER_TALK_L), hl
    ld      a, #PLAYER_ANIMATION_SILENT
    ld      (_player + PLAYER_ANIMATION), a
    jr      19$
10$:
    ld      e, (hl)
    inc     hl
    ld      d, (hl)
    inc     hl
    ld      (_player + PLAYER_TALK_L), hl
    ex      de, hl
    cp      #PLAYER_TALK_OWNER
    ld      a, #PLAYER_ANIMATION_SPEECH
    jr      nz, 11$
    call    PlayerSetSpeechOwner
    jr      19$
11$:
    call    PlayerSetSpeechOther
;   jr      19$
19$:

    ; レジスタの復帰
    pop     de
    pop     hl

    ; 終了
    ret

; プレイヤの会話を選択する
;
PlayerSelectTalk:

    ; レジスタの保存
    push    hl
    push    de

    ; hl < 会話テーブル
    ; c  < インデックス

    ; 会話の取得
    ld      a, c
    add     a, a
    ld      e, a
    ld      d, #0x00
    add     hl, de
    ld      e, (hl)
    inc     hl
    ld      d, (hl)
    ex      de, hl

    ; 台詞の設定
    call    PlayerSetTalk

    ; レジスタの復帰
    pop     de
    pop     hl

    ; 終了
    ret

; プレイヤが会話する
;
PlayerTalk:

    ; レジスタの保存
    push    hl
    push    de

    ; cf > 1 = 会話中

    ; アニメーションの更新
    ld      hl, #(_player + PLAYER_ANIMATION)
    dec     (hl)
    jr      nz, 18$

    ; 台詞の消去
    call    _PlayerClearSpeech
    call    _EnemyClearSpeech

    ; 会話の更新
    ld      hl, (_player + PLAYER_TALK_L)
    ld      a, (hl)
    or      a
    jr      z, 19$
    inc     hl
    cp      #PLAYER_TALK_SILENT
    jr      nz, 10$
    ld      (_player + PLAYER_TALK_L), hl
    ld      a, #PLAYER_ANIMATION_SILENT
    ld      (_player + PLAYER_ANIMATION), a
    jr      18$
10$:
    ld      e, (hl)
    inc     hl
    ld      d, (hl)
    inc     hl
    ld      (_player + PLAYER_TALK_L), hl
    ex      de, hl
    cp      #PLAYER_TALK_OWNER
    ld      a, #PLAYER_ANIMATION_SPEECH
    jr      nz, 11$
    call    PlayerSetSpeechOwner
    jr      18$
11$:
    call    PlayerSetSpeechOther
;   jr      18$
18$:
    scf
19$:

    ; レジスタの復帰
    pop     de
    pop     hl

    ; 終了
    ret

; プレイヤをロックする
;
_PlayerLock::

    ; レジスタの保存

    ; 処理の設定
    ld      hl, #PlayerIdle
    ld      (_player + PLAYER_PROC_L), hl
    xor     a
    ld      (_player + PLAYER_STATE), a

    ; レジスタの復帰

    ; 終了
    ret

; プレイヤをアンロックする
;
_PlayerUnlock::

    ; レジスタの保存

    ; 処理の設定
    ld      hl, #PlayerPlay
    ld      (_player + PLAYER_PROC_L), hl
    xor     a
    ld      (_player + PLAYER_STATE), a

    ; レジスタの復帰

    ; 終了
    ret

; プレイヤのヒット判定を行う
;
_PlayerHit::

    ; レジスタの保存
    push    hl
    push    de

    ; de < 攻撃範囲
    ; cf > 1 = ヒット

    ; プレイヤがアクティブかどうか
    ld      hl, (_player + PLAYER_LIFE_L)
    ld      a, h
    or      l
    jr      z, 80$
    ld      a, (_player + PLAYER_FLAG)
    bit     #PLAYER_FLAG_ACTIVE_BIT, a
    jr      z, 80$

    ; 範囲の判定
    ld      a, d
    or      a
    jp      m, 80$
    ld      a, e
    or      a
    jp      p, 20$
    ld      e, #0x00
20$:
    ld      a, (_player + PLAYER_POSITION_X)
    cp      e
    jr      c, 80$
    inc     d
    cp      d
    jr      nc, 80$
    scf
    jr      90$

    ; ヒットなし
80$:
    or      a

    ; 判定の完了
90$:

    ; レジスタの復帰
    pop     de
    pop     hl

    ; 終了
    ret

; プレイヤの攻撃判定を行う
;
PlayerAttack:

    ; レジスタの保存
    push    hl
    push    de

    ; de < L/R 攻撃範囲
    ; cf > 1 = ヒット

    ; 攻撃判定
    ld      a, (_player + PLAYER_POSITION_X)
    add     a, e
    ld      e, a
    ld      a, (_player + PLAYER_POSITION_X)
    add     a, d
    ld      d, a
    call    _EnemyHit
    ld      hl, #(_player + PLAYER_FLAG)
    jr      nc, 10$
    set     #PLAYER_FLAG_HIT_BIT, (hl)
    call    _EnemyLock
    scf
    jr      19$
10$:
    res     #PLAYER_FLAG_HIT_BIT, (hl)
    or      a
;   jr      19$
19$:

    ; レジスタの復帰
    pop     de
    pop     hl

    ; 終了
    ret

; プレイヤが二指真空把で防御するかどうかを判定する
;
_PlayerGuard::

    ; レジスタの保存

    ; cf > 1 = 防御した

    ; プレイヤがアクティブかどうか
    ld      hl, (_player + PLAYER_LIFE_L)
    ld      a, h
    or      l
    jr      z, 80$
    ld      a, (_player + PLAYER_FLAG)
    bit     #PLAYER_FLAG_ACTIVE_BIT, a
    jr      z, 80$

    ; 防御の判定
    ld      a, (_player + PLAYER_GUARD)
    cp      #PLAYER_GUARD_FRAME
    jr      nc, 80$

    ; 処理の更新
    ld      hl, #PlayerNishishinkuha
    ld      (_player + PLAYER_PROC_L), hl
    xor     a
    ld      (_player + PLAYER_STATE), a
    scf
    jr      90$

    ; 判定の完了
80$:
    or      a
90$:

    ; レジスタの復帰

    ; 終了
    ret

; プレイヤがダメージを受ける
;
_PlayerTakeDamage::

    ; レジスタの保存
    push    hl

    ; de < ダメージ量

    ; 体力の減少
    ld      hl, (_player + PLAYER_LIFE_L)
    or      a
    sbc     hl, de
    jr      nc, 10$
    ld      hl, #0x0000
10$:
    ld      (_player + PLAYER_LIFE_L), hl

    ; 攻撃方法の取得
    call    _EnemyGetAttack
    ld      (_player + PLAYER_DAMAGE), a

    ; 処理の設定
    ld      hl, #PlayerDamage
    ld      (_player + PLAYER_PROC_L), hl
    xor     a
    ld      (_player + PLAYER_STATE), a

    ; レジスタの復帰
    pop     hl

    ; 終了
    ret

; プレイヤがエネミーと接触する
;
PlayerContact:

    ; レジスタの保存
    push    hl
    push    bc
    push    de

    ; cf > 1 = 接触した

    ; 接触判定
    ld      a, (_player + PLAYER_POSITION_X)
    ld      e, a
    ld      d, a
    call    _EnemyHit
    jr      nc, 19$

    ; 体力の減少
    ld      hl, #0x0000
    ld      de, #10
    call    _EnemyGetType
    ld      b, a
10$:
    add     hl, de
    djnz    10$
    ex      de, hl
    ld      hl, (_player + PLAYER_LIFE_L)
    or      a
    sbc     hl, de
    jr      nc, 11$
    ld      hl, #0x0000
11$:
    ld      (_player + PLAYER_LIFE_L), hl

    ; 攻撃方法の取得
    xor     a
    ld      (_player + PLAYER_DAMAGE), a

    ; 処理の設定
    ld      hl, #PlayerDamage
    ld      (_player + PLAYER_PROC_L), hl
    xor     a
    ld      (_player + PLAYER_STATE), a
    scf
19$:

    ; レジスタの復帰
    pop     de
    pop     bc
    pop     hl

    ; 終了
    ret

; プレイヤが死んだかどうかを判定する
;
_PlayerIsDead::

    ; レジスタの保存

    ; cf > 1 = 死亡

    ; 死亡の判定
    ld      a, (_player + PLAYER_FLAG)
    bit     #PLAYER_FLAG_DEAD_BIT, a
    jr      nz, 10$
    or      a
    jr      19$
10$:
    scf
;   jr      19$
19$:

    ; レジスタの復帰

    ; 終了
    ret

; 定数の定義
;

; プレイヤの初期値
;
playerDefault:

    .dw     PLAYER_PROC_NULL
    .db     PLAYER_STATE_NULL
    .db     PLAYER_FLAG_NULL
    .db     28 ; PLAYER_POSITION_NULL
    .db     14 ; PLAYER_POSITION_NULL
    .dw     5000 ; PLAYER_LIFE_NULL
    .db     PLAYER_POWER_NULL
    .db     PLAYER_SPECIAL_HIKO ; PLAYER_SPECIAL_NULL
    .db     PLAYER_GUARD_NULL
    .db     PLAYER_DAMAGE_NULL
    .db     PLAYER_ANIMATION_NULL
    .dw     PLAYER_PATTERN_NULL
    .dw     PLAYER_SPEECH_NULL
    .dw     PLAYER_SPEECH_NULL
    .dw     PLAYER_TALK_NULL
    .db     PLAYER_PARAM_NULL
    .db     PLAYER_PARAM_NULL
    .db     PLAYER_PARAM_NULL
    .db     PLAYER_PARAM_NULL

; 力
playerPowerString:

    .db     _KTI, _KKA, _KRA, _EQU, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, 0x00
    .db     _KTI, _KKA, _KRA, _EQU, _GRT, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, 0x00
    .db     _KTI, _KKA, _KRA, _EQU, _GRT, _GRT, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, 0x00
    .db     _KTI, _KKA, _KRA, _EQU, _GRT, _GRT, _GRT, ____, ____, ____, ____, ____, ____, ____, ____, ____, 0x00
    .db     _KTI, _KKA, _KRA, _EQU, _GRT, _GRT, _GRT, _GRT, ____, ____, ____, ____, ____, ____, ____, ____, 0x00
    .db     _KTI, _KKA, _KRA, _EQU, _GRT, _GRT, _GRT, _GRT, _GRT, ____, ____, ____, ____, ____, ____, ____, 0x00
    .db     _KTI, _KKA, _KRA, _EQU, _GRT, _GRT, _GRT, _GRT, _GRT, _GRT, ____, ____, ____, ____, ____, ____, 0x00
    .db     _KTI, _KKA, _KRA, _EQU, _GRT, _GRT, _GRT, _GRT, _GRT, _GRT, _GRT, ____, ____, ____, ____, ____, 0x00

; 技
;
playerSpecialProc:

    .dw     PlayerHiko
    .dw     PlayerZankaiken
    .dw     PlayerHyakuretsuken
    .dw     PlayerHaganken
    .dw     PlayerKaikotsuken
    .dw     PlayerJuhazan

playerSpecialString:

    .db     _KWA, _KSA, _KSN, _EQU, _KHI, _KKO, _K_U, ____, _KWO, ____, _KTU, _KKU, ____, ____, ____, ____, 0x00
    .db     _KWA, _KSA, _KSN, _EQU, _KHO, _KKU, _KTO, ____, _KSA, _KSN, _KNN, _KKA, _K_I, _KKE, _KNN, ____, 0x00
    .db     _KWA, _KSA, _KSN, _EQU, _KHO, _KKU, _KTO, ____, _KHI, _Kya, _KKU, _KRE, _KTU, _KKE, _KNN, ____, 0x00
    .db     _KWA, _KSA, _KSN, _EQU, _KKO, _K_U, _KSI, _Kyu, ____, _KHA, _KKA, _KSN, _KNN, _KKE, _KNN, ____, 0x00
    .db     _KWA, _KSA, _KSN, _EQU, _KHO, _KKU, _KTO, ____, _KKA, _K_I, _KKO, _KTU, _KKE, _KNN, ____, ____, 0x00
    .db     _KWA, _KSA, _KSN, _EQU, _KHO, _KKU, _KTO, ____, _KSI, _KSN, _Kyu, _K_U, _KHA, _KSA, _KSN, _KNN, 0x00

; 死亡
playerDeadProc:

    .dw     PlayerDead_0
    .dw     PlayerDead_0
    .dw     PlayerDead_2
    .dw     PlayerDead_3
    .dw     PlayerDead_4

; パターン
;

; 立ち
playerPatternStand:

    .db     -1, 0, 2, 4
    .db     ____, _P00
    .db     _P12, _P01
    .db     ____, _P01
    .db     _P0A, _P09

; 前ジャンプ
playerPatternJumpFront_0:

    .db     -1, 0, 3, 4
    .db     ____, _P00, ____
    .db     _P14, _P06, _P05
    .db     ____, ____, _P01
    .db     ____, _P0A, _P0A
    .db     _P0A, ____, ____

playerPatternJumpFront_1:

    .db     -1, 0, 6, 3
    .db     _P0C, _P04, _P01, _P01, _P05, ____
    .db     _P00, _P0C, ____, ____, _P0B, _P0B
    .db     ____, ____, ____, ____, ____, _P0B

; 後ろジャンプ
playerPatternJumpBack_0:

    .db     -1, 0, 3, 4
    .db     ____, _P00, ____
    .db     _P04, _P07, _P15
    .db     _P0B, _P0B, ____
    .db     ____, _P0B, ____

playerPatternJumpBack_1:

    .db     -1, 0, 6, 3
    .db     ____, _P04, _P01, _P01, _P05, _P00
    .db     _P0A, _P0A, ____, ____, _P1F, _P08
    .db     _P0A, ____, ____, ____, ____, ____

; 正拳突き
playerPatternSeikenduki:

    .db     -3, 0, 4, 4
    .db     ____, ____, ____, _P00
    .db     _P10, _P1C, _P1C, _P01
    .db     ____, ____, ____, _P01
    .db     ____, ____, _P0A, _P09

; 足蹴り
playerPatternAshigeri:

    .db     -4, -1, 6, 4
    .db     ____, ____, ____, ____, _P00, ____
    .db     ____, ____, ____, _P04, _P07, _P13
    .db     _P1C, _P1C, _P1C, _P07, ____, ____
    .db     ____, ____, _P0A, ____, ____, ____

; 秘孔をつく
playerPatternHiko_0:

    .dw     playerPatternHiko_0_0
    .dw     playerPatternHiko_0_1
    .dw     playerPatternHiko_0_2

playerPatternHiko_0_0:

    .db     -2, 0, 3, 4
    .db     _P15, _P15, _P00
    .db     _P16, _P1C, _P01
    .db     ____, ____, _P01
    .db     ____, _P0A, _P09

playerPatternHiko_0_1:

    .db     -2, 0, 3, 4
    .db     _P1C, _P1C, _P00
    .db     _P18, _P18, _P01
    .db     ____, ____, _P01
    .db     ____, _P0A, _P09

playerPatternHiko_0_2:

    .db     -2, 0, 3, 4
    .db     _P11, _P1F, _P00
    .db     ____, _P12, _P01
    .db     ____, ____, _P01
    .db     ____, _P0A, _P09

playerPatternHiko_1:

    .db     -2, 0, 3, 4
    .db     ____, ____, _P00
    .db     _P18, _P19, _P01
    .db     ____, ____, _P01
    .db     ____, _P0A, _P09

; 北斗残悔拳
playerPatternZankaiken:

    .db     -2, 0, 3, 4
    .db     _P11, _P1C, _P00
    .db     _P12, _P1C, _P01
    .db     ____, ____, _P01
    .db     ____, _P0A, _P09

; 北斗百裂拳
playerPatternHyakuretsuken_0:

    .dw     playerPatternHyakuretsuken_0_0
    .dw     playerPatternHyakuretsuken_0_1
    .dw     playerPatternHyakuretsuken_0_2
    .dw     playerPatternHyakuretsuken_0_1
    
playerPatternHyakuretsuken_0_0:

    .db     -2, 0, 3, 4
    .db     _P1C, _P15, _P00
    .db     ____, _P12, _P01
    .db     _P1C, _P1C, _P01
    .db     ____, _P0A, _P09

playerPatternHyakuretsuken_0_1:

    .db     -2, 0, 3, 4
    .db     ____, ____, _P00
    .db     _P1C, _P1C, _P01
    .db     ____, ____, _P01
    .db     ____, _P0A, _P09

playerPatternHyakuretsuken_0_2:

    .db     -2, 0, 3, 4
    .db     _P1C, _P1C, _P00
    .db     ____, _P10, _P01
    .db     _P1C, _P17, _P01
    .db     ____, _P0A, _P09

playerPatternHyakuretsuken_1:

    .dw     playerPatternHyakuretsuken_1_0
    .dw     playerPatternHyakuretsuken_1_1
    .dw     playerPatternHyakuretsuken_1_2
    .dw     playerPatternHyakuretsuken_1_1
    
playerPatternHyakuretsuken_1_0:

    .db     -1, -1, 2, 5
    .db     ____, ____
    .db     ____, _P00
    .db     _P0B, _P01
    .db     ____, _P01
    .db     _P0A, _P09

playerPatternHyakuretsuken_1_1:

    .db     -1, -1, 2, 5
    .db     ____, ____
    .db     _P0B, _P00
    .db     ____, _P01
    .db     ____, _P01
    .db     _P0A, _P09

playerPatternHyakuretsuken_1_2:

    .db     -1, -1, 2, 5
    .db     _P0B, ____
    .db     ____, _P00
    .db     ____, _P01
    .db     ____, _P01
    .db     _P0A, _P09

; 交首破顔拳
playerPatternHaganken_0:

    .db     -3, 0, 4, 4
    .db     ____, ____, ____, _P00
    .db     _P12, _P1C, _P1C, _P01
    .db     ____, ____, ____, _P01
    .db     ____, ____, _P0A, _P09

playerPatternHaganken_1:

    .db     -1, 0, 3, 4
    .db     _P00, _P0A, ____
    .db     _P01, _P15, ____
    .db     _P06, _P05, ____
    .db     _P18, ____, _P0B

playerPatternHaganken_2:

    .db     -1, 0, 6, 3
    .db     _P0C, _P04, _P01, _P01, _P05, ____
    .db     _P00, _P0C, ____, ____, _P0B, _P0B
    .db     ____, ____, ____, ____, ____, _P0B

; 北斗壊骨拳
playerPatternKaikotsuken_0:

    .db     -2, 0, 3, 4
    .db     _P1C, _P11, _P00
    .db     ____, _P12, _P01
    .db     ____, ____, _P01
    .db     ____, _P0A, _P09

; 北斗柔破斬
playerPatternJuhazan_0:

    .dw     playerPatternJuhazan_0_0
    .dw     playerPatternJuhazan_0_1
    .dw     playerPatternJuhazan_0_2
    .dw     playerPatternJuhazan_0_3

playerPatternJuhazan_0_0:

    .db     -3, 0, 5, 4
    .db     ____, ____, ____, _P00, ____
    .db     ____, ____, ____, _P01, _P15
    .db     _P18, _P18, _P18, _P01, ____
    .db     ____, ____, ____, _P09, ____

playerPatternJuhazan_0_1:

    .db     -3, 0, 5, 4
    .db     ____, ____, ____, _P00, ____
    .db     ____, ____, ____, _P01, _P15
    .db     _P1A, _P1A, _P1A, _P01, ____
    .db     ____, ____, ____, _P09, ____

playerPatternJuhazan_0_2:

    .db     -3, 0, 5, 4
    .db     ____, ____, ____, _P00, ____
    .db     ____, ____, ____, _P01, _P15
    .db     _P1C, _P1C, _P1C, _P01, ____
    .db     ____, ____, ____, _P09, ____

playerPatternJuhazan_0_3:

    .db     -3, 0, 5, 4
    .db     ____, ____, ____, _P00, ____
    .db     ____, ____, ____, _P01, _P15
    .db     _P1F, _P1F, _P1F, _P01, ____
    .db     ____, ____, ____, _P09, ____

playerPatternJuhazan_1:

    .db     -3, 0, 4, 4
    .db     ____, ____, ____, _P00
    .db     _P1C, _P1C, _P1C, _P01
    .db     ____, ____, ____, _P01
    .db     ____, ____, _P0A, _P09

; 二指真空把
playerPatternNishishinkuha:

    .db     -3, 0, 4, 4
    .db     _P29, _P1C, _P2A, _P00
    .db     ____, ____, _P12, _P01
    .db     ____, ____, ____, _P01
    .db     ____, ____, _P0A, _P09

; ダメージ
playerPatternDamageLive:

    .dw     playerPatternDamage_0
    .dw     playerPatternDamage_1
    .dw     playerPatternDamage_0
    .dw     playerPatternDamage_0
    .dw     playerPatternDamage_0

playerPatternDamageDead:

    .dw     playerPatternDamage_0
    .dw     playerPatternDamage_1
    .dw     playerPatternStand
    .dw     playerPatternStand
    .dw     playerPatternStand

playerPatternDamage_0:

    .db     -2, 2, 3, 2
    .db     _P00, _P01, _P01
    .db     ____, _P0A, _P09

playerPatternDamage_1:

    .db     -2, 0, 4, 4
    .db     _P29, _P1C, _P00, _P2D
    .db     ____, _P12, _P01, ____
    .db     ____, ____, _P01, ____
    .db     ____, _P0A, _P09, ____

; 死亡
playerPatternDead_0:

    .db     -1, 2, 4, 2
    .db     _P1F, ____, _P10, ____
    .db     _P1F, _P01, _P01, _P00

playerPatternDead_2_0:

    .db     -1, 0, 3, 4
    .db     ____, _P00, _P1C
    .db     _P1C, _P06, _P1C
    .db     ____, _P01, ____
    .db     _P0A, _P09, ____

playerPatternDead_2_1:

    .db     -1, 0, 4, 4
    .db     ____, _P00, _P1C, ____
    .db     _P1C, _P06, _P1C, ____
    .db     ____, _P04, _P07, _P0A
    .db     ____, _P08, _P0B, ____

playerPatternDead_3_0:

    .db     -1, 0, 2, 4
    .db     ____, _P00
    .db     _P04, _P07
    .db     _P06, _P05
    .db     _P0A, _P09

playerPatternDead_3_1:

    .db     -1, 0, 4, 4
    .db     _P14, _P21, _P20, _P17
    .db     _P20, _P21, _P22, _P21
    .db     _P21, _P24, _P15, _P17
    .db     _P20, _P08, _P0B, _P21

; 台詞
;

; なし
playerSpeechNull:

    .db     ____, 0x00

; 正拳突き
playerSpeechSeikenduki:

    .db     _K_A, _KTA, _EXC, 0x00

; 足蹴り
playerSpeechAshigeri:

    .db     _K_o, _KWA, _KTA, _EXC, 0x00

; 秘孔をつく
playerSpeechHiko_0:

    .dw     playerSpeechHiko_0_0
    .dw     playerSpeechHiko_0_1
    .dw     playerSpeechHiko_0_2

playerSpeechHiko_0_0:

    .db     _KTO, _K_U, _K_I, ____, _KTO, _K_I, _K_U, ____, _KHI, _KKO, _K_U, _KWO, _KTU, _K_I, _KTA, 0x00

playerSpeechHiko_0_1:

    .db     _KSE, _KTU, _KRI, ____, _KTO, _K_I, _K_U, ____, _KHI, _KKO, _K_U, _KWO, _KTU, _K_I, _KTA, 0x00

playerSpeechHiko_0_2:

    .db     _K_I, _KKA, _KKU, ____, _KTO, _K_I, _K_U, ____, _KHI, _KKO, _K_U, _KWO, _KTU, _K_I, _KTA, 0x00

playerTalkHiko_1:

    .dw     playerTalkHiko_1_0
    .dw     playerTalkHiko_1_1
    .dw     playerTalkHiko_1_2

playerTalkHiko_1_0:

    .db     PLAYER_TALK_OWNER
    .dw     playerSpeechHiko_1_0_0
    .db     PLAYER_TALK_OWNER
    .dw     playerSpeechHiko_1_0_1
    .db     PLAYER_TALK_SILENT
    .db     0x00

playerSpeechHiko_1_0_0:

    .db     _K_O, _KMA, _K_E, _KHA, _KMO, _K_U, 0x00

playerSpeechHiko_1_0_1:

    .db     _KSI, _KNN, _KTE, _KSN, _K_I, _KRU, _EXC, _EXC, 0x00

playerTalkHiko_1_1:

    .db     PLAYER_TALK_OWNER
    .dw     playerSpeechHiko_1_1_0
    .db     PLAYER_TALK_OWNER
    .dw     playerSpeechHiko_1_1_1
    .db     PLAYER_TALK_SILENT
    .db     0x00

playerSpeechHiko_1_1_0:

    .db     _K_O, _KMA, _K_E, _KNO, _K_I, _KNO, _KTI, _KHA, 0x00

playerSpeechHiko_1_1_1:

    .db     _K_A, _KTO, ____, ___5, _BYO, _DOT, _DOT, _DOT, 0x00

playerTalkHiko_1_2:

    .db     PLAYER_TALK_OWNER
    .dw     playerSpeechHiko_1_2_0
    .db     PLAYER_TALK_OWNER
    .dw     playerSpeechHiko_1_2_1
    .db     PLAYER_TALK_SILENT
    .db     0x00

playerSpeechHiko_1_2_0:

    .db     _K_O, _KNO, _KRE, _KNO, _KTU, _KMI, _KHU, _KSN, _KKA, _KSA, _KWO, 0x00

playerSpeechHiko_1_2_1:

    .db     _K_O, _KMO, _K_I, _KSI, _KRE, _EXC, _EXC, _EXC, 0x00

playerTalkHiko_2:

    .dw     playerTalkHiko_2_0
    .dw     playerTalkHiko_2_1
    .dw     playerTalkHiko_2_2
    .dw     playerTalkHiko_2_3
    .dw     playerTalkHiko_2_4

playerTalkHiko_2_0:

    .db     PLAYER_TALK_OTHER
    .dw     playerSpeechHiko_2_0_0
    .db     PLAYER_TALK_SILENT
    .db     0x00

playerSpeechHiko_2_0_0:

    .db     _KSO, _KNN, _KNA, _DOT, _DOT, 0x00

playerTalkHiko_2_1:

    .db     PLAYER_TALK_OTHER
    .dw     playerSpeechHiko_2_1_0
    .db     PLAYER_TALK_SILENT
    .db     PLAYER_TALK_OWNER
    .dw     playerSpeechHiko_2_1_1
    .db     PLAYER_TALK_OWNER
    .dw     playerSpeechHiko_2_1_2
    .db     PLAYER_TALK_OWNER
    .dw     playerSpeechHiko_2_1_3
    .db     PLAYER_TALK_SILENT
    .db     0x00

playerSpeechHiko_2_1_0:

    .db     _KTA, _KSU, _KKE, _KTE, _EXC, 0x00

playerSpeechHiko_2_1_1:

    .db     _K_A, _KKU, _KTO, _K_U, ____, _KNO, 0x00

playerSpeechHiko_2_1_2:

    .db     _KHI, _KME, _K_I, ____, _KHA, 0x00

playerSpeechHiko_2_1_3:

    .db     _KKI, _KKO, _K_E, _KNN, _KNA, _EXC, 0x00

playerTalkHiko_2_2:

    .db     PLAYER_TALK_OTHER
    .dw     playerSpeechHiko_2_2_0
    .db     PLAYER_TALK_SILENT
    .db     0x00

playerSpeechHiko_2_2_0:

    .db     _KKO, _K_I, _KTU, _EXC, _EXC, _EXC, _EXC, 0x00

playerTalkHiko_2_3:

    .db     PLAYER_TALK_OTHER
    .dw     playerSpeechHiko_2_3_0
    .db     PLAYER_TALK_OTHER
    .dw     playerSpeechHiko_2_3_1
    .db     PLAYER_TALK_OTHER
    .dw     playerSpeechHiko_2_3_2
    .db     PLAYER_TALK_OTHER
    .dw     playerSpeechHiko_2_3_3
    .db     PLAYER_TALK_SILENT
    .db     0x00

playerSpeechHiko_2_3_0:

    .db     _K_I, _KTA, _KKU, _KMO, ____, _KKA, _KYU, _KKU, _KMO, _KNE, _K_e, 0x00

playerSpeechHiko_2_3_1:

    .db     _KKO, _KRE, _KKA, _KSN, ____, _K_A, _KNO, 0x00

playerSpeechHiko_2_3_2:

    .db     _KHO, _KKU, _KTO, _KSI, _KNN, _KKE, _KNN, ____, _KKA, _K_I, _EXC, 0x00

playerSpeechHiko_2_3_3:

    .db     _KWA, _KRA, _KWA, _KSE, _KRU, _KSE, _KSN, 0x00

playerTalkHiko_2_4:

    .db     PLAYER_TALK_OTHER
    .dw     playerSpeechHiko_2_4_0
    .db     PLAYER_TALK_SILENT
    .db     PLAYER_TALK_OWNER
    .dw     playerSpeechHiko_2_4_1
    .db     PLAYER_TALK_OWNER
    .dw     playerSpeechHiko_2_4_2
    .db     PLAYER_TALK_SILENT
    .db     0x00

playerSpeechHiko_2_4_0:

    .db     _KNA, _KNN, _KTO, _KMO, _KNA, _K_I, _EXC, 0x00

playerSpeechHiko_2_4_1:

    .db     _KKI, _KSA, _KMA, _KNO, _KYO, _K_U, _KNA, ____, _KKE, _KSN, _KTO, _KSN, _K_U, 0x00

playerSpeechHiko_2_4_2:

    .db     _K_O, _KRE, _KKA, _KSN, _K_I, _KKA, _KSU, _KTO, ____, _K_O, _KMO, _K_U, _KKA, 0x00

playerSpeechHiko_3:

    .dw     playerSpeechHiko_3_0
    .dw     playerSpeechHiko_3_1
    .dw     playerSpeechHiko_3_2
    .dw     playerSpeechHiko_3_3
    .dw     playerSpeechHiko_3_4

playerSpeechHiko_3_0:

    .db     _KHE, _KSN, _KHU, _KSN, _KHU, _KSN, 0x00

playerSpeechHiko_3_1:

    .db     _KTE, _KRE, _KRE, _KRE, _DOT, _DOT, 0x00

playerSpeechHiko_3_2:

    .db     _KTU, _KRA, _KRA, _KRA, _KRA, _DOT, _DOT, 0x00

playerSpeechHiko_3_3:

    .db     _KHE, _Ktu, _KHE, _Ktu, _KKE, _KSN, _KRE, _KRE, _KRE, 0x00

playerSpeechHiko_3_4:

    .db     _KHI, _KHE, _KSN, _KHE, _KSN, 0x00

; 北斗残悔拳
playerTalkZankaiken_0:

    .db     PLAYER_TALK_OWNER
    .dw     playerSpeechZankaiken_0_0
    .db     PLAYER_TALK_OWNER
    .dw     playerSpeechZankaiken_0_0
    .db     PLAYER_TALK_SILENT
    .db     PLAYER_TALK_OWNER
    .dw     playerSpeechZankaiken_0_1
    .db     PLAYER_TALK_OWNER
    .dw     playerSpeechZankaiken_0_2
    .db     0x00

playerSpeechZankaiken_0_0:

    .db     _KHO, _KKU, _KTO, _KSA, _KSN, _KNN, _KKA, _K_I, _KKE, _KNN, 0x00

playerSpeechZankaiken_0_1:

    .db     ___3, _BYO, ____, _KKO, _KSN, ____, _KNI, 0x00

playerSpeechZankaiken_0_2:

    .db     _K_O, _KMA, _K_E, _KHA, ____, _KSI, _KNU, _EXC, 0x00

playerTalkZankaiken_1:

    .db     PLAYER_TALK_OTHER
    .dw     playerSpeechZankaiken_1_3
    .db     PLAYER_TALK_OTHER
    .dw     playerSpeechZankaiken_1_2
    .db     PLAYER_TALK_OTHER
    .dw     playerSpeechZankaiken_1_1
    .db     PLAYER_TALK_OTHER
    .dw     playerSpeechZankaiken_1_0
    .db     0x00

playerSpeechZankaiken_1_0:

    .db     ___0, _BYO, 0x00

playerSpeechZankaiken_1_1:

    .db     ___1, _BYO, 0x00

playerSpeechZankaiken_1_2:

    .db     ___2, _BYO, 0x00

playerSpeechZankaiken_1_3:

    .db     ___3, _BYO, 0x00

; 北斗百裂拳
playerSpeechHyakuretsuken_0:

    .db     _K_A, _KTA, _KTA, _KTA, _KTA, _DOT, _DOT, 0x00

playerSpeechHyakuretsuken_1:

    .db     _KTA, _KTA, _KTA, _KTA, _KTA, _KTA, 0x00

playerSpeechHyakuretsuken_2:

    .db     _KTO, _KSN, _KSA, _Ktu, 0x00

playerTalkHyakuretsuken_3:

    .db     PLAYER_TALK_OWNER
    .dw     playerSpeechHyakuretsuken_3_0
    .db     PLAYER_TALK_OWNER
    .dw     playerSpeechHyakuretsuken_3_1
    .db     PLAYER_TALK_OWNER
    .dw     playerSpeechHyakuretsuken_3_1
    .db     PLAYER_TALK_SILENT
    .db     0x00

playerSpeechHyakuretsuken_3_0:

    .db     _KHO, _KKU, _KTO, 0x00

playerSpeechHyakuretsuken_3_1:

    .db     _KHI, _Kya, _KKU, _KRE, _KTU, _KKE, _KNN, 0x00

playerTalkHyakuretsuken_4:

    .dw     playerTalkHyakuretsuken_4_0
    .dw     playerTalkHyakuretsuken_4_1
    .dw     playerTalkHyakuretsuken_4_2
    .dw     playerTalkHyakuretsuken_4_3
    .dw     playerTalkHyakuretsuken_4_4
    .dw     playerTalkHyakuretsuken_4_5

playerTalkHyakuretsuken_4_0:

    .db     PLAYER_TALK_OTHER
    .dw     playerSpeechHyakuretsuken_4_0_0
    .db     PLAYER_TALK_OTHER
    .dw     playerSpeechHyakuretsuken_4_0_1
    .db     PLAYER_TALK_SILENT
    .db     0x00

playerSpeechHyakuretsuken_4_0_0:

    .db     _K_O, _KMA, _K_E, _KNO, ____, _KKE, _KNN, ____, _KNA, _KTO, _KSN, 0x00

playerSpeechHyakuretsuken_4_0_1:

    .db     _KKA, ____, _KHO, _KTO, _KSN, _KMO, ____, _KKI, _KKA, _KNN, _EXC, 0x00

playerTalkHyakuretsuken_4_1:

    .db     PLAYER_TALK_OTHER
    .dw     playerSpeechHyakuretsuken_4_1_0
    .db     PLAYER_TALK_OTHER
    .dw     playerSpeechHyakuretsuken_4_1_1
    .db     PLAYER_TALK_SILENT
    .db     0x00

playerSpeechHyakuretsuken_4_1_0:

    .db     _KHE, _Ktu, _KHE, _Ktu, _KHE, _Ktu, 0x00

playerSpeechHyakuretsuken_4_1_1:

    .db     _KNA, _KNN, _KTO, _KMO, _KNA, _K_I, _KSE, _KSN, _EXC, 0x00

playerTalkHyakuretsuken_4_2:

    .db     PLAYER_TALK_OTHER
    .dw     playerSpeechHyakuretsuken_4_2_0
    .db     PLAYER_TALK_SILENT
    .db     0x00

playerSpeechHyakuretsuken_4_2_0:

    .db     _KKI, _KSA, _KMA, _EXC, _EXC, 0x00

playerTalkHyakuretsuken_4_3:

    .db     PLAYER_TALK_OTHER
    .dw     playerSpeechHyakuretsuken_4_3_0
    .db     PLAYER_TALK_OTHER
    .dw     playerSpeechHyakuretsuken_4_3_1
    .db     PLAYER_TALK_OTHER
    .dw     playerSpeechHyakuretsuken_4_3_2
    .db     PLAYER_TALK_SILENT
    .db     0x00

playerSpeechHyakuretsuken_4_3_0:

    .db     _KKO, _KRE, _KHA, ____, _K_A, _KNO, 0x00

playerSpeechHyakuretsuken_4_3_1:

    .db     _KTE, _KSN, _KNN, _KSE, _KTU, _KNO, ____, _KKE, _KNN, _KHO, _KPS, _K_U, 0x00

playerSpeechHyakuretsuken_4_3_2:

    .db     _KHO, _KKU, _KTO, _KSI, _KNN, _KKE, _KNN, _EXC, 0x00

playerTalkHyakuretsuken_4_4:

    .db     PLAYER_TALK_OTHER
    .dw     playerSpeechHyakuretsuken_4_4_0
    .db     PLAYER_TALK_SILENT
    .db     0x00

playerSpeechHyakuretsuken_4_4_0:

    .db     _K_I, _KTE, _K_e, _KNA, ____, _KKO, _KNO, _EXC, 0x00

playerTalkHyakuretsuken_4_5:

    .db     PLAYER_TALK_OTHER
    .dw     playerSpeechHyakuretsuken_4_5_0
    .db     PLAYER_TALK_OTHER
    .dw     playerSpeechHyakuretsuken_4_5_1
    .db     PLAYER_TALK_SILENT
    .db     0x00

playerSpeechHyakuretsuken_4_5_0:

    .db     _K_O, _KNE, _KKA, _KSN, _K_I, _KTA, _KSN, _EXC, _EXC, 0x00

playerSpeechHyakuretsuken_4_5_1:

    .db     _KTA, _KSU, _KKE, _KTE, _KKU, _KRE, _EXC, 0x00

; 交首破顔拳
playerSpeechHaganken_0:

    .db     _K_U, _K_a, _KTA, 0x00

playerTalkHaganken_1:

    .db     PLAYER_TALK_OWNER
    .dw     playerSpeechNull
    .db     PLAYER_TALK_OWNER
    .dw     playerSpeechHaganken_1_0
    .db     PLAYER_TALK_OWNER
    .dw     playerSpeechHaganken_1_0
    .db     PLAYER_TALK_SILENT
    .db     0x00

playerSpeechHaganken_1_0:

    .db     _KKO, _K_U, _KSI, _Kyu, _KHA, _KKA, _KSN, _KNN, _KKE, _KNN, 0x00

playerTalkHaganken_2:

    .db     PLAYER_TALK_OTHER
    .dw     playerSpeechHaganken_2_0
    .db     PLAYER_TALK_OTHER
    .dw     playerSpeechHaganken_2_1
    .db     PLAYER_TALK_SILENT
    .db     0x00

playerSpeechHaganken_2_0:

    .db     _KKU, _KSN, _KKI, _Ktu, _EXC, 0x00

playerSpeechHaganken_2_1:

    .db     _KKO, _KSN, _KKI, _KKO, _KSN, _KKI, _KKI, 0x00

; 北斗壊骨拳
playerTalkKaikotsuken_0:

    .db     PLAYER_TALK_OWNER
    .dw     playerSpeechKaikotsuken_0_0
    .db     PLAYER_TALK_OWNER
    .dw     playerSpeechKaikotsuken_0_1
    .db     PLAYER_TALK_OWNER
    .dw     playerSpeechKaikotsuken_0_1
    .db     PLAYER_TALK_SILENT
    .db     0x00

playerSpeechKaikotsuken_0_0:

    .db     _KHO, _KKU, _KTO, 0x00

playerSpeechKaikotsuken_0_1:

    .db     _KKA, _K_I, _KKO, _KTU, _KKE, _KNN, 0x00

; 北斗柔破斬
playerSpeechJuhazan_0:

    .db     _K_O, _KWA, _KTA, _KTA, _KTA, _KTA, 0x00

playerSpeechJuhazan_1:

    .db     _K_O, _K_O, 0x00

playerSpeechJuhazan_2:

    .db     _K_U, _KWA, _KTA, _EXC, 0x00

playerTalkJuhazan_3:

    .db     PLAYER_TALK_OWNER
    .dw     playerSpeechJuhazan_3_0
    .db     PLAYER_TALK_OWNER
    .dw     playerSpeechJuhazan_3_0
    .db     PLAYER_TALK_SILENT
    .db     0x00

playerSpeechJuhazan_3_0:

    .db     _KHO, _KKU, _KTO, _KSI, _Kyu, _KSN, _K_U, _KHA, _KSA, _KSN, _KNN, 0x00

; 二指真空把
playerTalkNishishinkuha:

    .db     PLAYER_TALK_SILENT
    .db     PLAYER_TALK_OWNER
    .dw     playerSpeechNishishinkuha_0
    .db     PLAYER_TALK_OWNER
    .dw     playerSpeechNishishinkuha_1
    .db     0x00

playerSpeechNishishinkuha_0:

    .db     _KHO, _KKU, _KTO, _KSI, _KNN, _KKE, _KNN, 0x00

playerSpeechNishishinkuha_1:

    .db     _KNI, _KSI, ____, _KSI, _KNN, _KKU, _K_U, _KHA, _EXC, 0x00

; 技が効かない
playerSpeechNoEffect:

    .dw     playerSpeechNoEffect_0
    .dw     playerSpeechNoEffect_1
    .dw     playerSpeechNoEffect_2
    .dw     playerSpeechNoEffect_3
    .dw     playerSpeechNoEffect_4

playerSpeechNoEffect_0:

    .db     _KNA, _KNI, _EXC, _EXC, _EXC, 0x00

playerSpeechNoEffect_1:

    .db     _KHA, _KSN, _KKA, _KNA, _EXC, 0x00

playerSpeechNoEffect_2:

    .db     _KNA, _KNN, _KTA, _KSN, _KTO, 0x00

playerSpeechNoEffect_3:

    .db     _K_U, _K_O, _Ktu, _EXC, _EXC, 0x00

playerSpeechNoEffect_4:

    .db     _KKI, _KKA, _KNA, _K_I, _EXC, 0x00

; 死亡
playerTalkDead_0:

    .db     PLAYER_TALK_OTHER
    .dw     playerSpeechDead_0_0
    .db     PLAYER_TALK_OTHER
    .dw     playerSpeechDead_0_1
    .db     PLAYER_TALK_OTHER
    .dw     playerSpeechDead_0_2
    .db     PLAYER_TALK_OTHER
    .dw     playerSpeechDead_0_3
    .db     PLAYER_TALK_SILENT
    .db     0x00

playerSpeechDead_0_0:

    .db     _KHE, _Ktu, _KHE, _Ktu, _KHE, 0x00

playerSpeechDead_0_1:

    .db     ___7, _KTU, _KNO, ____, _KKI, _KSU, _KSN, _KNO, 0x00

playerSpeechDead_0_2:

    .db     _K_O, _KTO, _KKO, _KNO, ____, _KKU, _KHI, _KSN, _KHA, 0x00

playerSpeechDead_0_3:

    .db     _K_O, _KRE, _KSA, _KMA, ____, _KKA, _KSN, _KMO, _KRA, _Ktu, _KTA, _EXC, _EXC, 0x00

playerSpeechDead_2_0:

    .db     _KSU, _KHA, _KPS, _Ktu, 0x00

playerSpeechDead_2_1:

    .db     _KSU, _KHA, _KPS, _Ktu, _KSU, _KHA, _KPS, _Ktu, 0x00

playerTalkDead_3_0:

    .db     PLAYER_TALK_OWNER
    .dw     playerSpeechDead_3_0_0
    .db     PLAYER_TALK_OWNER
    .dw     playerSpeechDead_3_0_1
    .db     0x00

playerSpeechDead_3_0_0:

    .db     _KHO, _KSN, _KKO, _KKO, 0x00

playerSpeechDead_3_0_1:

    .db     _EXC, 0x00

playerTalkDead_3_1:

    .db     PLAYER_TALK_OWNER
    .dw     playerSpeechDead_3_1_0
    .db     0x00

playerSpeechDead_3_1_0:

    .db     _KYU, _KRI, _K_A, _K_a, _KSD, 0x00

playerTalkDead_4_1:

    .db     PLAYER_TALK_OWNER
    .dw     playerSpeechDead_3_1_0
    .db     PLAYER_TALK_SILENT
    .db     PLAYER_TALK_OTHER
    .dw     playerSpeechDead_4_1_0
    .db     PLAYER_TALK_OTHER
    .dw     playerSpeechDead_4_1_1
    .db     PLAYER_TALK_OTHER
    .dw     playerSpeechDead_4_1_2
    .db     0x00

playerSpeechDead_4_1_0:

    .db     _K_O, _KMA, _K_E, ____, _KHA, 0x00

playerSpeechDead_4_1_1:

    .db     _K_O, _KRE, _KNI, ____, _KHA, 0x00

playerSpeechDead_4_1_2:

    .db     _KKA, _KTE, _KNN, _EXC, _EXC, 0x00


; DATA 領域
;
    .area   _DATA

; 変数の定義
;

; プレイヤ
;
_player::
    
    .ds     PLAYER_LENGTH

