; Game.s : ゲーム
;


; モジュール宣言
;
    .module Game

; 参照ファイル
;
    .include    "bios.inc"
    .include    "vdp.inc"
    .include    "System.inc"
    .include    "Sound.inc"
    .include    "App.inc"
    .include    "Code.inc"
    .include	"Game.inc"
    .include    "Player.inc"
    .include    "Enemy.inc"
    .include    "Back.inc"

; 外部変数宣言
;
    .globl  _patternTable

; マクロの定義
;


; CODE 領域
;
    .area   _CODE

; ゲームを初期化する
;
_GameInitialize::
    
    ; レジスタの保存
    
    ; スプライトのクリア
    call    _SystemClearSprite
    
    ; パターンネームのクリア
    xor     a
    call    _SystemClearPatternName
    
    ; ゲームの初期化
    ld      hl, #gameDefault
    ld      de, #_game
    ld      bc, #GAME_LENGTH
    ldir

    ; プレイヤの初期化
    call    _PlayerInitialize

    ; エネミーの初期化
    call    _EnemyInitialize

    ; 背景の初期化
    call    _BackInitialize

    ; 転送の設定
    ld      hl, #_SystemUpdatePatternName
    ld      (_transfer), hl

    ; 描画の開始
    ld      hl, #(_videoRegister + VDP_R1)
    set     #VDP_R1_BL, (hl)
    
    ; 処理の設定
    ld      hl, #GameLoad
    ld      (_game + GAME_PROC_L), hl
    xor     a
    ld      (_game + GAME_STATE), a

    ; 状態の設定
    ld      a, #APP_STATE_GAME_UPDATE
    ld      (_app + APP_STATE), a
    
    ; レジスタの復帰
    
    ; 終了
    ret

; ゲームを更新する
;
_GameUpdate::
    
    ; レジスタの保存
    
    ; スプライトのクリア
    call    _SystemClearSprite

    ; 状態別の処理
    ld      hl, #10$
    push    hl
    ld      hl, (_game + GAME_PROC_L)
    jp      (hl)
;   pop     hl
10$:

    ; フレームの更新
    ld      hl, #(_game + GAME_FRAME)
    inc     (hl)

    ; レジスタの復帰
    
    ; 終了
    ret

; 何もしない
;
GameNull:

    ; レジスタの保存

    ; レジスタの復帰

    ; 終了
    ret

; ゲームを待機する
;
GameIdle:

    ; レジスタの保存

    ; 初期化
    ld      a, (_game + GAME_STATE)
    or      a
    jr      nz, 09$

    ; 初期化の完了
    ld      hl, #(_game + GAME_STATE)
    inc     (hl)
09$:

    ; レジスタの復帰

    ; 終了
    ret

; ゲームを読み込む
;
GameLoad:

    ; レジスタの保存

    ; 初期化
    ld      a, (_game + GAME_STATE)
    or      a
    jr      nz, 09$

    ; 転送の設定
    ld      hl, #_SystemUpdatePatternName
    ld      (_transfer), hl

    ; 初期化の完了
    ld      hl, #(_game + GAME_STATE)
    inc     (hl)
09$:

    ; プレイヤの更新
    call    _PlayerUpdate

    ; エネミーの更新
    call    _EnemyUpdate

    ; 背景の更新
    call    _BackUpdate

    ; 背景の描画
    call    _BackRender

    ; エネミーの描画
    call    _EnemyRender

    ; プレイヤの描画
    call    _PlayerRender

    ; 処理の更新
    ld      hl, #GamePlay
    ld      (_game + GAME_PROC_L), hl
    xor     a
    ld      (_game + GAME_STATE), a

    ; レジスタの復帰

    ; 終了
    ret

; ゲームをプレイする
;
GamePlay:

    ; レジスタの保存

    ; 初期化
    ld      a, (_game + GAME_STATE)
    or      a
    jr      nz, 09$

    ; 転送の設定
    ld      hl, #GameTransfer
    ld      (_transfer), hl

    ; 初期化の完了
    ld      hl, #(_game + GAME_STATE)
    inc     (hl)
