; Enemy.s : エネミー
;


; モジュール宣言
;
    .module Enemy

; 参照ファイル
;
    .include    "bios.inc"
    .include    "vdp.inc"
    .include    "System.inc"
    .include    "Sound.inc"
    .include    "App.inc"
    .include    "Code.inc"
    .include    "Game.inc"
    .include    "Player.inc"
    .include	"Enemy.inc"

; 外部変数宣言
;
    .globl  _patternTable

; マクロの定義
;


; CODE 領域
;
    .area   _CODE

; エネミーを初期化する
;
_EnemyInitialize::
    
    ; レジスタの保存
    
    ; エネミーの初期化
    ld      hl, #(_enemy + 0x0000)
    ld      de, #(_enemy + 0x0001)
    ld      bc, #(ENEMY_LENGTH - 0x0001)
    ld      (hl), #0x00
    ldir

    ; カウントの初期化
    xor     a
    ld      (enemyCount), a

    ; パターンジェネレータの転送
    ld      hl, #(_patternTable + 0x1200)
    ld      de, #(APP_PATTERN_GENERATOR_TABLE + 0x0400)
    ld      bc, #0x0180
    call    LDIRVM

    ; カラーテーブルの設定
    ld      a, #VDP_COLOR_MAGENTA
    call    EnemySetColor
    ld      a, #((VDP_COLOR_WHITE << 4) | VDP_COLOR_BLACK)
    ld      (_appColorTable + 0x0017), a

    ; 処理の設定
    ld      hl, #EnemyLoad
    ld      (_enemy + ENEMY_PROC_L), hl
    xor     a
    ld      (_enemy + ENEMY_STATE), a
    
    ; レジスタの復帰
    
    ; 終了
    ret

; エネミーを更新する
;
_EnemyUpdate::
    
    ; レジスタの保存

    ; 状態別の処理
    ld      hl, #10$
    push    hl
    ld      hl, (_enemy + ENEMY_PROC_L)
    jp      (hl)
;   pop     hl
10$:

    ; レジスタの復帰
    
    ; 終了
    ret

; エネミーを描画する
;
_EnemyRender::

    ; レジスタの保存

    ; 矢の描画
    ld      a, (_enemy + ENEMY_FLAG)
    bit     #ENEMY_FLAG_ARROW_BIT, a
    jr      z, 10$
    ld      hl, #enemyPatternArrow
    ld      de, (_enemy + ENEMY_ARROW_X)
    call    _GamePrintPattern
10$:

    ; 衝撃波の描画
    ld      a, (_enemy + ENEMY_FLAG)
    bit     #ENEMY_FLAG_WAVE_BIT, a
    jr      z, 20$
    ld      a, (_enemy + ENEMY_WAVE_SIZE)
    add     a, a
    ld      e, a
    ld      d, #0x00
    ld      hl, #enemyPatternWave
    add     hl, de
    ld      e, (hl)
    inc     hl
    ld      d, (hl)
    ex      de, hl
    ld      de, (_enemy + ENEMY_WAVE_X)
    call    _GamePrintPattern
20$:

    ; パターンの描画
    ld      hl, (_enemy + ENEMY_PATTERN_L)
    ld      de, (_enemy + ENEMY_POSITION_X)
    ld      a, h
    or      l
    call    nz, _GamePrintPattern

    ; 台詞の描画
    ld      hl, (_enemy + ENEMY_SPEECH_L)
    ld      de, (_enemy + ENEMY_SPEECH_X)
    ld      a, h
    or      l
    call    nz, _GamePrintString

    ; レジスタの復帰

    ; 終了
    ret

; 何もしない
;
EnemyNull:

    ; レジスタの保存

    ; レジスタの復帰

    ; 終了
    ret

; エネミーを読み込む
;
EnemyLoad:

    ; レジスタの保存

    ; エネミーの初期化
    ld      hl, #(_enemy + 0x0000)
    ld      de, #(_enemy + 0x0001)
    ld      bc, #(ENEMY_LENGTH - 0x0001)
    ld      (hl), #0x00
    ldir

    ; カウントの更新
    ld      hl, #enemyCount
    inc     (hl)

    ; エネミーの決定
    ld      a, (hl)
    and     #0x01
    jr      z, 10$
    ld      a, #ENEMY_TYPE_SHITAPPA
    jr      11$
10$:
    call    _SystemGetRandom
    and     #0x0f
    cp      #(ENEMY_TYPE_SHITAPPA + 0x01)
    jr      c, 10$
    cp      #(ENEMY_TYPE_RAOH + 0x01)
    jr      nc, 10$
11$:
;;  ld      a, #ENEMY_TYPE_HEART
    ld      (_enemy + ENEMY_TYPE), a
    call    EnemySetAction

    ; 体力の設定
    ld      hl, #0x0000
    ld      de, #300
    ld      a, (_enemy + ENEMY_TYPE)
    ld      b, a
20$:
    add     hl, de
    djnz    20$
    ld      (_enemy + ENEMY_LIFE_L), hl

    ; エネミーの配置
    call    _SystemGetRandom
    and     #0x0f
    add     a, #4
    ld      (_enemy + ENEMY_POSITION_X), a
    ld      a, #14
    ld      (_enemy + ENEMY_POSITION_Y), a

    ; パターンジェネレータの転送
    ld      a, (_enemy + ENEMY_TYPE)
    ld      d, a
    ld      e, #0x00
    srl     d
    rr      e
    ld      hl, #(_patternTable + 0x1380)
    add     hl, de
    ld      de, #(APP_PATTERN_GENERATOR_TABLE + 0x0580)
    ld      bc, #0x0080
    call    LDIRVM

    ; カラーテーブルの設定
    ld      a, #VDP_COLOR_MAGENTA
    call    EnemySetColor

    ; レジスタの復帰

    ; 終了
    ret

; シタッパが行動する
;
EnemyShitappa:

    ; レジスタの保存

    ; 初期化
    ld      a, (_enemy + ENEMY_STATE)
    or      a
    jr      nz, 09$

    ; フラグの設定
    ld      hl, #(_enemy + ENEMY_FLAG)
    set     #ENEMY_FLAG_ACTIVE_BIT, (hl)

    ; アニメーションの設定
    xor     a
    ld      (_enemy + ENEMY_ANIMATION), a

    ; パターンの設定
    ld      hl, #enemyPatternShitappaStand
    ld      (_enemy + ENEMY_PATTERN_L), hl

    ; カラーテーブルの設定
    ld      a, #VDP_COLOR_MAGENTA
    call    EnemySetColor
    
    ; 初期化の完了
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
09$:

    ; 移動
    call    EnemyWalk
    jr      nc, 90$

    ; 攻撃
    ld      hl, #EnemySeikenduki
    ld      (_enemy + ENEMY_PROC_L), hl
    xor     a
    ld      (_enemy + ENEMY_STATE), a
    jp      (hl)

    ; 行動の完了
90$:

    ; レジスタの復帰

    ; 終了
    ret

; スペードが行動する
;
EnemySpade:

    ; レジスタの保存

    ; 初期化
    ld      a, (_enemy + ENEMY_STATE)
    or      a
    jr      nz, 09$

    ; フラグの設定
    ld      hl, #(_enemy + ENEMY_FLAG)
    set     #ENEMY_FLAG_ACTIVE_BIT, (hl)
    res     #ENEMY_FLAG_ARROW_BIT, (hl)

    ; アニメーションの設定
    xor     a
    ld      (_enemy + ENEMY_ANIMATION), a

    ; パターンの設定
    ld      hl, #enemyPatternSpadeStand
    ld      (_enemy + ENEMY_PATTERN_L), hl

    ; カラーテーブルの設定
    ld      a, #VDP_COLOR_MAGENTA
    call    EnemySetColor
    
    ; 初期化の完了
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
09$:

    ; 移動
    call    EnemyWalk
    jr      nc, 90$

    ; 攻撃
    call    _SystemGetRandom
    and     #0x18
    ld      hl, #EnemySeikenduki
    jr      nz, 10$
    ld      hl, #EnemySpadeSpecial
10$:
    ld      (_enemy + ENEMY_PROC_L), hl
    xor     a
    ld      (_enemy + ENEMY_STATE), a
    jp      (hl)

    ; 行動の完了
90$:

    ; レジスタの復帰

    ; 終了
    ret

EnemySpadeSpecial:

    ; レジスタの保存

    ; 初期化
    ld      a, (_enemy + ENEMY_STATE)
    or      a
    jr      nz, 09$

    ; 攻撃方法の設定
    ld      a, #ENEMY_ATTACK_ARROW
    ld      (_enemy + ENEMY_ATTACK), a

    ; アニメーションの設定
    xor     a
    ld      (_enemy + ENEMY_ANIMATION), a

    ; パターンの設定
    ld      hl, #enemyPatternSpadeSpecial
    ld      (_enemy + ENEMY_PATTERN_L), hl

    ; 矢の設定
    ld      de, (_enemy + ENEMY_POSITION_X)
    ld      a, e
    add     a, #0x02
    ld      e, a
    ld      (_enemy + ENEMY_ARROW_X), de
    ld      hl, #(_enemy + ENEMY_FLAG)
    set     #ENEMY_FLAG_ARROW_BIT, (hl)

    ; 初期化の完了
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
09$:

    ; 0x01 : 攻撃０
10$:
;   ld      a, (_enemy + ENEMY_STATE)
;   dec     a
;   jr      nz, 20$

    ; ガード判定
    ld      a, (_enemy + ENEMY_ARROW_X)
    call    _PlayerGetDistance
    neg
    cp      #2
    jr      nc, 11$
    call    _PlayerGuard
    jr      c, 18$

    ; ヒット判定
11$:
    ld      de, #0x0000
    call    EnemyAttackArrow
    jr      nc, 12$

    ; プレイヤへのダメージ
    ld      de, #1000
    call    _PlayerTakeDamage
    jr      18$

    ; アニメーションの更新
12$:
    ld      hl, #(_enemy + ENEMY_ANIMATION)
    inc     (hl)
    ld      a, (hl)
    and     #0x01
    jr      nz, 19$

    ; 矢の更新
    ld      hl, #(_enemy + ENEMY_ARROW_X)
    inc     (hl)
    ld      a, (hl)
    cp      #0x20
    jr      c, 19$

    ; 矢の削除
18$:
    ld      hl, #(_enemy + ENEMY_FLAG)
    res     #ENEMY_FLAG_ARROW_BIT, (hl)

    ; 処理の更新
    ld      hl, #EnemySpade
    ld      (_enemy + ENEMY_PROC_L), hl
    xor     a
    ld      (_enemy + ENEMY_STATE), a
19$:
    jr      90$

    ; 行動の完了
90$:

    ; レジスタの復帰

    ; 終了
    ret

; ダイヤが行動する
;
EnemyDia:

    ; レジスタの保存

    ; 初期化
    ld      a, (_enemy + ENEMY_STATE)
    or      a
    jr      nz, 09$

    ; フラグの設定
    ld      hl, #(_enemy + ENEMY_FLAG)
    set     #ENEMY_FLAG_ACTIVE_BIT, (hl)

    ; アニメーションの設定
    xor     a
    ld      (_enemy + ENEMY_ANIMATION), a

    ; パターンの設定
    ld      hl, #enemyPatternDiaStand
    ld      (_enemy + ENEMY_PATTERN_L), hl

    ; カラーテーブルの設定
    ld      a, #VDP_COLOR_MAGENTA
    call    EnemySetColor
    
    ; 初期化の完了
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
09$:

    ; 移動
    call    EnemyWalk
    jr      nc, 90$

    ; 攻撃
    ld      hl, #EnemyDiaSpecial
    ld      (_enemy + ENEMY_PROC_L), hl
    xor     a
    ld      (_enemy + ENEMY_STATE), a
    jp      (hl)

    ; 行動の完了
90$:

    ; レジスタの復帰

    ; 終了
    ret

EnemyDiaSpecial:

    ; レジスタの保存

    ; 初期化
    ld      a, (_enemy + ENEMY_STATE)
    or      a
    jr      nz, 09$

    ; 攻撃方法の設定
    xor     a
    ld      (_enemy + ENEMY_ATTACK), a

    ; パターンの設定
    ld      hl, #enemyPatternDiaSpecial_0
    ld      (_enemy + ENEMY_PATTERN_L), hl

    ; 会話の設定
    call    _SystemGetRandom
    and     #0x01
    ld      c, a
    ld      hl, #enemyTalkDia_0
    call    EnemySelectTalk

    ; 初期化の完了
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
09$:

    ; 0x01 : 会話
10$:
    ld      a, (_enemy + ENEMY_STATE)
    dec     a
    jr      nz, 20$

    ; 会話の更新
    call    EnemyTalk
    jr      c, 19$

    ; アニメーションの設定
    ld      a, #ENEMY_ANIMATION_ATTACK
    ld      (_enemy + ENEMY_ANIMATION), a

    ; パターンの設定
    ld      hl, #enemyPatternDiaSpecial_1
    ld      (_enemy + ENEMY_PATTERN_L), hl

    ; ヒット判定
    ld      de, #0x0a02
    call    EnemyAttack
    ld      de, #450
    call    c, _PlayerTakeDamage

    ; 状態の更新
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
19$:
    jr      90$

    ; 0x02 : 攻撃
20$:
;   dec     a
;   jr      nz, 30$

    ; アニメーションの更新
    ld      hl, #(_enemy + ENEMY_ANIMATION)
    dec     (hl)
    jr      nz, 29$

    ; 処理の更新
    ld      hl, #EnemyDia
    ld      (_enemy + ENEMY_PROC_L), hl
    xor     a
    ld      (_enemy + ENEMY_STATE), a
29$:
    jr      90$

    ; 行動の完了
90$:

    ; レジスタの復帰

    ; 終了
    ret

; クラブが行動する
;
EnemyClub:

    ; レジスタの保存

    ; 初期化
    ld      a, (_enemy + ENEMY_STATE)
    or      a
    jr      nz, 09$

    ; フラグの設定
    ld      hl, #(_enemy + ENEMY_FLAG)
    set     #ENEMY_FLAG_ACTIVE_BIT, (hl)

    ; アニメーションの設定
    xor     a
    ld      (_enemy + ENEMY_ANIMATION), a

    ; パターンの設定
    ld      hl, #enemyPatternClubStand
    ld      (_enemy + ENEMY_PATTERN_L), hl

    ; カラーテーブルの設定
    ld      a, #VDP_COLOR_MAGENTA
    call    EnemySetColor
    
    ; 初期化の完了
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
09$:

    ; 移動
    call    EnemyWalk
    jr      nc, 90$

    ; 攻撃
    ld      hl, #EnemyClubSpecial
    ld      (_enemy + ENEMY_PROC_L), hl
    xor     a
    ld      (_enemy + ENEMY_STATE), a
    jp      (hl)

    ; 行動の完了
90$:

    ; レジスタの復帰

    ; 終了
    ret

EnemyClubSpecial:

    ; レジスタの保存

    ; 初期化
    ld      a, (_enemy + ENEMY_STATE)
    or      a
    jr      nz, 09$

    ; 攻撃方法の設定
    xor     a
    ld      (_enemy + ENEMY_ATTACK), a

    ; アニメーションの設定
    ld      a, #ENEMY_ANIMATION_SPECIAL
    ld      (_enemy + ENEMY_ANIMATION), a

    ; パターンの設定
    ld      hl, #enemyPatternClubSpecial_0
    ld      (_enemy + ENEMY_PATTERN_L), hl

    ; ヒット判定
    ld      de, #0x0301
    call    EnemyAttack
    ld      de, #500
    call    c, _PlayerTakeDamage

    ; 初期化の完了
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
09$:

    ; 0x01 : 攻撃０
10$:
    ld      a, (_enemy + ENEMY_STATE)
    dec     a
    jr      nz, 20$

    ; アニメーションの更新
    ld      hl, #(_enemy + ENEMY_ANIMATION)
    dec     (hl)
    jr      nz, 19$

    ; アニメーションの設定
    ld      a, #ENEMY_ANIMATION_SPECIAL
    ld      (_enemy + ENEMY_ANIMATION), a

    ; パターンの設定
    ld      hl, #enemyPatternClubSpecial_1
    ld      (_enemy + ENEMY_PATTERN_L), hl

    ; ヒット判定
    ld      de, #0x0301
    call    EnemyAttack
    ld      de, #450
    call    c, _PlayerTakeDamage

    ; 状態の更新
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
19$:
    jr      90$

    ; 0x02 : 攻撃１
20$:
    dec     a
    jr      nz, 30$

    ; アニメーションの更新
    ld      hl, #(_enemy + ENEMY_ANIMATION)
    dec     (hl)
    jr      nz, 29$

    ; アニメーションの設定
    ld      a, #ENEMY_ANIMATION_SPECIAL
    ld      (_enemy + ENEMY_ANIMATION), a

    ; パターンの設定
    ld      hl, #enemyPatternClubSpecial_0
    ld      (_enemy + ENEMY_PATTERN_L), hl

    ; 状態の更新
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
29$:
    jr      90$

    ; 0x02 : 攻撃２
30$:
;   dec     a
;   jr      nz, 40$

    ; アニメーションの更新
    ld      hl, #(_enemy + ENEMY_ANIMATION)
    dec     (hl)
    jr      nz, 39$

    ; 処理の更新
    ld      hl, #EnemyClub
    ld      (_enemy + ENEMY_PROC_L), hl
    xor     a
    ld      (_enemy + ENEMY_STATE), a
39$:
    jr      90$

    ; 行動の完了
90$:

    ; レジスタの復帰

    ; 終了
    ret

; ハートが行動する
;
EnemyHeart:

    ; レジスタの保存

    ; 初期化
    ld      a, (_enemy + ENEMY_STATE)
    or      a
    jr      nz, 09$

    ; フラグの設定
    ld      hl, #(_enemy + ENEMY_FLAG)
    set     #ENEMY_FLAG_ACTIVE_BIT, (hl)

    ; アニメーションの設定
    xor     a
    ld      (_enemy + ENEMY_ANIMATION), a

    ; パターンの設定
    ld      hl, #enemyPatternHeartStand
    ld      (_enemy + ENEMY_PATTERN_L), hl

    ; カラーテーブルの設定
    ld      a, #VDP_COLOR_MAGENTA
    call    EnemySetColor
    
    ; 初期化の完了
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
09$:

    ; 移動
    call    EnemyWalk
    jr      nc, 90$

    ; 攻撃
    ld      hl, #EnemyHeartSpecial
    ld      (_enemy + ENEMY_PROC_L), hl
    xor     a
    ld      (_enemy + ENEMY_STATE), a
    jp      (hl)

    ; 行動の完了
90$:

    ; レジスタの復帰

    ; 終了
    ret

EnemyHeartSpecial:

    ; レジスタの保存

    ; 初期化
    ld      a, (_enemy + ENEMY_STATE)
    or      a
    jr      nz, 09$

    ; 攻撃方法の設定
    xor     a
    ld      (_enemy + ENEMY_ATTACK), a

    ; アニメーションの設定
    ld      a, #ENEMY_ANIMATION_ATTACK
    ld      (_enemy + ENEMY_ANIMATION), a

    ; パターンの設定
    ld      hl, #enemyPatternHeartSpecial_0
    ld      (_enemy + ENEMY_PATTERN_L), hl

    ; 初期化の完了
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
09$:

    ; 0x01 : 攻撃０
10$:
    ld      a, (_enemy + ENEMY_STATE)
    dec     a
    jr      nz, 20$

    ; アニメーションの更新
    ld      hl, #(_enemy + ENEMY_ANIMATION)
    dec     (hl)
    jr      nz, 19$

    ; アニメーションの設定
    ld      a, #ENEMY_ANIMATION_ATTACK
    ld      (_enemy + ENEMY_ANIMATION), a

    ; パターンの設定
    ld      hl, #enemyPatternHeartSpecial_1
    ld      (_enemy + ENEMY_PATTERN_L), hl

    ; ヒット判定
    ld      de, #0x0503
    call    EnemyAttack
    ld      de, #850
    call    c, _PlayerTakeDamage

    ; 状態の更新
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
19$:
    jr      90$

    ; 0x02 : 攻撃１
20$:
;   dec     a
;   jr      nz, 30$

    ; アニメーションの更新
    ld      hl, #(_enemy + ENEMY_ANIMATION)
    dec     (hl)
    jr      nz, 29$

    ; 処理の更新
    ld      hl, #EnemyHeart
    ld      (_enemy + ENEMY_PROC_L), hl
    xor     a
    ld      (_enemy + ENEMY_STATE), a
29$:
    jr      90$

    ; 行動の完了
90$:

    ; レジスタの復帰

    ; 終了
    ret

; レイが行動する
;
EnemyRei:

    ; レジスタの保存

    ; 初期化
    ld      a, (_enemy + ENEMY_STATE)
    or      a
    jr      nz, 09$

    ; フラグの設定
    ld      hl, #(_enemy + ENEMY_FLAG)
    set     #ENEMY_FLAG_ACTIVE_BIT, (hl)

    ; アニメーションの設定
    xor     a
    ld      (_enemy + ENEMY_ANIMATION), a

    ; パターンの設定
    ld      hl, #enemyPatternReiStand
    ld      (_enemy + ENEMY_PATTERN_L), hl

    ; カラーテーブルの設定
    ld      a, #VDP_COLOR_MAGENTA
    call    EnemySetColor
    
    ; 初期化の完了
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
09$:

    ; 移動
    call    EnemyWalk
    jr      nc, 90$

    ; 攻撃
    call    _SystemGetRandom
    ld      hl, #EnemySeikenduki
    and     #0x04
    jr      z, 10$
    ld      hl, #EnemyReiSpecial
10$:
    ld      (_enemy + ENEMY_PROC_L), hl
    xor     a
    ld      (_enemy + ENEMY_STATE), a
    jp      (hl)

    ; 行動の完了
90$:

    ; レジスタの復帰

    ; 終了
    ret

EnemyReiSpecial:

    ; レジスタの保存

    ; 初期化
    ld      a, (_enemy + ENEMY_STATE)
    or      a
    jr      nz, 09$

    ; 攻撃方法の設定
    ld      a, #ENEMY_ATTACK_NANTO
    ld      (_enemy + ENEMY_ATTACK), a

    ; アニメーションの設定
    ld      a, #0x10
    ld      (_enemy + ENEMY_ANIMATION), a

    ; ヒット判定
    ld      de, #0x0401
    call    EnemyAttack
    call    c, _PlayerLock

    ; 初期化の完了
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
09$:

    ; 0x01 : 攻撃０
10$:
    ld      a, (_enemy + ENEMY_STATE)
    dec     a
    jr      nz, 20$

    ; パターンの選択
    ld      a, (_enemy + ENEMY_ANIMATION)
    and     #0x03
    ld      hl, #enemyPatternReiSpecial
    call    EnemySelectPattern

    ; アニメーションの更新
    ld      hl, #(_enemy + ENEMY_ANIMATION)
    dec     (hl)
    jr      nz, 19$

    ; ヒット判定
    ld      a, (_enemy + ENEMY_FLAG)
    bit     #ENEMY_FLAG_HIT_BIT, a
    jr      nz, 11$

    ; 処理の更新
    ld      hl, #EnemyRei
    ld      (_enemy + ENEMY_PROC_L), hl
    xor     a
    ld      (_enemy + ENEMY_STATE), a
    jr      90$

    ; 会話の設定
11$:
    ld      hl, #enemyTalkRei_0
    call    EnemySetTalk

    ; 状態の更新
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
19$:
    jr      90$

    ; 0x02 : 会話０
20$:
    dec     a
    jr      nz, 30$

    ; 会話の更新
    call    EnemyTalk
    jr      c, 29$

    ; プレイヤへのダメージ
    ld      de, #1500
    call    _PlayerTakeDamage

    ; アニメーションの設定
    ld      a, #ENEMY_ANIMATION_ATTACK
    ld      (_enemy + ENEMY_ANIMATION), a

    ; パターンの設定
    ld      hl, #enemyPatternReiStand
    ld      (_enemy + ENEMY_PATTERN_L), hl

    ; 状態の更新
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
29$:
    jr      90$

    ; 0x03 : 待機
30$:
;   dec     a
;   jr      nz, 40$

    ; アニメーションの更新
    ld      hl, #(_enemy + ENEMY_ANIMATION)
    dec     (hl)
    jr      nz, 39$

    ; 処理の更新
    ld      hl, #EnemyRei
    ld      (_enemy + ENEMY_PROC_L), hl
    xor     a
    ld      (_enemy + ENEMY_STATE), a
39$:
    jr      90$

    ; 行動の完了
90$:

    ; レジスタの復帰

    ; 終了
    ret

; ジャギが行動する
;
EnemyJagi:

    ; レジスタの保存

    ; 初期化
    ld      a, (_enemy + ENEMY_STATE)
    or      a
    jr      nz, 09$

    ; フラグの設定
    ld      hl, #(_enemy + ENEMY_FLAG)
    set     #ENEMY_FLAG_ACTIVE_BIT, (hl)

    ; アニメーションの設定
    xor     a
    ld      (_enemy + ENEMY_ANIMATION), a

    ; パターンの設定
    ld      hl, #enemyPatternJagiStand
    ld      (_enemy + ENEMY_PATTERN_L), hl

    ; カラーテーブルの設定
    ld      a, #VDP_COLOR_MAGENTA
    call    EnemySetColor
    
    ; 初期化の完了
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
09$:

    ; 移動
    call    EnemyWalk
    jr      nc, 90$

    ; 攻撃
    call    _SystemGetRandom
    and     #0x40
    ld      hl, #EnemyJagiSpecial_0
    jr      z, 10$
    ld      hl, #EnemyJagiSpecial_1
10$:
    ld      (_enemy + ENEMY_PROC_L), hl
    xor     a
    ld      (_enemy + ENEMY_STATE), a
    jp      (hl)

    ; 行動の完了
90$:

    ; レジスタの復帰

    ; 終了
    ret

EnemyJagiSpecial_0:

    ; レジスタの保存

    ; 初期化
    ld      a, (_enemy + ENEMY_STATE)
    or      a
    jr      nz, 09$

    ; 攻撃方法の設定
    ld      a, #ENEMY_ATTACK_HOKUTO
    ld      (_enemy + ENEMY_ATTACK), a

    ; アニメーションの設定
    ld      a, #0x18
    ld      (_enemy + ENEMY_ANIMATION), a

    ; ヒット判定
    ld      de, #0x0301
    call    EnemyAttack
    call    c, _PlayerLock

    ; 初期化の完了
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
09$:

    ; 0x01 : 攻撃０
10$:
    ld      a, (_enemy + ENEMY_STATE)
    dec     a
    jr      nz, 20$

    ; パターンの選択
    ld      a, (_enemy + ENEMY_ANIMATION)
    and     #0x03
    ld      hl, #enemyPatternJagiSpecial_0
    call    EnemySelectPattern

    ; アニメーションの更新
    ld      hl, #(_enemy + ENEMY_ANIMATION)
    dec     (hl)
    jr      nz, 19$

    ; ヒット判定
    ld      a, (_enemy + ENEMY_FLAG)
    bit     #ENEMY_FLAG_HIT_BIT, a
    jr      nz, 11$

    ; 処理の更新
    ld      hl, #EnemyJagi
    ld      (_enemy + ENEMY_PROC_L), hl
    xor     a
    ld      (_enemy + ENEMY_STATE), a
    jr      90$

    ; 会話の設定
11$:
    ld      hl, #enemyTalkJagi_0
    call    EnemySetTalk

    ; 状態の更新
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
19$:
    jr      90$

    ; 0x02 : 会話０
20$:
    dec     a
    jr      nz, 30$

    ; 会話の更新
    call    EnemyTalk
    jr      c, 29$

    ; プレイヤへのダメージ
    ld      de, #900
    call    _PlayerTakeDamage

    ; アニメーションの設定
    ld      a, #ENEMY_ANIMATION_ATTACK
    ld      (_enemy + ENEMY_ANIMATION), a

    ; パターンの設定
    ld      hl, #enemyPatternJagiStand
    ld      (_enemy + ENEMY_PATTERN_L), hl

    ; 状態の更新
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
29$:
    jr      90$

    ; 0x03 : 待機