09$:

    ; プレイヤの更新
    call    _PlayerUpdate

    ; エネミーの更新
    call    _EnemyUpdate

    ; 背景の更新
    call    _BackUpdate

    ; 背景の描画
    call    _BackRender

    ; エネミーの描画
    call    _EnemyRender

    ; プレイヤの描画
    call    _PlayerRender

    ; ゲームオーバーの判定
    call    _PlayerIsDead
    jr      nc, 99$

    ; 処理の更新
    ld      hl, #GameOver
    ld      (_game + GAME_PROC_L), hl
    xor     a
    ld      (_game + GAME_STATE), a
99$:

    ; レジスタの復帰

    ; 終了
    ret

; ゲームオーバーになる
;
GameOver:

    ; レジスタの保存

    ; 初期化
    ld      a, (_game + GAME_STATE)
    or      a
    jr      nz, 09$

    ; ゲームオーバーの表示
    call    GamePrintOver

    ; 転送の設定
    ld      hl, #_SystemUpdatePatternName
    ld      (_transfer), hl

    ; 初期化の完了
    ld      hl, #(_game + GAME_STATE)
    inc     (hl)
09$:

    ; プレイヤの更新
    call    _PlayerUpdate

    ; エネミーの更新
    call    _EnemyUpdate

    ; 背景の更新
    call    _BackUpdate

    ; 背景の描画
    call    _BackRender

    ; エネミーの描画
    call    _EnemyRender

    ; プレイヤの描画
    call    _PlayerRender

    ; SPACE キーの入力
    ld      a, (_input + INPUT_BUTTON_SPACE)
    dec     a
    jr      nz, 99$

    ; 画面のクリア
    xor     a
    call    _SystemClearPatternName
    
    ; 状態の更新
    ld      a, #APP_STATE_TITLE_INITIALIZE
    ld      (_app + APP_STATE), a
99$:

    ; レジスタの復帰

    ; 終了
    ret

; VRAM へ転送する
;
GameTransfer:

    ; レジスタの保存

    ; d < ポート #0
    ; e < ポート #1

    ; フィールドの転送
    ld      hl, #(10 * 0x0020 + 0)
    ld      b, #(8 * 0x20)
    call    GameTransferPatternName

    ; ステータスの転送
    ld      hl, #(20 * 0x0020 + 7)
    ld      b, #(32 - 8)
    call    GameTransferPatternName
    ld      hl, #(22 * 0x0020 + 7)
    ld      b, #(32 - 8)
    call    GameTransferPatternName

    ; カラーテーブルの転送
    call    GameTransferColorTable

    ; デバッグの転送
    ld      hl, #0x02e0
    ld      b, #0x14
    call    GameTransferPatternName

    ; レジスタの復帰

    ; 終了
    ret

GameTransferPatternName:

    ; レジスタの保存
    push    de

    ; d  < ポート #0
    ; e  < ポート #1
    ; hl < 相対アドレス
    ; b  < 転送バイト数

    ; パターンネームテーブルの取得    
    ld      a, (_videoRegister + VDP_R2)
    add     a, a
    add     a, a
    add     a, h

    ; VRAM アドレスの設定
    ld      c, e
    out     (c), l
    or      #0b01000000
    out     (c), a

    ; パターンネームテーブルの転送
    ld      c, d
    ld      de, #_patternName
    add     hl, de
10$:
    outi
    jp      nz, 10$

    ; レジスタの復帰
    pop     de

    ; 終了
    ret