30$:
;   dec     a
;   jr      nz, 40$

    ; アニメーションの更新
    ld      hl, #(_enemy + ENEMY_ANIMATION)
    dec     (hl)
    jr      nz, 39$

    ; 処理の更新
    ld      hl, #EnemyJagi
    ld      (_enemy + ENEMY_PROC_L), hl
    xor     a
    ld      (_enemy + ENEMY_STATE), a
39$:
    jr      90$

    ; 行動の完了
90$:

    ; レジスタの復帰

    ; 終了
    ret

EnemyJagiSpecial_1:

    ; レジスタの保存

    ; 初期化
    ld      a, (_enemy + ENEMY_STATE)
    or      a
    jr      nz, 09$

    ; 攻撃方法の設定
    ld      a, #ENEMY_ATTACK_NANTO
    ld      (_enemy + ENEMY_ATTACK), a

    ; パターンの設定
    ld      hl, #enemyPatternJagiSpecial_1
    ld      (_enemy + ENEMY_PATTERN_L), hl

    ; 台詞の設定
    ld      hl, #enemySpeechJagi_1
    ld      a, #ENEMY_ANIMATION_ATTACK
    call    EnemySetSpeechOwner

    ; ヒット判定
    ld      de, #0x0402
    call    EnemyAttack
    ld      de, #400
    call    c, _PlayerTakeDamage

    ; 初期化の完了
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
09$:

    ; 0x01 : 会話０
10$:
;   ld      a, (_enemy + ENEMY_STATE)
;   dec     a
;   jr      nz, 20$

    ; 台詞の更新
    call    EnemySpeechOwner
    jr      c, 19$

    ; 処理の更新
    ld      hl, #EnemyJagi
    ld      (_enemy + ENEMY_PROC_L), hl
    xor     a
    ld      (_enemy + ENEMY_STATE), a
19$:
    jr      90$

    ; 行動の完了
90$:

    ; レジスタの復帰

    ; 終了
    ret

; ユダが行動する
;
EnemyJuda:

    ; レジスタの保存

    ; 初期化
    ld      a, (_enemy + ENEMY_STATE)
    or      a
    jr      nz, 09$

    ; フラグの設定
    ld      hl, #(_enemy + ENEMY_FLAG)
    set     #ENEMY_FLAG_ACTIVE_BIT, (hl)
    res     #ENEMY_FLAG_WAVE_BIT, (hl)

    ; アニメーションの設定
    xor     a
    ld      (_enemy + ENEMY_ANIMATION), a

    ; パターンの設定
    ld      hl, #enemyPatternJudaStand
    ld      (_enemy + ENEMY_PATTERN_L), hl

    ; カラーテーブルの設定
    ld      a, #VDP_COLOR_MAGENTA
    call    EnemySetColor
    
    ; 初期化の完了
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
09$:

    ; 移動
    call    EnemyWalk
    jr      nc, 90$

    ; 攻撃
    call    _SystemGetRandom
    ld      hl, #EnemySeikenduki
    and     #0x21
    jr      nz, 10$
    ld      hl, #EnemyJudaSpecial
10$:
    ld      (_enemy + ENEMY_PROC_L), hl
    xor     a
    ld      (_enemy + ENEMY_STATE), a
    jp      (hl)

    ; 行動の完了
90$:

    ; レジスタの復帰

    ; 終了
    ret

EnemyJudaSpecial:

    ; レジスタの保存

    ; 初期化
    ld      a, (_enemy + ENEMY_STATE)
    or      a
    jr      nz, 09$

    ; 攻撃方法の設定
    ld      a, #ENEMY_ATTACK_NANTO
    ld      (_enemy + ENEMY_ATTACK), a

    ; アニメーションの設定
    xor     a
    ld      (_enemy + ENEMY_ANIMATION), a

    ; 初期化の完了
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
09$:

    ; 0x01 : 攻撃０
10$:
    ld      a, (_enemy + ENEMY_STATE)
    dec     a
    jr      nz, 20$

    ; パターンの選択
    ld      a, (_enemy + ENEMY_ANIMATION)
    and     #0x03
    ld      hl, #enemyPatternJudaSpecial_0
    call    EnemySelectPattern

    ; アニメーションの更新
    ld      hl, #(_enemy + ENEMY_ANIMATION)
    inc     (hl)
    ld      a, (hl)
    cp      #(0x03 * 0x04 * 0x01)
    jr      c, 19$

    ; アニメーションの設定
    xor     a
    ld      (_enemy + ENEMY_ANIMATION), a

    ; 衝撃波の設定
    ld      de, (_enemy + ENEMY_POSITION_X)
    inc     e
    inc     e
    inc     e
    inc     d
    inc     d
    inc     d
    ld      (_enemy + ENEMY_WAVE_X), de
    ld      a, #0x01
    ld      (_enemy + ENEMY_WAVE_SIZE), a
    ld      hl, #(_enemy + ENEMY_FLAG)
    set     #ENEMY_FLAG_WAVE_BIT, (hl)

    ; 状態の更新
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
19$:
    jr      90$

    ; 0x02 : 攻撃１
20$:
    dec     a
    jr      nz, 30$

    ; ヒット判定
    ld      a, (_enemy + ENEMY_POSITION_X)
    ld      e, a
    ld      a, (_enemy + ENEMY_WAVE_X)
    sub     e
    ld      e, a
    inc     a
    ld      d, a
    call    EnemyAttack
    jr      nc, 21$

    ; プレイヤのロック
    call    _PlayerLock

    ; 会話の設定
    ld      hl, #enemyTalkJuda_0
    call    EnemySetTalk

    ; 状態の更新
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
    jr      29$

    ; アニメーションの更新
21$:
    ld      hl, #(_enemy + ENEMY_ANIMATION)
    inc     (hl)
    ld      a, (hl)
    and     #0x03
    jr      nz, 29$

    ; 衝撃波の更新
    ld      hl, #(_enemy + ENEMY_WAVE_SIZE)
    ld      a, (hl)
    cp      #ENEMY_WAVE_SIZE_MAX
    jr      nc, 22$
    inc     (hl)
    ld      hl, #(_enemy + ENEMY_WAVE_X)
    inc     (hl)
    jr      29$

    ; 状態の更新
22$:
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
    inc     (hl)
29$:
    jr      90$

    ; 0x03 : 会話
30$:
    dec     a
    jr      nz, 40$

    ; 会話の更新
    call    EnemyTalk
    jr      c, 39$

    ; プレイヤへのダメージ
    ld      de, #650
    call    _PlayerTakeDamage

    ; アニメーションの設定
    xor     a
    ld      (_enemy + ENEMY_ANIMATION), a

    ; 状態の更新
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
39$:
    jr      90$

    ; 0x04 : 攻撃２
40$:
;   dec     a
;   jr      nz, 50$

    ; アニメーションの更新
    ld      hl, #(_enemy + ENEMY_ANIMATION)
    inc     (hl)
    ld      a, (hl)
    and     #0x01
    jr      nz, 49$

    ; 衝撃波の更新
    ld      hl, #(_enemy + ENEMY_WAVE_SIZE)
    dec     (hl)
    jr      nz, 49$

    ; 処理の更新
    ld      hl, #EnemyJuda
    ld      (_enemy + ENEMY_PROC_L), hl
    xor     a
    ld      (_enemy + ENEMY_STATE), a
49$:
    jr      90$

    ; 行動の完了
90$:

    ; レジスタの復帰

    ; 終了
    ret

; シュウが行動する
;
EnemyShew:

    ; レジスタの保存

    ; 初期化
    ld      a, (_enemy + ENEMY_STATE)
    or      a
    jr      nz, 09$

    ; フラグの設定
    ld      hl, #(_enemy + ENEMY_FLAG)
    set     #ENEMY_FLAG_ACTIVE_BIT, (hl)

    ; アニメーションの設定
    xor     a
    ld      (_enemy + ENEMY_ANIMATION), a

    ; パターンの設定
    ld      hl, #enemyPatternShewStand
    ld      (_enemy + ENEMY_PATTERN_L), hl

    ; カラーテーブルの設定
    ld      a, #VDP_COLOR_MAGENTA
    call    EnemySetColor
    
    ; 初期化の完了
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
09$:

    ; 移動
    call    EnemyWalk
    jr      nc, 90$

    ; 攻撃
    call    _SystemGetRandom
    ld      hl, #EnemyShewSpecial_0
    and     #0x03
    jr      z, 10$
    ld      hl, #EnemyShewSpecial_1
    dec     a
    jr      z, 10$
    ld      hl, #EnemyShewSpecial_2
    dec     a
    jr      z, 10$
    ld      hl, #EnemyShewSpecial_3
10$:
    ld      (_enemy + ENEMY_PROC_L), hl
    xor     a
    ld      (_enemy + ENEMY_STATE), a
    jp      (hl)

    ; 行動の完了
90$:

    ; レジスタの復帰

    ; 終了
    ret

EnemyShewSpecial_0:

    ; レジスタの保存

    ; 初期化
    ld      a, (_enemy + ENEMY_STATE)
    or      a
    jr      nz, 09$

    ; 攻撃方法の設定
    ld      a, #ENEMY_ATTACK_NANTO
    ld      (_enemy + ENEMY_ATTACK), a

    ; 位置の更新
    ld      de, #0x0002
    call    _EnemyMove

    ; パターンの設定
    ld      hl, #enemyPatternShewSpecial_0_0
    ld      (_enemy + ENEMY_PATTERN_L), hl

    ; 台詞の設定
    ld      hl, #enemySpeechShew_0
    ld      a, #ENEMY_ANIMATION_SPECIAL
    call    EnemySetSpeechOwner

    ; 初期化の完了
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
09$:

    ; 0x01 : 攻撃０
10$:
    ld      a, (_enemy + ENEMY_STATE)
    dec     a
    jr      nz, 20$

    ; 台詞の更新
    call    EnemySpeechOwner
    jr      c, 19$

    ; 位置の更新
    ld      de, #0x0002
    call    _EnemyMove

    ; アニメーションの設定
    ld      a, #ENEMY_ANIMATION_SPECIAL
    ld      (_enemy + ENEMY_ANIMATION), a

    ; パターンの設定
    ld      hl, #enemyPatternShewSpecial_0_1
    ld      (_enemy + ENEMY_PATTERN_L), hl

    ; ヒット判定
    ld      de, #0x0302
    call    EnemyAttack
    ld      de, #500
    call    c, _PlayerTakeDamage

    ; 状態の更新
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
19$:
    jr      90$

    ; 0x02 : 攻撃１
20$:
    dec     a
    jr      nz, 30$

    ; アニメーションの更新
    ld      hl, #(_enemy + ENEMY_ANIMATION)
    dec     (hl)
    jr      nz, 29$

    ; 位置の更新
    ld      de, #0x0002
    call    _EnemyMove

    ; アニメーションの設定
    ld      a, #ENEMY_ANIMATION_SPECIAL
    ld      (_enemy + ENEMY_ANIMATION), a

    ; パターンの設定
    ld      hl, #enemyPatternShewSpecial_0_2
    ld      (_enemy + ENEMY_PATTERN_L), hl

    ; 状態の更新
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
29$:
    jr      90$

    ; 0x03 : 攻撃２
30$:
    dec     a
    jr      nz, 40$

    ; アニメーションの更新
    ld      hl, #(_enemy + ENEMY_ANIMATION)
    dec     (hl)
    jr      nz, 39$

    ; 位置の更新
    ld      de, #0x0002
    call    _EnemyMove

    ; アニメーションの設定
    ld      a, #ENEMY_ANIMATION_SPECIAL
    ld      (_enemy + ENEMY_ANIMATION), a

    ; パターンの設定
    ld      hl, #enemyPatternShewStand
    ld      (_enemy + ENEMY_PATTERN_L), hl

    ; 状態の更新
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
39$:
    jr      90$

    ; 0x04 : 着地
40$:
;   dec     a
;   jr      nz, 50$

    ; アニメーションの更新
    ld      hl, #(_enemy + ENEMY_ANIMATION)
    dec     (hl)
    jr      nz, 49$

    ; 処理の更新
    ld      hl, #EnemyShew
    ld      (_enemy + ENEMY_PROC_L), hl
    xor     a
    ld      (_enemy + ENEMY_STATE), a
49$:
    jr      90$

    ; 行動の完了
90$:

    ; レジスタの復帰

    ; 終了
    ret

EnemyShewSpecial_1:

    ; レジスタの保存

    ; 初期化
    ld      a, (_enemy + ENEMY_STATE)
    or      a
    jr      nz, 09$

    ; 攻撃方法の設定
    ld      a, #ENEMY_ATTACK_NANTO
    ld      (_enemy + ENEMY_ATTACK), a

    ; アニメーションの設定
    xor     a
    ld      (_enemy + ENEMY_ANIMATION), a

    ; 初期化の完了
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
09$:

    ; 0x01 : 攻撃０
10$:
    ld      a, (_enemy + ENEMY_STATE)
    dec     a
    jr      nz, 20$

    ; パターンの選択
    ld      a, (_enemy + ENEMY_ANIMATION)
    srl     a
    srl     a
    ld      hl, #enemyPatternShewSpecial_1_0
    call    EnemySelectPattern

    ; アニメーションの更新
    ld      hl, #(_enemy + ENEMY_ANIMATION)
    inc     (hl)
    ld      a, (hl)
    cp      #(0x05 * 0x04)
    jr      c, 19$

    ; ヒット判定
    ld      de, #0x0401
    call    EnemyAttack
    jr      c, 11$

    ; 処理の更新
    ld      hl, #EnemyShew
    ld      (_enemy + ENEMY_PROC_L), hl
    xor     a
    ld      (_enemy + ENEMY_STATE), a
    jr      90$

    ; ヒット
11$:
    call    _PlayerLock

    ; 状態の更新
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
19$:
    jr      90$

    ; 0x02 : 攻撃１
20$:
    dec     a
    jr      nz, 30$

    ; 位置の更新
    ld      de, #0x0005
    call    _EnemyMove

    ; アニメーションの設定
    xor     a
    ld      (_enemy + ENEMY_ANIMATION), a

    ; 状態の更新
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
    jr      31$

    ; 0x03：攻撃２
30$:
    dec     a
    jr      nz, 40$
31$:

    ; パターンの選択
    ld      a, (_enemy + ENEMY_ANIMATION)
    srl     a
    srl     a
    srl     a
    ld      hl, #enemyPatternShewSpecial_1_1
    call    EnemySelectPattern

    ; アニメーションの更新
    ld      hl, #(_enemy + ENEMY_ANIMATION)
    inc     (hl)
    ld      a, (hl)
    cp      #(0x02 * 0x08)
    jr      c, 39$

    ; 会話の設定
    ld      hl, #enemyTalkShew_1
    call    EnemySetTalk

    ; 状態の更新
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
39$:
    jr      90$

    ; 0x04 : 会話０
40$:
    dec     a
    jr      nz, 50$

    ; 会話の更新
    call    EnemyTalk
    jr      c, 49$

    ; プレイヤへのダメージ
    ld      de, #1000
    call    _PlayerTakeDamage

    ; アニメーションの設定
    ld      a, #ENEMY_ANIMATION_ATTACK
    ld      (_enemy + ENEMY_ANIMATION), a

    ; パターンの設定
    ld      hl, #enemyPatternShewStand
    ld      (_enemy + ENEMY_PATTERN_L), hl

    ; 状態の更新
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
49$:
    jr      90$

    ; 0x05 : 攻撃の完了
50$:
;   dec     a
;   jr      nz, 60$

    ; アニメーションの更新
    ld      hl, #(_enemy + ENEMY_ANIMATION)
    dec     (hl)
    jr      nz, 59$

    ; 処理の更新
    ld      hl, #EnemyShew
    ld      (_enemy + ENEMY_PROC_L), hl
    xor     a
    ld      (_enemy + ENEMY_STATE), a
59$:
    jr      90$

    ; 行動の完了
90$:

    ; レジスタの復帰

    ; 終了
    ret

EnemyShewSpecial_2:

    ; レジスタの保存

    ; 初期化
    ld      a, (_enemy + ENEMY_STATE)
    or      a
    jr      nz, 09$

    ; 攻撃方法の設定
    ld      a, #ENEMY_ATTACK_NANTO
    ld      (_enemy + ENEMY_ATTACK), a

    ; パターンの設定
    ld      hl, #enemyPatternShewSpecial_2_0
    ld      (_enemy + ENEMY_PATTERN_L), hl

    ; 台詞の設定
    ld      hl, #enemySpeechShew_2_0
    ld      a, #ENEMY_ANIMATION_ATTACK
    call    EnemySetSpeechOwner

    ; 初期化の完了
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
09$:

    ; 0x01 : 攻撃０
10$:
    ld      a, (_enemy + ENEMY_STATE)
    dec     a
    jr      nz, 20$

    ; 台詞の更新
    call    EnemySpeechOwner
    jr      c, 19$

    ; ヒット判定
    ld      de, #0x0402
    call    EnemyAttack
    jr      c, 11$

    ; 処理の更新
    ld      hl, #EnemyShew
    ld      (_enemy + ENEMY_PROC_L), hl
    xor     a
    ld      (_enemy + ENEMY_STATE), a
    jr      90$

    ; ヒット
11$:
    call    _PlayerLock

    ; アニメーションの設定
    ld      a, #0x60
    ld      (_enemy + ENEMY_ANIMATION), a

    ; 状態の更新
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
19$:
    jr      90$

    ; 0x02 : 攻撃１
20$:
    dec     a
    jr      nz, 30$

    ; パターンの選択
    ld      a, (_enemy + ENEMY_ANIMATION)
    srl     a
    srl     a
    and     #0x01
    ld      c, a
    ld      hl, #enemyPatternShewSpecial_2
    call    EnemySelectPattern

    ; 台詞の選択
    ld      a, c
    or      a
    jr      z, 21$
    ld      hl, #enemySpeechShew_2_1
    call    _EnemySetSpeech
    jr      22$
21$:
    call    _EnemyClearSpeech
22$:

    ; アニメーションの更新
    ld      hl, #(_enemy + ENEMY_ANIMATION)
    dec     (hl)
    jr      nz, 29$

    ; パターンの設定
    ld      hl, #enemyPatternShewStand
    ld      (_enemy + ENEMY_PATTERN_L), hl

    ; 会話の設定
    ld      hl, #enemyTalkShew_2_2
    call    EnemySetTalk

    ; 状態の更新
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
29$:
    jr      90$

    ; 0x03：会話０
30$:
    dec     a
    jr      nz, 40$

    ; 会話の更新
    call    EnemyTalk
    jr      c, 39$

    ; プレイヤへのダメージ
    ld      de, #800
    call    _PlayerTakeDamage

    ; アニメーションの設定
    ld      a, #ENEMY_ANIMATION_ATTACK
    ld      (_enemy + ENEMY_ANIMATION), a

    ; 状態の更新
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
39$:
    jr      90$

    ; 0x04 : 攻撃の完了
40$:
;   dec     a
;   jr      nz, 50$

    ; アニメーションの更新
    ld      hl, #(_enemy + ENEMY_ANIMATION)
    dec     (hl)
    jr      nz, 49$

    ; 処理の更新
    ld      hl, #EnemyShew
    ld      (_enemy + ENEMY_PROC_L), hl
    xor     a
    ld      (_enemy + ENEMY_STATE), a
49$:
    jr      90$

    ; 行動の完了
90$:

    ; レジスタの復帰

    ; 終了
    ret

EnemyShewSpecial_3:

    ; レジスタの保存

    ; 初期化
    ld      a, (_enemy + ENEMY_STATE)
    or      a
    jr      nz, 09$

    ; 攻撃方法の設定
    ld      a, #ENEMY_ATTACK_NANTO
    ld      (_enemy + ENEMY_ATTACK), a

    ; パターンの設定
    ld      hl, #enemyPatternShewSpecial_3_0
    ld      (_enemy + ENEMY_PATTERN_L), hl

    ; 台詞の設定
    ld      hl, #enemySpeechShew_3_0
    ld      a, #ENEMY_ANIMATION_ATTACK
    call    EnemySetSpeechOwner

    ; 初期化の完了
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
09$:

    ; 0x01 : 攻撃０
10$:
    ld      a, (_enemy + ENEMY_STATE)
    dec     a
    jr      nz, 20$

    ; 台詞の更新
    call    EnemySpeechOwner
    jr      c, 19$

    ; ヒット判定
    ld      de, #0x0301
    call    EnemyAttack
    jr      c, 11$

    ; 処理の更新
    ld      hl, #EnemyShew
    ld      (_enemy + ENEMY_PROC_L), hl
    xor     a
    ld      (_enemy + ENEMY_STATE), a
    jr      90$

    ; ヒット
11$:
    call    _PlayerLock

    ; アニメーションの設定
    ld      a, #0x60
    ld      (_enemy + ENEMY_ANIMATION), a

    ; 状態の更新
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
19$:
    jr      90$

    ; 0x02 : 攻撃１
20$:
    dec     a
    jr      nz, 30$

    ; パターンの選択
    ld      a, (_enemy + ENEMY_ANIMATION)
    srl     a
    and     #0x07
    ld      hl, #enemyPatternShewSpecial_3
    call    EnemySelectPattern

    ; アニメーションの更新
    ld      hl, #(_enemy + ENEMY_ANIMATION)
    dec     (hl)
    jr      nz, 29$

    ; パターンの設定
    ld      hl, #enemyPatternShewStand
    ld      (_enemy + ENEMY_PATTERN_L), hl

    ; 会話の設定
    ld      hl, #enemyTalkShew_3_1
    call    EnemySetTalk

    ; 状態の更新
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
29$:
    jr      90$

    ; 0x03：会話０
30$:
    dec     a
    jr      nz, 40$

    ; 会話の更新
    call    EnemyTalk
    jr      c, 39$

    ; プレイヤへのダメージ
    ld      de, #900
    call    _PlayerTakeDamage

    ; アニメーションの設定
    ld      a, #ENEMY_ANIMATION_ATTACK
    ld      (_enemy + ENEMY_ANIMATION), a

    ; 状態の更新
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
39$:
    jr      90$

    ; 0x04 : 攻撃の完了
40$:
;   dec     a
;   jr      nz, 50$

    ; アニメーションの更新
    ld      hl, #(_enemy + ENEMY_ANIMATION)
    dec     (hl)
    jr      nz, 49$

    ; 処理の更新
    ld      hl, #EnemyShew
    ld      (_enemy + ENEMY_PROC_L), hl
    xor     a
    ld      (_enemy + ENEMY_STATE), a
49$:
    jr      90$

    ; 行動の完了
90$:

    ; レジスタの復帰

    ; 終了
    ret

; ラオウが行動する
;
EnemyRaoh:

    ; レジスタの保存

    ; 初期化
    ld      a, (_enemy + ENEMY_STATE)
    or      a
    jr      nz, 09$

    ; フラグの設定
    ld      hl, #(_enemy + ENEMY_FLAG)
    set     #ENEMY_FLAG_ACTIVE_BIT, (hl)

    ; アニメーションの設定
    xor     a
    ld      (_enemy + ENEMY_ANIMATION), a

    ; パターンの設定
    ld      hl, #enemyPatternRaohStand
    ld      (_enemy + ENEMY_PATTERN_L), hl

    ; カラーテーブルの設定
    ld      a, #VDP_COLOR_MAGENTA
    call    EnemySetColor
    
    ; 初期化の完了
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
09$:

    ; 移動
    call    EnemyWalk
    jr      nc, 90$

    ; 攻撃
    call    _SystemGetRandom
    ld      hl, #EnemySeikenduki
    and     #0x03
    jr      z, 10$
    ld      hl, #EnemyRaohSpecial_0
    dec     a
    jr      z, 10$
    ld      hl, #EnemyRaohSpecial_1
    dec     a
    jr      z, 10$
    ld      hl, #EnemyRaohSpecial_2
10$:
    ld      (_enemy + ENEMY_PROC_L), hl
    xor     a
    ld      (_enemy + ENEMY_STATE), a
    jp      (hl)

    ; 行動の完了
90$:

    ; レジスタの復帰

    ; 終了
    ret

EnemyRaohSpecial_0:

    ; レジスタの保存

    ; 初期化
    ld      a, (_enemy + ENEMY_STATE)
    or      a
    jr      nz, 09$

    ; 攻撃方法の設定
    ld      a, #ENEMY_ATTACK_HOKUTO
    ld      (_enemy + ENEMY_ATTACK), a

    ; パターンの設定
    ld      hl, #enemyPatternRaohSpecial_0_0
    ld      (_enemy + ENEMY_PATTERN_L), hl

    ; 台詞の設定
    ld      hl, #enemySpeechRaoh_0
    ld      a, #ENEMY_ANIMATION_SPECIAL
    call    EnemySetSpeechOwner

    ; ヒット判定
    ld      de, #0x0301
    call    EnemyAttack
    ld      de, #1100
    call    c, _PlayerTakeDamage

    ; 初期化の完了
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
09$:

    ; 0x01 : 攻撃０
10$:
    ld      a, (_enemy + ENEMY_STATE)
    dec     a
    jr      nz, 20$

    ; 台詞の更新
    call    EnemySpeechOwner
    jr      c, 19$

    ; アニメーションの設定
    ld      a, #ENEMY_ANIMATION_SPECIAL
    ld      (_enemy + ENEMY_ANIMATION), a

    ; パターンの設定
    ld      hl, #enemyPatternRaohSpecial_0_1
    ld      (_enemy + ENEMY_PATTERN_L), hl

    ; 状態の更新
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
19$:
    jr      90$

    ; 0x02 : 攻撃１
20$:
;   dec     a
;   jr      nz, 30$

    ; アニメーションの更新
    ld      hl, #(_enemy + ENEMY_ANIMATION)
    dec     (hl)
    jr      nz, 29$

    ; 処理の更新
    ld      hl, #EnemyRaoh
    ld      (_enemy + ENEMY_PROC_L), hl
    xor     a
    ld      (_enemy + ENEMY_STATE), a
29$:
    jr      90$

    ; 行動の完了
90$:

    ; レジスタの復帰

    ; 終了
    ret

EnemyRaohSpecial_1:

    ; レジスタの保存

    ; 初期化
    ld      a, (_enemy + ENEMY_STATE)
    or      a
    jr      nz, 09$

    ; 攻撃方法の設定
    ld      a, #ENEMY_ATTACK_HOKUTO
    ld      (_enemy + ENEMY_ATTACK), a

    ; アニメーションの設定
    ld      a, #ENEMY_ANIMATION_ATTACK
    ld      (_enemy + ENEMY_ANIMATION), a

    ; パターンの設定
    ld      hl, #enemyPatternRaohSpecial_1_0
    ld      (_enemy + ENEMY_PATTERN_L), hl

    ; 初期化の完了
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
09$:

    ; 0x01 : 攻撃０
10$:
    ld      a, (_enemy + ENEMY_STATE)
    dec     a
    jr      nz, 20$

    ; アニメーションの更新
    ld      hl, #(_enemy + ENEMY_ANIMATION)
    dec     (hl)
    jr      nz, 19$

    ; ヒット判定
    ld      de, #0x0302
    call    EnemyAttack
    ld      de, #1300
    call    c, _PlayerTakeDamage

    ; パターンの設定
    ld      hl, #enemyPatternRaohSpecial_1_1
    ld      (_enemy + ENEMY_PATTERN_L), hl

    ; 台詞の設定
    ld      hl, #enemySpeechRaoh_1
    ld      a, #ENEMY_ANIMATION_ATTACK
    call    EnemySetSpeechOwner

    ; 状態の更新
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
19$:
    jr      90$

    ; 0x02 : 攻撃１
20$:
;   dec     a
;   jr      nz, 30$

    ; 台詞の更新
    call    EnemySpeechOwner
    jr      c, 29$

    ; 処理の更新
    ld      hl, #EnemyRaoh
    ld      (_enemy + ENEMY_PROC_L), hl
    xor     a
    ld      (_enemy + ENEMY_STATE), a
29$:
    jr      90$

    ; 行動の完了
90$:

    ; レジスタの復帰

    ; 終了
    ret

EnemyRaohSpecial_2:

    ; レジスタの保存

    ; 初期化
    ld      a, (_enemy + ENEMY_STATE)
    or      a
    jr      nz, 09$

    ; 攻撃方法の設定
    ld      a, #ENEMY_ATTACK_HIKO
    ld      (_enemy + ENEMY_ATTACK), a

    ; アニメーションの設定
    ld      a, #ENEMY_ANIMATION_ATTACK
    ld      (_enemy + ENEMY_ANIMATION), a

    ; パターンの設定
    ld      hl, #enemyPatternRaohSpecial_2
    ld      (_enemy + ENEMY_PATTERN_L), hl

    ; ヒット判定
    ld      de, #0x0303
    call    EnemyAttack
    call    c, _PlayerLock

    ; 初期化の完了
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
09$:

    ; 0x01 : 攻撃０