GameTransferColorTable:

    ; レジスタの保存
    push    de

    ; d  < ポート #0
    ; e  < ポート #1

    ; パターンネームテーブルの取得    
    ld      a, (_videoRegister + VDP_R3)
    ld      l, #0x00
    srl     a
    rr      l
    srl     a
    rr      l

    ; VRAM アドレスの設定
    ld      c, e
    out     (c), l
    or      #0b01000000
    out     (c), a

    ; パターンネームテーブルの転送
    ld      c, d
    ld      hl, #_appColorTable
    ld      b, #0x20
10$:
    outi
    jp      nz, 10$

    ; レジスタの復帰
    pop     de

    ; 終了
    ret

; スコアを取得する
;
_GameGetScore::

    ; レジスタの保存

    ; hl > スコア

    ; スコアの取得
    ld      hl, (_game + GAME_SCORE_L)

    ; レジスタの復帰

    ; 終了
    ret

; スコアを加算する
;
_GameAddScore::

    ; レジスタの保存
    push    hl
    push    de

    ; hl < スコア

    ; スコアの加算
    ld      de, (_game + GAME_SCORE_L)
    add     hl, de
    ld      de, #GAME_SCORE_MAXIMUM
    or      a
    sbc     hl, de
    jr      nc, 10$
    add     hl, de
    jr      11$
10$:
    ex      de, hl
11$:
    ld      (_game + GAME_SCORE_L), hl

    ; レジスタの復帰
    pop     de
    pop     hl

    ; 終了
    ret

; 台詞の表示位置を取得する
;
_GameGetSpeechPosition::

    ; レジスタの保存
    push    hl
    push    bc

    ; hl < 文字列
    ; de < Y/X 位置
    ; de > 表示位置

    ; 文字列長の取得
    ld      b, #0x00
10$:
    ld      a, (hl)
    or      a
    jr      z, 11$
    inc     hl
    inc     b
    jr      10$
11$:

    ; 位置の調整
    ld      a, b
    srl     a
    sub     e
    neg
    jp      p, 20$
    xor     a
20$:
    ld      e, a
    add     a, b
    cp      #(0x20 + 0x01)
    jr      c, 21$
    ld      a, #0x20
    sub     b
    ld      e, a
21$:

    ; レジスタの復帰
    pop     bc
    pop     hl

    ; 終了
    ret

; ゲームオーバーを表示する
;
GamePrintOver:

    ; レジスタの保存

    ; GAME OVER の描画
    ld      hl, #gameStringGameOver
    ld      de, #((3 << 8) | 11)
    call    _GamePrintString

    ; YOUR SCORE の描画
    ld      hl, #gameStringYourScore
    ld      de, #((5 << 8) | 7)
    call    _GamePrintString
    ld      hl, (_game + GAME_SCORE_L)
    ld      de, #((5 << 8) | 20)
    call    _GamePrintValue

    ; PUSH [ ] KEY の描画
    ld      hl, #gameStringPushSpaceKey
    ld      de, #((7 << 8) | 8)
    call    _GamePrintString

    ; レジスタの復帰

    ; 終了
    ret

; 文字列を表示する
;
_GamePrintString::

    ; レジスタの保存
    push    hl
    push    de
    
    ; hl < 文字列
    ; de < Y/X 位置

    ; 表示位置の取得
    push    hl
    xor     a
    srl     d
    rra
    srl     d
    rra
    srl     d
    rra
    add     a, e
    ld      e, a
    ld      hl, #_patternName
    add     hl, de
    ex      de, hl
    pop     hl

    ; コードの描画
10$:
    ld      a, (hl)
    or      a
    jr      z, 19$
    ld      (de), a
    inc     hl
    inc     de
    jr      10$
19$:

    ; レジスタの復帰
    pop     de
    pop     hl

    ; 終了
    ret

; 数値を表示する
;
_GamePrintValue::

    ; レジスタの保存
    push    hl
    push    de
    
    ; hl < 数値
    ; de < Y/X 位置

    ; 表示位置の取得
    push    hl
    xor     a
    srl     d
    rra
    srl     d
    rra
    srl     d
    rra
    add     a, e
    ld      e, a
    ld      hl, #_patternName
    add     hl, de
    ex      de, hl
    pop     hl

    ; 数値の文字列化
    push    de
    ld      de, #gameValue
    call    _AppGetDecimal16
    pop     de

    ; 文字列の描画
    ld      hl, #(gameValue + 0x0001)
    ld      b, #0x03