10$:
    ld      a, (_enemy + ENEMY_STATE)
    dec     a
    jr      nz, 20$

    ; アニメーションの更新
    ld      hl, #(_enemy + ENEMY_ANIMATION)
    dec     (hl)
    jr      nz, 19$

    ; ヒット判定
    ld      a, (_enemy + ENEMY_FLAG)
    bit     #ENEMY_FLAG_HIT_BIT, a
    jr      nz, 11$

    ; 処理の更新
    ld      hl, #EnemyRaoh
    ld      (_enemy + ENEMY_PROC_L), hl
    xor     a
    ld      (_enemy + ENEMY_STATE), a
    jr      90$

    ; 会話の設定
11$:
    ld      hl, #enemyTalkRaoh_2
    call    EnemySetTalk

    ; 状態の更新
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
19$:
    jr      90$

    ; 0x02 : 攻撃１
20$:
;   dec     a
;   jr      nz, 30$

    ; 会話の更新
    call    EnemyTalk
    jr      c, 29$

    ; プレイヤへのダメージ
    ld      de, #9999
    call    _PlayerTakeDamage

    ; パターンの設定
    ld      hl, #enemyPatternRaohStand
    ld      (_enemy + ENEMY_PATTERN_L), hl

    ; 処理の更新
    ld      hl, #EnemyIdle
    ld      (_enemy + ENEMY_PROC_L), hl
    xor     a
    ld      (_enemy + ENEMY_STATE), a
29$:
    jr      90$

    ; 行動の完了
90$:

    ; レジスタの復帰

    ; 終了
    ret

; エネミーが待機する
;
EnemyIdle:

    ; レジスタの保存

    ; レジスタの復帰

    ; 終了
    ret

; エネミーがダメージを受けている
;
EnemyDamage:

    ; レジスタの保存

    ; 初期化
    ld      a, (_enemy + ENEMY_STATE)
    or      a
    jr      nz, 09$

    ; フラグの設定
    ld      hl, #(_enemy + ENEMY_FLAG)
    res     #ENEMY_FLAG_ACTIVE_BIT, (hl)
    res     #ENEMY_FLAG_ARROW_BIT, (hl)
    res     #ENEMY_FLAG_WAVE_BIT, (hl)

    ; アニメーションの設定
    ld      a, #ENEMY_ANIMATION_DAMAGE
    ld      (_enemy + ENEMY_ANIMATION), a

    ; カラーテーブルの設定
    ld      a, #VDP_COLOR_MEDIUM_RED
    call    EnemySetColor

    ; 台詞の消去
    call    _EnemyClearSpeech
    
    ; 初期化の完了
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
09$:

    ; アニメーションの更新
    ld      hl, #(_enemy + ENEMY_ANIMATION)
    dec     (hl)
    jr      nz, 19$

    ; 体力の確認
    ld      hl, (_enemy + ENEMY_LIFE_L)
    ld      a, h
    or      l
    jr      z, 10$

    ; 処理の更新
    call    EnemySetAction
    jr      19$
10$:
    ld      hl, #EnemyDown
    ld      (_enemy + ENEMY_PROC_L), hl
    xor     a
    ld      (_enemy + ENEMY_STATE), a
19$:

    ; レジスタの復帰

    ; 終了
    ret

; エネミーが倒れる
;
EnemyDown:

    ; レジスタの保存

    ; 初期化
    ld      a, (_enemy + ENEMY_STATE)
    or      a
    jr      nz, 09$

    ; フラグの設定
    ld      hl, #(_enemy + ENEMY_FLAG)
    res     #ENEMY_FLAG_ACTIVE_BIT, (hl)
    res     #ENEMY_FLAG_ARROW_BIT, (hl)
    res     #ENEMY_FLAG_WAVE_BIT, (hl)

    ; 位置の設定
    ld      a, #14
    ld      (_enemy + ENEMY_POSITION_Y), a

    ; アニメーションの設定
    ld      a, #ENEMY_ANIMATION_DOWN
    ld      (_enemy + ENEMY_ANIMATION), a

    ; パターンの設定
    ld      hl, #enemyPatternDown
    ld      (_enemy + ENEMY_PATTERN_L), hl

    ; 台詞の設定
    ld      hl, #enemySpeechDown
    call    _EnemySetSpeech

    ; カラーテーブルの設定
    ld      a, #VDP_COLOR_MEDIUM_RED
    call    EnemySetColor

    ; スコアの加算
    ld      hl, #0x0000
    ld      de, #GAME_SCORE_WIN
    ld      a, (_enemy + ENEMY_TYPE)
    ld      b, a
00$:
    add     hl, de
    djnz    00$
    call    _GameAddScore

    ; 初期化の完了
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
09$:

    ; アニメーションの更新
    ld      hl, #(_enemy + ENEMY_ANIMATION)
    dec     (hl)
    jr      nz, 19$

    ; 処理の更新
    ld      hl, #EnemyLoad
    ld      (_enemy + ENEMY_PROC_L), hl
    xor     a
    ld      (_enemy + ENEMY_STATE), a
19$:

    ; レジスタの復帰

    ; 終了
    ret

; エネミーが爆発する
;
EnemyBomb:

    ; レジスタの保存

    ; 初期化
    ld      a, (_enemy + ENEMY_STATE)
    or      a
    jr      nz, 09$

    ; フラグの設定
    ld      hl, #(_enemy + ENEMY_FLAG)
    res     #ENEMY_FLAG_ACTIVE_BIT, (hl)
    res     #ENEMY_FLAG_ARROW_BIT, (hl)
    res     #ENEMY_FLAG_WAVE_BIT, (hl)

    ; 位置の設定
    ld      a, #14
    ld      (_enemy + ENEMY_POSITION_Y), a

    ; アニメーションの設定
    ld      a, #ENEMY_ANIMATION_BOMB
    ld      (_enemy + ENEMY_ANIMATION), a

    ; パターンの設定
    ld      hl, #enemyPatternBomb
    ld      (_enemy + ENEMY_PATTERN_L), hl

    ; 台詞の設定
00$:
    call    _SystemGetRandom
    and     #0x0f
    cp      #0x0b
    jr      nc, 00$
    add     a, a
    ld      e, a
    ld      d, #0x00
    ld      hl, #enemySpeechBomb
    add     hl, de
    ld      e, (hl)
    inc     hl
    ld      d, (hl)
    ex      de, hl
    call    _EnemySetSpeech

    ; カラーテーブルの設定
    ld      a, #VDP_COLOR_MEDIUM_RED
    call    EnemySetColor
    
    ; スコアの加算
    ld      hl, #0x0000
    ld      de, #GAME_SCORE_WIN
    ld      a, (_enemy + ENEMY_TYPE)
    ld      b, a
01$:
    add     hl, de
    djnz    01$
    call    _GameAddScore

    ; 初期化の完了
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
09$:

    ; アニメーションの更新
    ld      hl, #(_enemy + ENEMY_ANIMATION)
    dec     (hl)
    jr      nz, 19$

    ; 処理の更新
    ld      hl, #EnemyLoad
    ld      (_enemy + ENEMY_PROC_L), hl
    xor     a
    ld      (_enemy + ENEMY_STATE), a
19$:

    ; レジスタの復帰

    ; 終了
    ret

; エネミーが正拳突きをする
;
EnemySeikenduki:

    ; レジスタの保存

    ; 初期化
    ld      a, (_enemy + ENEMY_STATE)
    or      a
    jr      nz, 09$

    ; 攻撃方法の設定
    xor     a
    ld      (_enemy + ENEMY_ATTACK), a

    ; アニメーションの設定
    ld      a, #ENEMY_ANIMATION_ATTACK
    ld      (_enemy + ENEMY_ANIMATION), a

    ; パターンの設定
    ld      a, (_enemy + ENEMY_TYPE)
    add     a, a
    ld      e, a
    ld      d, #0x00
    ld      hl, #enemyPatternSeikenduki
    add     hl, de
    ld      e, (hl)
    inc     hl
    ld      d, (hl)
    ld      (_enemy + ENEMY_PATTERN_L), de

    ; ヒット判定
    ld      hl, #0x0000
    ld      de, #20
    ld      a, (_enemy + ENEMY_TYPE)
    ld      b, a
00$:
    add     hl, de
    djnz    00$
    ld      de, #0x0302
    call    EnemyAttack
    ex      de, hl
    call    c, _PlayerTakeDamage

    ; 初期化の完了
    ld      hl, #(_enemy + ENEMY_STATE)
    inc     (hl)
09$:

    ; アニメーションの更新
    ld      hl, #(_enemy + ENEMY_ANIMATION)
    dec     (hl)
    jr      nz, 19$

    ; 処理の更新
    call    EnemySetAction
19$:

    ; レジスタの復帰

    ; 終了
    ret

; エネミーが歩く
;
EnemyWalk:

    ; レジスタの保存
    push    de

    ; cf > 1 = 攻撃命令

    ; アニメーションの更新
    ld      hl, #(_enemy + ENEMY_ANIMATION)
    ld      a, (hl)
    or      a
    jr      z, 100$
    dec     (hl)
    jr      90$

    ; 移動
100$:
    ld      a, (_enemy + ENEMY_POSITION_X)
    call    _PlayerGetDistance
    or      a
    jp      p, 110$
    neg
    ld      d, a
    cp      #0x04
    jr      nc, 101$
    call    _SystemGetRandom
    and     #0x11
    jr      z, 180$
101$:
    ld      a, (_enemy + ENEMY_TYPE)
    sub     #0x10
    neg
    ld      e, a
102$:
    call    _SystemGetRandom
    and     #0x0f
    cp      e
    jr      nc, 102$
    or      a
    jr      z, 180$
110$:
    ld      a, (_enemy + ENEMY_POSITION_X)
    ld      de, #0x0701
    cp      #0x06
    jr      c, 120$
    ld      de, #0x0703
    cp      #0x0c
    jr      c, 120$
    ld      de, #0x0307
    cp      #0x18
    jr      c, 120$
    ld      de, #0x0107
;   jr      120$
120$:
    call    _SystemGetRandom
    and     d
    ld      d, a
    call    _SystemGetRandom
    and     e
    ld      e, a
    ld      a, d
    cp      e
    jr      c, 121$
    ld      de, #0x0001
    jr      122$
121$:
    ld      de, #0x00ff
;   jr      122$
122$:
    call    _EnemyMove
    ld      a, (_enemy + ENEMY_TYPE)
    sub     #ENEMY_ANIMATION_WALK
    neg
    ld      (_enemy + ENEMY_ANIMATION), a
    or      a
    jr      190$
180$:
    scf
;   jr      190$
190$:

    ; 歩行の完了
90$:

    ; レジスタの復帰
    pop     de

    ; 終了
    ret

; エネミーの行動を設定する
;
EnemySetAction:

    ; レジスタの保存

    ; 処理の設定
    ld      a, (_enemy + ENEMY_TYPE)
    add     a, a
    ld      e, a
    ld      d, #0x00
    ld      hl, #enemyProc
    add     hl, de
    ld      e, (hl)
    inc     hl
    ld      d, (hl)
    ld      (_enemy + ENEMY_PROC_L), de
    xor     a
    ld      (_enemy + ENEMY_STATE), a

    ; レジスタの復帰

    ; 終了
    ret

; エネミーを移動させる
;
_EnemyMove::

    ; レジスタの保存
    push    hl

    ; de < Y/X 移動量

    ; 位置の更新
    ld      hl, (_enemy + ENEMY_POSITION_X)
    ld      a, e
    or      a
    jp      p, 10$
    add     a, l
    jp      p, 11$
    xor     a
    jr      11$
10$:
    add     a, l
    cp      #0x1f
    jr      c, 11$
    ld      a, #(0x1f - 0x01)
;   jr      11$
11$:
    ld      l, a
    ld      a, d
    add     a, h
    ld      h, a
    ld      (_enemy + ENEMY_POSITION_X), hl

    ; レジスタの復帰
    pop     hl

    ; 終了
    ret

; エネミーの種類を取得する
;
_EnemyGetType::

    ; レジスタの保存

    ; a > 種類

    ; 種類の取得
    ld      a, (_enemy + ENEMY_TYPE)

    ; レジスタの復帰

    ; 終了
    ret

; エネミーの名前の文字列を取得する
;
_EnemyGetNameString::

    ; レジスタの保存

    ; hl > 文字列

    ; 名前の取得
    ld      a, (_enemy + ENEMY_TYPE)
    or      a
    jr      nz, 10$
    ld      hl, #(enemyNameString + 0x0000)
    jr      19$
10$:
    ld      hl, #(enemyNameString + 0x0008)
;   jr      19$
19$:

    ; レジスタの復帰

    ; 終了
    ret

; エネミーの体力を取得する
;
_EnemyGetLife::

    ; レジスタの保存

    ; hl > 体力

    ; 体力の取得
    ld      hl, (_enemy + ENEMY_LIFE_L)

    ; レジスタの復帰

    ; 終了
    ret

; エネミーの攻撃方法を取得する
;
_EnemyGetAttack::

    ; レジスタの保存

    ; a > 攻撃方法

    ; 攻撃方法の取得
    ld      a, (_enemy + ENEMY_ATTACK)

    ; レジスタの復帰

    ; 終了
    ret

; エネミーの色を設定する
;
EnemySetColor:

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
    ld      hl, #(_appColorTable + 0x0010 + 0x0000)
    ld      de, #(_appColorTable + 0x0010 + 0x0001)
    ld      bc, #(0x0007 - 0x0001)
    ld      (hl), a
    ldir

    ; レジスタの復帰
    pop     de
    pop     bc
    pop     hl

    ; 終了
    ret

; エネミーのパターンを設定する
;
_EnemySetPattern::

    ; レジスタの保存
    push    hl
    push    de

    ; a < パターン番号

    ; パターンの設定
    push    af
    or      a
    jr      nz, 10$
    ld      a, (_enemy + ENEMY_TYPE)
    add     a, a
    ld      e, a
    ld      d, #0x00
    ld      hl, #enemyPatternStand
    jr      11$
10$:
    add     a, a
    ld      e, a
    ld      d, #0x00
    ld      hl, #enemyPattern
11$:
    add     hl, de
    ld      e, (hl)
    inc     hl
    ld      d, (hl)
    ld      (_enemy + ENEMY_PATTERN_L), de
    pop     af

    ; 色の設定
    ld      e, a
    ld      d, #0x00
    ld      hl, #enemyPatternColor
    add     hl, de
    ld      a, (hl)
    call    EnemySetColor

    ; レジスタの復帰
    pop     de
    pop     hl

    ; 終了
    ret

; エネミーのパターンを選択する
;
EnemySelectPattern:

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
    ld      (_enemy + ENEMY_PATTERN_L), de

    ; レジスタの復帰
    pop     de
    pop     hl

    ; 終了
    ret

; エネミーの台詞の消去する
;
_EnemyClearSpeech::

    ; レジスタの保存
    push    hl

    ; 台詞の消去
    ld      hl, #0x0000
    ld      (_enemy + ENEMY_SPEECH_L), hl

    ; レジスタの復帰
    pop     hl

    ; 終了
    ret

; エネミーの台詞を設定する
;
_EnemySetSpeech::

    ; レジスタの保存
    push    de

    ; hl < 文字列

    ; 台詞の設定
    ld      a, h
    or      l
    jr      z, 10$
    ld      a, (_enemy + ENEMY_POSITION_X)
    ld      e, a
    ld      d, #12
    call    _GameGetSpeechPosition
    ld      (_enemy + ENEMY_SPEECH_L), hl
    ld      (_enemy + ENEMY_SPEECH_X), de
    jr      19$
10$:
    ld      (_enemy + ENEMY_SPEECH_L), hl
;   jr      19$
19$:

    ; レジスタの復帰
    pop     de

    ; 終了
    ret

EnemySetSpeechOwner:

    ; レジスタの保存

    ; hl < 文字列
    ; a  < アニメーション

    ; アニメーションの設定
    ld      (_enemy + ENEMY_ANIMATION), a

    ; 台詞の設定
    call    _EnemySetSpeech

    ; レジスタの復帰

    ; 終了
    ret

EnemySetSpeechOther:

    ; レジスタの保存

    ; hl < 文字列
    ; a  < アニメーション

    ; アニメーションの設定
    ld      (_enemy + ENEMY_ANIMATION), a

    ; 台詞の設定
    call    _PlayerSetSpeech

    ; レジスタの復帰

    ; 終了
    ret

; エネミーが台詞を言う
;
EnemySpeechOwner:

    ; レジスタの保存

    ; cf > 1 = 台詞中
    push    hl

    ; アニメーションの更新
    ld      hl, #(_enemy + ENEMY_ANIMATION)
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

EnemySpeechOther:

    ; レジスタの保存

    ; cf > 1 = 台詞中
    push    hl

    ; アニメーションの更新
    ld      hl, #(_enemy + ENEMY_ANIMATION)
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

; エネミーの会話を設定する
;
EnemySetTalk:

    ; レジスタの保存
    push    hl
    push    de

    ; hl < 会話

    ; 会話の設定
    ld      a, (hl)
    inc     hl
    cp      #ENEMY_TALK_SILENT
    jr      nz, 10$
    ld      (_enemy + ENEMY_TALK_L), hl
    ld      a, #ENEMY_ANIMATION_SILENT
    ld      (_enemy + ENEMY_ANIMATION), a
    jr      19$
10$:
    ld      e, (hl)
    inc     hl
    ld      d, (hl)
    inc     hl
    ld      (_enemy + ENEMY_TALK_L), hl
    ex      de, hl
    cp      #ENEMY_TALK_OWNER
    ld      a, #ENEMY_ANIMATION_SPEECH
    jr      nz, 11$
    call    EnemySetSpeechOwner
    jr      19$
11$:
    call    EnemySetSpeechOther
;   jr      19$
19$:

    ; レジスタの復帰
    pop     de
    pop     hl

    ; 終了
    ret

; エネミーの会話を選択する
;
EnemySelectTalk:

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
    call    EnemySetTalk

    ; レジスタの復帰
    pop     de
    pop     hl

    ; 終了
    ret

; エネミーが会話する
;
EnemyTalk:

    ; レジスタの保存
    push    hl
    push    de

    ; cf > 1 = 会話中

    ; アニメーションの更新
    ld      hl, #(_enemy + ENEMY_ANIMATION)
    dec     (hl)
    jr      nz, 18$

    ; 台詞の消去
    call    _PlayerClearSpeech
    call    _EnemyClearSpeech

    ; 会話の更新
    ld      hl, (_enemy + ENEMY_TALK_L)
    ld      a, (hl)
    or      a
    jr      z, 19$
    inc     hl
    cp      #ENEMY_TALK_SILENT
    jr      nz, 10$
    ld      (_enemy + ENEMY_TALK_L), hl
    ld      a, #ENEMY_ANIMATION_SILENT
    ld      (_enemy + ENEMY_ANIMATION), a
    jr      18$
10$:
    ld      e, (hl)
    inc     hl
    ld      d, (hl)
    inc     hl
    ld      (_enemy + ENEMY_TALK_L), hl
    ex      de, hl
    cp      #ENEMY_TALK_OWNER
    ld      a, #ENEMY_ANIMATION_SPEECH
    jr      nz, 11$
    call    EnemySetSpeechOwner
    jr      18$
11$:
    call    EnemySetSpeechOther
;   jr      18$
18$:
    scf
19$:

    ; レジスタの復帰
    pop     de
    pop     hl

    ; 終了
    ret

; エネミーをロックする
;
_EnemyLock::

    ; レジスタの保存

    ; 処理の設定
    ld      hl, #EnemyIdle
    ld      (_enemy + ENEMY_PROC_L), hl
    xor     a
    ld      (_enemy + ENEMY_STATE), a

    ; レジスタの復帰

    ; 終了
    ret

; エネミーをアンロックする
;
_EnemyUnlock::

    ; レジスタの保存

    ; 処理の設定
    call    EnemySetAction

    ; レジスタの復帰

    ; 終了
    ret

; エネミーのヒット判定を行う
;
_EnemyHit::

    ; レジスタの保存
    push    hl
    push    de

    ; de < 攻撃範囲
    ; cf > 1 = ヒット

    ; エネミーがアクティブかどうか
    ld      a, (_enemy + ENEMY_TYPE)
    or      a
    jr      z, 80$
    ld      hl, (_enemy + ENEMY_LIFE_L)
    ld      a, h
    or      l
    jr      z, 80$
    ld      a, (_enemy + ENEMY_FLAG)
    bit     #ENEMY_FLAG_ACTIVE_BIT, a
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
    ld      a, (_enemy + ENEMY_POSITION_X)
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

; エネミーの攻撃判定を行う
;
EnemyAttack:

    ; レジスタの保存
    push    hl
    push    de

    ; de < L/R 攻撃範囲
    ; cf > 1 = ヒット

    ; 攻撃判定
    ld      a, (_enemy + ENEMY_POSITION_X)
    add     a, e
    ld      e, a
    ld      a, (_enemy + ENEMY_POSITION_X)
    add     a, d
    ld      d, a
    call    _PlayerHit
    ld      hl, #(_enemy + ENEMY_FLAG)
    jr      nc, 10$
    set     #ENEMY_FLAG_HIT_BIT, (hl)
    scf
    jr      19$
10$:
    res     #ENEMY_FLAG_HIT_BIT, (hl)
    or      a
;   jr      19$
19$:

    ; レジスタの復帰
    pop     de
    pop     hl

    ; 終了
    ret

EnemyAttackArrow:

    ; レジスタの保存
    push    hl
    push    de

    ; de < L/R 攻撃範囲
    ; cf > 1 = ヒット

    ; 攻撃判定
    ld      a, (_enemy + ENEMY_ARROW_X)
    add     a, e
    ld      e, a
    ld      a, (_enemy + ENEMY_ARROW_X)
    add     a, d
    ld      d, a
    call    _PlayerHit
    ld      hl, #(_enemy + ENEMY_FLAG)
    jr      nc, 10$
    set     #ENEMY_FLAG_HIT_BIT, (hl)
    scf
    jr      19$
10$:
    res     #ENEMY_FLAG_HIT_BIT, (hl)
    or      a
;   jr      19$
19$:

    ; レジスタの復帰
    pop     de
    pop     hl

    ; 終了
    ret

; エネミーがダメージを受ける
;
_EnemyTakeDamage::

    ; レジスタの保存
    push    hl

    ; de < ダメージ量

    ; 体力の減少
    ld      hl, (_enemy + ENEMY_LIFE_L)
    or      a
    sbc     hl, de
    jr      nc, 10$
    ld      hl, #0x0000
10$:
    ld      (_enemy + ENEMY_LIFE_L), hl

    ; 処理の設定
    ld      hl, #EnemyDamage
    ld      (_enemy + ENEMY_PROC_L), hl
    xor     a
    ld      (_enemy + ENEMY_STATE), a

    ; レジスタの復帰
    pop     hl

    ; 終了
    ret

; 必殺技を受ける
;
_EnemyTakeSpecial::

    ; レジスタの保存
    push    hl

    ; 処理の設定
    ld      hl, #EnemyBomb
    ld      (_enemy + ENEMY_PROC_L), hl
    xor     a
    ld      (_enemy + ENEMY_STATE), a

    ; レジスタの復帰
    pop     hl

    ; 終了
    ret

; 定数の定義
;

; 種類別の処理
;
enemyProc:
    
    .dw     EnemyLoad
    .dw     EnemyShitappa
    .dw     EnemySpade
    .dw     EnemyDia
    .dw     EnemyClub
    .dw     EnemyHeart
    .dw     EnemyRei
    .dw     EnemyJagi
    .dw     EnemyJuda
    .dw     EnemyShew
    .dw     EnemyRaoh

; 名前
;
enemyNameString:

    .db     ____, ____, ____, ____, ____, ____, ____, 0x00
    .db     _E38, _E39, _E3A, _E3B, _E3C, _E3D, _E3E, 0x00

; パターン
;

; 立ち
enemyPatternStand:

    .dw     enemyPatternNull
    .dw     enemyPatternShitappaStand
    .dw     enemyPatternSpadeStand
    .dw     enemyPatternDiaStand
    .dw     enemyPatternClubStand
    .dw     enemyPatternHeartStand
    .dw     enemyPatternReiStand
    .dw     enemyPatternJagiStand
    .dw     enemyPatternJudaStand
    .dw     enemyPatternShewStand
    .dw     enemyPatternRaohStand

; 正拳突き
enemyPatternSeikenduki:

    .dw     enemyPatternNull
    .dw     enemyPatternShitappaSeikenduki
    .dw     enemyPatternSpadeSeikenduki
    .dw     enemyPatternDiaSeikenduki
    .dw     enemyPatternClubSeikenduki
    .dw     enemyPatternHeartSeikenduki
    .dw     enemyPatternReiSeikenduki
    .dw     enemyPatternJagiSeikenduki
    .dw     enemyPatternJudaSeikenduki
    .dw     enemyPatternShewSeikenduki
    .dw     enemyPatternRaohSeikenduki

; なし
enemyPatternNull:

    .db     0, 0, 1, 1
    .db     ____

; シタッパ
enemyPatternShitappaStand:

    .db     -1, 0, 3, 4
    .db     ____, _E30, ____
    .db     ____, _E01, _E17
    .db     ____, _E01, ____
    .db     _E0A, ____, _E0B

enemyPatternShitappaSeikenduki:

    .db     -1, 0, 5, 4
    .db     ____, _E30, ____, ____, ____
    .db     ____, _E01, _E1C, _E1C, _E11
    .db     ____, _E01, ____, ____, ____
    .db     _E0A, ____, _E0B, ____, ____

; スペード
enemyPatternSpadeStand:

    .db     -1, 0, 4, 4
    .db     ____, _E30, _E27, _E31
    .db     ____, _E01, _E13, ____
    .db     ____, _E01, _E15, ____
    .db     _E0A, _E09, ____, ____

enemyPatternSpadeSeikenduki:

    .db     -1, 0, 5, 4
    .db     ____, _E30, ____, ____, ____
    .db     ____, _E01, _E1C, _E1C, _E11
    .db     ____, _E01, ____, ____, ____
    .db     _E0A, _E09, ____, ____, ____

enemyPatternSpadeSpecial:

    .db     -1, 0, 3, 4
    .db     ____, _E30, _E27
    .db     ____, _E01, _E13
    .db     ____, _E01, _E15
    .db     _E0A, _E09, ____

; ダイヤ
enemyPatternDiaStand:

    .db     -1, 0, 3, 4
    .db     ____, _E30, ____
    .db     ____, _E01, ____
    .db     ____, _E01, ____
    .db     _E0A, ____, _E0B

enemyPatternDiaSeikenduki:

    .db     -1, 0, 5, 4
    .db     ____, _E30, ____, ____, ____
    .db     ____, _E01, _E1C, _E1C, _E11
    .db     ____, _E01, ____, ____, ____
    .db     _E0A, ____, _E0B, ____, ____

enemyPatternDiaSpecial_0:

    .db     -1, 0, 3, 4
    .db     ____, _E30, ____
    .db     ____, _E01, _E1C
    .db     ____, _E01, _E13
    .db     _E0A, ____, _E0B

enemyPatternDiaSpecial_1:

    .db     -1, 0, 10, 4
    .db     ____, _E30, ____, ____, ____, ____, ____, ____, ____, ____
    .db     ____, _E01, _E1C, _E1C, _E1C, _E1C, _E1C, _E1C, _E1C, _E1C
    .db     ____, _E01, _E13, ____, ____, ____, ____, ____, ____, ____
    .db     _E0A, ____, _E0B, ____, ____, ____, ____, ____, ____, ____

; クラブ
enemyPatternClubStand:

    .db     0, 0, 3, 4
    .db     _E30, _E0A, _E0B
    .db     _E01, ____, ____
    .db     _E01, ____, ____
    .db     _E08, _E0B, ____

enemyPatternClubSeikenduki:

    .db     0, 0, 4, 4
    .db     _E30, ____, ____, ____
    .db     _E01, _E1C, _E1C, _E11
    .db     _E01, ____, ____, ____
    .db     _E08, _E0B, ____, ____