10$:
    ld      a, (hl)
    or      a
    jr      nz, 11$
    ld      (de), a
    inc     hl
    inc     de
    djnz    10$
11$:
    inc     b
12$:
    ld      a, (hl)
    add     a, #___0
    ld      (de), a
    inc     hl
    inc     de
    djnz    12$

    ; レジスタの復帰
    pop     de
    pop     hl

    ; 終了
    ret

; パターンを表示する
;
_GamePrintPattern::

    ; レジスタの保存
    push    hl
    push    bc
    push    de
    
    ; hl < パターン
    ; de < Y/X 位置

    ; 位置の調整
    ld      a, e
    add     a, (hl)
    ld      e, a
    inc     hl
    ld      a, d
    add     a, (hl)
    ld      d, a
    inc     hl

    ; サイズの取得
    ld      b, #0x00
    ld      c, (hl)
    inc     hl
    ld      (gamePattern), bc
    ld      b, (hl)
    inc     hl

    ; クリッピング
    ld      a, e
    or      a
    jp      p, 10$
    add     a, c
    jp      m, 90$
    jr      z, 90$
    ld      c, a
    push    de
    ld      a, e
    neg
    ld      e, a
    ld      d, #0x00
    add     hl, de
    pop     de
    ld      e, #0x00
    jr      19$
10$:
    ld      a, e
    cp      #0x20
    jr      nc, 90$
    add     a, c
    sub     #0x20
    jr      c, 19$
    jr      z, 19$
    sub     c
    neg
    ld      c, a
;   jr      19$
19$:

    ; 表示位置の取得
    push    hl
    xor     a
    srl     d
    rra
    srl     d
    rra
    srl     d
    rra
    add     a, e
    ld      e, a
    ld      hl, #_patternName
    add     hl, de
    ex      de, hl
    pop     hl

    ; パターンの描画
30$:
    push    bc
    push    hl
    push    de
31$:
    ld      a, (hl)
    cp      #____
    jr      z, 32$
    ld      (de), a
32$:
    inc     hl
    inc     de
    dec     c
    jr      nz, 31$
    pop     de
    ex      de, hl
    ld      bc, #0x0020
    add     hl, bc
    ex      de, hl
    pop     hl
    ld      bc, (gamePattern)
    add     hl, bc
    pop     bc
    djnz    30$

    ; 表示の完了
90$:

    ; レジスタの復帰
    pop     de
    pop     bc
    pop     hl

    ; 終了
    ret

; 定数の定義
;

; ゲームの初期値
;
gameDefault:

    .dw     GAME_PROC_NULL
    .db     GAME_STATE_NULL
    .db     GAME_FLAG_NULL
    .db     GAME_FRAME_NULL
    .db     GAME_COUNT_NULL
    .dw     GAME_SCORE_NULL

; 文字列
;
gameStringGameOver:

    .db     ___G, ___A, ___M, ___E, ____, ___O, ___V, ___E, ___R, 0x00

gameStringYourScore:

    .db     ___Y, ___O, ___U, ___R, ____, ___S, ___C, ___O, ___R, ___E, ____, _EQU, 0x00

gameStringPushSpaceKey:

    .db     ___P, ___U, ___S, ___H, ____, _LSB, ____, _RSB, ____, ___K, ___E, ___Y, ____, _EXC, _EXC, 0x00


; DATA 領域
;
    .area   _DATA

; 変数の定義
;

; ゲーム
;
_game::

    .ds     GAME_LENGTH

; 数値
;
gameValue:

    .ds     0x05

; パターン
;
gamePattern:

    .ds     0x02