enemyPatternClubSpecial_0:

    .db     0, 0, 3, 4
    .db     _E30, ____, ____
    .db     _E01, _E0A, _E0B
    .db     _E01, ____, ____
    .db     _E08, _E0B, ____

enemyPatternClubSpecial_1:

    .db     0, 0, 3, 4
    .db     _E30, ____, ____
    .db     _E01, ____, ____
    .db     _E01, _E0A, _E0B
    .db     _E08, _E0B, ____

; ハート
enemyPatternHeartStand:

    .db     -1, 0, 4, 4
    .db     ____, _E30, ____, ____
    .db     _E04, _E01, _E05, _E13
    .db     _E01, _E01, _E01, ____
    .db     _E0A, _E01, _E0B, ____

enemyPatternHeartSeikenduki:

    .db     -1, 0, 5, 4
    .db     ____, _E30, ____, ____, ____
    .db     _E04, _E01, _E1C, _E1C, _E11
    .db     _E01, _E01, _E01, ____, ____
    .db     _E0A, _E01, _E0B, ____, ____

enemyPatternHeartSpecial_0:

    .db     -1, -1, 5, 5
    .db     ____, ____, ____, ____, _E28
    .db     ____, _E30, ____, _E0A, ____
    .db     _E04, _E01, _E05, _E13, ____
    .db     _E01, _E01, _E01, ____, ____
    .db     _E0A, _E01, _E0B, ____, ____

enemyPatternHeartSpecial_1:

    .db     -1, 0, 6, 4
    .db     ____, _E30, ____, ____, ____, ____
    .db     _E04, _E01, _E05, _E1C, _E1C, _E33
    .db     _E01, _E01, _E01, ____, ____, ____
    .db     _E0A, _E01, _E0B, ____, ____, ____

; レイ
enemyPatternReiStand:

    .db     -1, 0, 3, 4
    .db     ____, _E30, ____
    .db     ____, _E31, _E32
    .db     ____, _E31, ____
    .db     _E0A, ____, _E0B

enemyPatternReiSeikenduki:

    .db     -1, 0, 5, 4
    .db     ____, _E30, ____, ____, ____
    .db     ____, _E31, _E1C, _E1C, _E11
    .db     ____, _E31, ____, ____, ____
    .db     _E0A, ____, _E0B, ____, ____

enemyPatternReiSpecial:

    .dw     enemyPatternReiSpecial_0
    .dw     enemyPatternReiSpecial_1
    .dw     enemyPatternReiSpecial_2
    .dw     enemyPatternReiSpecial_3

enemyPatternReiSpecial_0:

    .db     -1, 0, 5, 4
    .db     ____, _E30, _E14, _E14, _E14
    .db     ____, _E31, ____, ____, ____
    .db     ____, _E31, ____, ____, ____
    .db     _E0A, ____, _E0B, ____, ____

enemyPatternReiSpecial_1:

    .db     -1, 0, 5, 4
    .db     ____, _E30, _E10, _E10, _E10
    .db     ____, _E31, ____, ____, ____
    .db     ____, _E31, ____, ____, ____
    .db     _E0A, ____, _E0B, ____, ____

enemyPatternReiSpecial_2:

    .db     -1, 0, 5, 4
    .db     ____, _E30, ____, ____, ____
    .db     ____, _E31, _E17, _E17, _E17
    .db     ____, _E31, ____, ____, ____
    .db     _E0A, ____, _E0B, ____, ____

enemyPatternReiSpecial_3:

    .db     -1, 0, 5, 4
    .db     ____, _E30, ____, ____, ____
    .db     ____, _E31, _E13, _E13, _E13
    .db     ____, _E31, ____, ____, ____
    .db     _E0A, ____, _E0B, ____, ____

; ジャギ
enemyPatternJagiStand:

    .db     -1, 0, 3, 4
    .db     ____, _E30, ____
    .db     ____, _E01, _E32
    .db     ____, _E31, ____
    .db     _E0A, _E09, ____

enemyPatternJagiSeikenduki:

    .db     -1, 0, 5, 4
    .db     ____, _E30, ____, ____, ____
    .db     ____, _E01, _E1C, _E1C, _E11
    .db     ____, _E31, ____, ____, ____
    .db     _E0A, _E09, ____, ____, ____

enemyPatternJagiSpecial_0:

    .dw     enemyPatternJagiSpecial_0_0
    .dw     enemyPatternJagiSpecial_0_1
    .dw     enemyPatternJagiSpecial_0_2
    .dw     enemyPatternJagiSpecial_0_1

enemyPatternJagiSpecial_0_0:

    .db     -1, 0, 4, 4
    .db     ____, _E30, _E0A, _E0B
    .db     ____, _E01, ____, ____
    .db     ____, _E31, ____, ____
    .db     _E0A, _E09, ____, ____

enemyPatternJagiSpecial_0_1:

    .db     -1, 0, 4, 4
    .db     ____, _E30, ____, ____
    .db     ____, _E01, _E1C, _E1C
    .db     ____, _E31, ____, ____
    .db     _E0A, _E09, ____, ____

enemyPatternJagiSpecial_0_2:

    .db     -1, 0, 4, 4
    .db     ____, _E30, ____, ____
    .db     ____, _E01, ____, ____
    .db     ____, _E31, _E0B, _E0A
    .db     _E0A, _E09, ____, ____

enemyPatternJagiSpecial_1:

    .db     -1, 0, 5, 4
    .db     ____, _E30, ____, ____, ____
    .db     ____, _E01, _E1A, _E19, _E18
    .db     ____, _E31, ____, ____, ____
    .db     _E0A, _E09, ____, ____, ____

; ユダ
enemyPatternJudaStand:

    .db     0, 0, 2, 4
    .db     _E30, ____
    .db     _E31, _E17
    .db     _E31, ____
    .db     _E08, _E32

enemyPatternJudaSeikenduki:

    .db     0, 0, 4, 4
    .db     _E30, ____, ____, ____
    .db     _E31, _E1C, _E1C, _E11
    .db     _E31, ____, ____, ____
    .db     _E08, _E32, ____, ____

enemyPatternJudaSpecial_0:

    .dw     enemyPatternJudaSpecial_0_0
    .dw     enemyPatternJudaSpecial_0_1
    .dw     enemyPatternJudaSpecial_0_2
    .dw     enemyPatternJudaSpecial_0_3

enemyPatternJudaSpecial_0_0:

    .db     0, 0, 3, 4
    .db     _E30, ____, ____
    .db     _E31, _E14, _E14
    .db     _E31, ____, ____
    .db     _E08, _E32, ____

enemyPatternJudaSpecial_0_1:

    .db     0, 0, 3, 4
    .db     _E30, ____, ____
    .db     _E31, _E17, _E17
    .db     _E31, ____, ____
    .db     _E08, _E32, ____

enemyPatternJudaSpecial_0_2:

    .db     0, 0, 3, 4
    .db     _E30, ____, ____
    .db     _E31, _E15, _E15
    .db     _E31, ____, ____
    .db     _E08, _E32, ____

enemyPatternJudaSpecial_0_3:

    .db     0, 0, 3, 4
    .db     _E30, ____, ____
    .db     _E31, _E16, _E16
    .db     _E31, ____, ____
    .db     _E08, _E32, ____

; シュウ
enemyPatternShewStand:

    .db     0, 0, 2, 4
    .db     _E30, ____
    .db     _E31, _E13
    .db     _E31, ____
    .db     _E08, _E0B

enemyPatternShewSeikenduki:

    .db     0, 0, 4, 4
    .db     _E30, ____, ____, ____
    .db     _E31, _E1C, _E1C, _E11
    .db     _E31, ____, ____, ____
    .db     _E08, _E0B, ____, ____

enemyPatternShewSpecial_0_0:

    .db     -1, -1, 3, 5
    .db     ____, _E30, ____
    .db     ____, _E31, _E11
    .db     ____, _E31, ____
    .db     _E0A, _E0A, ____
    .db     _E0A, ____, ____

enemyPatternShewSpecial_0_1:

    .db     -1, -2, 5, 4
    .db     ____, _E30, ____, ____, ____
    .db     _E12, _E31, ____, ____, ____
    .db     ____, _E31, _E1C, _E1C, _E13
    .db     ____, _E32, ____, ____, ____

enemyPatternShewSpecial_0_2:

    .db     -3, -2, 5, 4
    .db     ____, ____, ____, _E30, ____
    .db     ____, ____, ____, _E31, _E11
    .db     _E12, _E1C, _E1C, _E31, ____
    .db     ____, ____, ____, _E33, ____

enemyPatternShewSpecial_1_0:

    .dw     enemyPatternShewSpecial_1_0_0
    .dw     enemyPatternShewSpecial_1_0_1
    .dw     enemyPatternShewSpecial_1_0_2
    .dw     enemyPatternShewSpecial_1_0_1
    .dw     enemyPatternShewSpecial_1_0_3

enemyPatternShewSpecial_1_0_0:

    .db     -3, 0, 7, 4
    .db     ____, ____, ____, _E30, ____, ____, ____
    .db     _E13, _E13, _E13, _E31, _E13, _E13, _E13
    .db     ____, ____, ____, _E31, ____, ____, ____
    .db     ____, ____, ____, _E08, _E0B, ____, ____

enemyPatternShewSpecial_1_0_1:

    .db     -3, 0, 7, 4
    .db     ____, _E13, ____, _E30, ____, _E13, ____
    .db     _E13, _E13, _E13, _E31, _E13, _E13, _E13
    .db     ____, ____, ____, _E31, ____, ____, ____
    .db     ____, ____, ____, _E08, _E0B, ____, ____

enemyPatternShewSpecial_1_0_2:

    .db     -3, -1, 7, 5
    .db     ____, _E13, _E13, ____, _E13, _E13, ____
    .db     ____, _E13, ____, _E30, ____, _E13, ____
    .db     _E13, _E13, _E13, _E31, _E13, _E13, _E13
    .db     ____, ____, ____, _E31, ____, ____, ____
    .db     ____, ____, ____, _E08, _E0B, ____, ____

enemyPatternShewSpecial_1_0_3:

    .db     0, 0, 2, 4
    .db     _E30, ____
    .db     _E31, ____
    .db     _E31, ____
    .db     _E08, _E0B


enemyPatternShewSpecial_1_1:

    .dw     enemyPatternShewSpecial_1_1_0
    .dw     enemyPatternShewSpecial_1_1_1

enemyPatternShewSpecial_1_1_0:

    .db     0, 0, 4, 4
    .db     _E30, ____, ____, ____
    .db     _E31, _E34, _E34, _E35
    .db     _E31, ____, ____, ____
    .db     _E08, _E0B, ____, ____

enemyPatternShewSpecial_1_1_1:

    .db     0, 0, 4, 4
    .db     _E30, ____, ____, ____
    .db     _E31, ____, ____, _E35
    .db     _E31, ____, ____, ____
    .db     _E08, _E0B, ____, ____

enemyPatternShewSpecial_2:

    .dw     enemyPatternShewSpecial_2_0
    .dw     enemyPatternShewSpecial_2_1

enemyPatternShewSpecial_2_0:

    .db     -2, 0, 6, 4
    .db     ____, _E0A, ____, ____, ____, ____
    .db     _E30, _E31, _E31, _E18, _E18, _E18
    .db     ____, ____, _E08, ____, ____, ____
    .db     ____, ____, _E08, ____, ____, ____

enemyPatternShewSpecial_2_1:

    .db    -2, 0, 5, 4
    .db     ____, ____, ____, _E0B, ____
    .db     _E0A, _E18, _E31, _E31, _E30
    .db     ____, ____, _E08, ____, ____
    .db     ____, ____, _E08, ____, ____

enemyPatternShewSpecial_3:

    .dw     enemyPatternShewSpecial_3_0
    .dw     enemyPatternShewSpecial_3_1
    .dw     enemyPatternShewSpecial_3_2
    .dw     enemyPatternShewSpecial_3_3
    .dw     enemyPatternShewSpecial_3_3
    .dw     enemyPatternShewSpecial_3_2
    .dw     enemyPatternShewSpecial_3_1
    .dw     enemyPatternShewSpecial_3_0

enemyPatternShewSpecial_3_0:

    .db     -1, -1, 3, 5
    .db     ____, _E08, _E08
    .db     ____, _E08, _E08
    .db     ____, _E31, ____
    .db     ____, _E31, _E30
    .db     _E0A, _E09, ____

enemyPatternShewSpecial_3_1:

    .db     -1, -1, 4, 5
    .db     ____, _E08, ____, _E0A
    .db     ____, _E08, _E0A, ____
    .db     ____, _E31, ____, ____
    .db     ____, _E31, _E30, ____
    .db     _E0A, _E09, ____, ____

enemyPatternShewSpecial_3_2:

    .db     -1, -1, 4, 5
    .db     ____, _E08, ____, ____
    .db     ____, _E08, _E1F, _E1F
    .db     ____, _E31, ____, ____
    .db     ____, _E31, _E30, ____
    .db     _E0A, _E09, ____, ____

enemyPatternShewSpecial_3_3:

    .db     -1, -1, 4, 5
    .db     ____, _E08, ____, ____
    .db     ____, _E08, ____, ____
    .db     ____, _E31, _E0B, ____
    .db     ____, _E31, _E30, _E0B
    .db     _E0A, _E09, ____, ____

; ラオウ
enemyPatternRaohStand:

    .db     -1, 0, 3, 4
    .db     ____, _E30, ____
    .db     _E31, _E01, _E13
    .db     ____, _E01, ____
    .db     _E31, ____, _E0B

enemyPatternRaohSeikenduki:

    .db     -1, 0, 5, 4
    .db     ____, _E30, ____, ____, ____
    .db     _E31, _E01, _E1C, _E1C, _E11
    .db     ____, _E01, ____, ____, ____
    .db     _E31, ____, _E0B, ____, ____

enemyPatternRaohSpecial_0_0:

    .db     -1, 0, 5, 4
    .db     ____, _E30, ____, ____, ____
    .db     _E31, _E01, _E1C, _E1C, _E11
    .db     ____, _E01, ____, ____, ____
    .db     _E31, ____, _E0B, ____, ____

enemyPatternRaohSpecial_0_1:

    .db     -1, 0, 5, 4
    .db     ____, _E30, ____, ____, ____
    .db     _E31, _E01, _E1C, _E1C, _E13
    .db     ____, _E01, ____, ____, ____
    .db     _E31, ____, _E0B, ____, ____

enemyPatternRaohSpecial_1_0:

    .db     -1, 0, 2, 4
    .db     ____, _E30
    .db     _E12, _E01
    .db     ____, _E01
    .db     _E18, _E09

enemyPatternRaohSpecial_1_1:

    .db     -1, 0, 4, 4
    .db     ____, _E30, ____, ____
    .db     _E0A, _E01, _E13, _E0A
    .db     ____, _E01, _E0A, ____
    .db     ____, _E08, ____, ____

enemyPatternRaohSpecial_2:

    .db     -1, 0, 4, 4
    .db     ____, _E30, _E10, _E1C
    .db     _E31, _E01, _E13, ____
    .db     ____, _E01, ____, ____
    .db     _E31, ____, _E0B, ____

; 矢
enemyPatternArrow:

    .db     -2, 0, 3, 1
    .db     _E32, _E1C, _E31

; 衝撃波
enemyPatternWave:

    .dw     enemyPatternNull
    .dw     enemyPatternWave_1
    .dw     enemyPatternWave_2
    .dw     enemyPatternWave_3
    .dw     enemyPatternWave_4
    .dw     enemyPatternWave_5
    .dw     enemyPatternWave_6
    .dw     enemyPatternWave_7
    .dw     enemyPatternWave_8
    .dw     enemyPatternWave_9
    .dw     enemyPatternWave_10
    .dw     enemyPatternWave_11
    .dw     enemyPatternWave_12

enemyPatternWave_1:

    .db     0, 0, 1, 1
    .db     _E33

enemyPatternWave_2:

    .db     -1, 0, 2, 1
    .db     _E33, _E33

enemyPatternWave_3:

    .db     -2, 0, 3, 1
    .db     _E33, _E33, _E33

enemyPatternWave_4:

    .db     -3, 0, 4, 1
    .db     _E33, _E33, _E33, _E33

enemyPatternWave_5:

    .db     -4, 0, 5, 1
    .db     _E33, _E33, _E33, _E33, _E33

enemyPatternWave_6:

    .db     -5, 0, 6, 1
    .db     _E33, _E33, _E33, _E33, _E33, _E33

enemyPatternWave_7:

    .db     -6, 0, 7, 1
    .db     _E33, _E33, _E33, _E33, _E33, _E33, _E33

enemyPatternWave_8:

    .db     -7, 0, 8, 1
    .db     _E33, _E33, _E33, _E33, _E33, _E33, _E33, _E33

enemyPatternWave_9:

    .db     -8, 0, 9, 1
    .db     _E33, _E33, _E33, _E33, _E33, _E33, _E33, _E33, _E33

enemyPatternWave_10:

    .db     -9, 0, 10, 1
    .db     _E33, _E33, _E33, _E33, _E33, _E33, _E33, _E33, _E33, _E33

enemyPatternWave_11:

    .db     -10, 0, 11, 1
    .db     _E33, _E33, _E33, _E33, _E33, _E33, _E33, _E33, _E33, _E33, _E33

enemyPatternWave_12:

    .db     -11, 0, 12, 1
    .db     _E33, _E33, _E33, _E33, _E33, _E33, _E33, _E33, _E33, _E33, _E33, _E33

; 倒れる
enemyPatternDown:

    .db     -2, 3, 5, 1
    .db     _E28, _E01, _E01, _E0A, _E0B

; 爆発
enemyPatternBomb:

    .db     -2, 0, 4, 4
    .db     _E14, _E21, _E22, _E20
    .db     _E20, _E20, _E15, _E21
    .db     _E20, ____, _E07, _E17
    .db     _E21, _E08, _E23, _E20

; その他
enemyPattern:

    .dw     enemyPatternNull
    .dw     enemyPatternHiko_0
    .dw     enemyPatternHiko_1
    .dw     enemyPatternHiko_2
    .dw     enemyPatternHiko_3
    .dw     enemyPatternHiko_4
    .dw     enemyPatternHyakuretsuken_0
    .dw     enemyPatternHyakuretsuken_1
    .dw     enemyPatternJuhazan_0
    .dw     enemyPatternJuhazan_1

enemyPatternColor:

    .db     VDP_COLOR_MAGENTA
    .db     VDP_COLOR_LIGHT_YELLOW
    .db     VDP_COLOR_LIGHT_YELLOW
    .db     VDP_COLOR_LIGHT_YELLOW
    .db     VDP_COLOR_LIGHT_YELLOW
    .db     VDP_COLOR_LIGHT_YELLOW
    .db     VDP_COLOR_MAGENTA
    .db     VDP_COLOR_MAGENTA
    .db     VDP_COLOR_MAGENTA
    .db     VDP_COLOR_MEDIUM_RED

enemyPatternHiko_0:

    .db     -2, 0, 4, 4
    .db     ____, _E03, _E0C, ____
    .db     _E0F, _E06, _E05, ____
    .db     ____, _E08, _E01, ____
    .db     ____, _E18, ____, _E0B

enemyPatternHiko_1:

    .db     -1, 0, 3, 4
    .db     _E11, ____, ____
    .db     _E04, _E26, _E05
    .db     _E03, _E29, _E01
    .db     ____, _E0A, _E0A

enemyPatternHiko_2:

    .db     -1, 0, 3, 4
    .db     _E0E, _E03, ____
    .db     _E04, _E07, _E1D
    .db     _E06, _E05, ____
    .db     _E0A, _E09, _E1F

enemyPatternHiko_3:

    .db     -1, 0, 3, 4
    .db     _E21, _E03, ____
    .db     _E20, _E06, _E17
    .db     ____, _E04, _E24
    .db     _E0A, _E0A, ____

enemyPatternHiko_4:

    .db     -2, 0, 4, 4
    .db     _E21, _E0B, _E03, ____
    .db     _E20, _E04, _E07, ____
    .db     ____, _E06, _E05, _E0B
    .db     ____, _E0A, ____, _E0B

enemyPatternHyakuretsuken_0:

    .db     -2, -2, 4, 3
    .db     _E1F, _E04, _E05, ____
    .db     _E02, _E07, ____, _E0B
    .db     _E0A, ____, ____, ____

enemyPatternHyakuretsuken_1:

    .db     -2, 3, 5, 1
    .db     _E02, _E01, _E01, _E0A, _E0B

enemyPatternJuhazan_0:

    .db     -1, 0, 3, 4
    .db     ____, _E30, ____
    .db     _E04, _E01, _E26
    .db     _E01, _E01, _E27
    .db     _E0A, _E01, _E0B

enemyPatternJuhazan_1:

    .db     -1, 0, 3, 4
    .db     ____, _E30, ____
    .db     _E04, _E01, _E31
    .db     _E01, _E01, _E32
    .db     _E0A, _E01, _E0B

; 台詞
;

; シタッパ

; スペード

; ダイヤ
enemyTalkDia_0:

    .dw     enemyTalkDia_0_0
    .dw     enemyTalkDia_0_1
    
enemyTalkDia_0_0:

    .db     ENEMY_TALK_OWNER
    .dw     enemySpeechDia_0_0_0
    .db     ENEMY_TALK_OWNER
    .dw     enemySpeechDia_0_0_1
    .db     0x00

enemySpeechDia_0_0_0:

    .db     _KKO, _KNO, ____, _KHO, _KSN, _K_U, ____, _KKA, _KSN, 0x00

enemySpeechDia_0_0_1:

    .db     _KMI, _KKI, _KRE, _KRU, _KKA, _EXC, _EXC, 0x00

enemyTalkDia_0_1:

    .db     ENEMY_TALK_SILENT
    .db     0x00

; クラブ

; ハート

; レイ

enemyTalkRei_0:

    .db     ENEMY_TALK_OWNER
    .dw     enemySpeechRei_0_0
    .db     ENEMY_TALK_OWNER
    .dw     enemySpeechRei_0_1
    .db     0x00

enemySpeechRei_0_0:

    .db     _KNA, _KNN, _KTO, 0x00

enemySpeechRei_0_1:

    .db     _KSU, _K_I, _KTI, _Kyo, _K_U, _KKE, _KNN, 0x00

; ジャギ

enemyTalkJagi_0:

    .db     ENEMY_TALK_OWNER
    .dw     enemySpeechJagi_0_0
    .db     ENEMY_TALK_OWNER
    .dw     enemySpeechJagi_0_1
    .db     0x00

enemySpeechJagi_0_0:

    .db     _KHO, _KKU, _KTO, 0x00

enemySpeechJagi_0_1:

    .db     _KRA, _KKA, _KNN, _KKE, _KSN, _KKI, 0x00

enemySpeechJagi_1:

    .db     _KHA, _Ktu, _Ktu, _EXC, 0x00

; ユダ
enemyTalkJuda_0:

    .db     ENEMY_TALK_OWNER
    .dw     enemySpeechJuda_0_0
    .db     ENEMY_TALK_OWNER
    .dw     enemySpeechJuda_0_1
    .db     0x00

enemySpeechJuda_0_0:

    .db     _KNA, _KNN, _KTO, 0x00

enemySpeechJuda_0_1:

    .db     _KKO, _K_U, _KKA, _KKU, _KKE, _KNN, 0x00

; シュウ
enemySpeechShew_0:

    .db     _KHI, _Kyo, _K_U, _EXC, 0x00

enemyTalkShew_1:

    .db     ENEMY_TALK_OWNER
    .dw     enemySpeechShew_1_0
    .db     ENEMY_TALK_OWNER
    .dw     enemySpeechShew_1_1
    .db     0x00

enemySpeechShew_1_0:

    .db     _KNA, _KNN, _KTO, 0x00

enemySpeechShew_1_1:

    .db     _KYU, _K_U, _KKE, _KSN, _KNN, _KSI, _Kyo, _K_U, 0x00

enemySpeechShew_2_0:

    .db     _KHO, _KYA, _KSD, _EXC, _EXC, 0x00

enemySpeechShew_2_1:

    .db     _KKA, _KSN, _Ktu, _EXC, 0x00

enemyTalkShew_2_2:

    .db     ENEMY_TALK_OWNER
    .dw     enemySpeechShew_2_2_0
    .db     ENEMY_TALK_OWNER
    .dw     enemySpeechShew_2_2_1
    .db     0x00

enemySpeechShew_2_2_0:

    .db     _KNA, _KNN, _KTO, 0x00

enemySpeechShew_2_2_1:

    .db     _KRE, _Ktu, _KKI, _Kya, _KKU, ____, _KKU, _K_U, _KHU, _KSN, 0x00

enemySpeechShew_3_0:

    .db     _KSE, _K_I, _K_i, _K_i, _EXC, 0x00

enemyTalkShew_3_1:

    .db     ENEMY_TALK_OWNER
    .dw     enemySpeechShew_3_1_0
    .db     ENEMY_TALK_OWNER
    .dw     enemySpeechShew_3_1_1
    .db     0x00

enemySpeechShew_3_1_0:

    .db     _KNA, _KNN, _KTO, 0x00

enemySpeechShew_3_1_1:

    .db     _KRI, _Ktu, _KKI, _Kya, _KKU, ____, _KKU, _K_U, _KHU, _KSN, 0x00

; ラオウ

enemySpeechRaoh_0:

    .db     _K_A, _KTA, _EXC, 0x00

enemySpeechRaoh_1:

    .db     _K_A, _KTA, _K_a, _EXC, _EXC, 0x00

enemyTalkRaoh_2:

    .db     ENEMY_TALK_OWNER
    .dw     enemySpeechRaoh_2_0
    .db     ENEMY_TALK_OWNER
    .dw     enemySpeechRaoh_2_1
    .db     ENEMY_TALK_SILENT
    .db     0x00

enemySpeechRaoh_2_0:

    .db     _KHI, _KKO, _K_U, ____, _KNO, ____, _KHI, _KTO, _KTU, 0x00

enemySpeechRaoh_2_1:

    .db     _KSI, _KNN, _KKE, _KTU, _KSI, _Kyu, _K_U, ____, _KWO, _KTU, _K_I, _KTA, 0x00

; 倒れる
enemySpeechDown:

    .db     _KTO, _KSN, _KSA, _Ktu, 0x00

; 爆発
enemySpeechBomb:

    .dw     enemySpeechBomb_0
    .dw     enemySpeechBomb_1
    .dw     enemySpeechBomb_2
    .dw     enemySpeechBomb_3
    .dw     enemySpeechBomb_4
    .dw     enemySpeechBomb_5
    .dw     enemySpeechBomb_6
    .dw     enemySpeechBomb_7
    .dw     enemySpeechBomb_8
    .dw     enemySpeechBomb_9
    .dw     enemySpeechBomb_10

enemySpeechBomb_0:

    .db     _KHI, _KTE, _KSN, _KHU, _KSN, _EXC, 0x00

enemySpeechBomb_1:

    .db     _KWA, _KHA, _KSN, _KRA, _EXC, 0x00

enemySpeechBomb_2:

    .db     _KTA, _KWA, _KHA, _KSN, _EXC, 0x00

enemySpeechBomb_3:

    .db     _K_A, _KHE, _KSN, _KSI, _EXC, 0x00

enemySpeechBomb_4:

    .db     _KHA, _KKA, _KSN, _KKA, _KSN, 0x00

enemySpeechBomb_5:

    .db     _K_E, _KRO, _KHA, _KSN, _EXC, 0x00

enemySpeechBomb_6:

    .db     _KTI, _KNI, _Kya, _EXC, _EXC, 0x00

enemySpeechBomb_7:

    .db     _K_A, _KRO, _EXC, _EXC, _EXC, 0x00

enemySpeechBomb_8:

    .db     _KRA, _K_I, _KRE, _Ktu, _EXC, 0x00

enemySpeechBomb_9:

    .db     _KHI, _K_E, _EXC, _EXC, _EXC, 0x00

enemySpeechBomb_10:

    .db     _KHE, _KRE, _KTU, _EXC, _EXC, 0x00


; DATA 領域
;
    .area   _DATA

; 変数の定義
;

; エネミー
;
_enemy::
    
    .ds     ENEMY_LENGTH

; カウント
enemyCount:

    .ds     0x01
