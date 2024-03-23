; App.s : アプリケーション
;


; モジュール宣言
;
    .module App

; 参照ファイル
;
    .include    "bios.inc"
    .include    "vdp.inc"
    .include    "System.inc"
    .include	"App.inc"
    .include    "Title.inc"
    .include    "Game.inc"

; 外部変数宣言
;
    .globl  _patternTable
    

; CODE 領域
;
    .area   _CODE

; アプリケーションを初期化する
;
_AppInitialize::
    
    ; レジスタの保存
    
    ; 画面表示の停止
    call    DISSCR
    
    ; ビデオの設定
    ld      hl, #videoScreen1
    ld      de, #_videoRegister
    ld      bc, #0x08
    ldir
    
    ; 割り込みの禁止
    di
    
    ; VDP ポートの取得
    ld      a, (_videoPort + 1)
    ld      c, a
    
    ; スプライトジェネレータの転送
;   inc     c
;   ld      a, #<APP_SPRITE_GENERATOR_TABLE
;   out     (c), a
;   ld      a, #(>APP_SPRITE_GENERATOR_TABLE | 0b01000000)
;   out     (c), a
;   dec     c
;   ld      hl, #(_patternTable + 0x0000)
;   ld      d, #0x08
;10$:
;   ld      e, #0x10
;11$:
;   push    de
;   ld      b, #0x08
;   otir
;   ld      de, #0x78
;   add     hl, de
;   ld      b, #0x08
;   otir
;   ld      de, #0x80
;   or      a
;   sbc     hl, de
;   pop     de
;   dec     e
;   jr      nz, 11$
;   ld      a, #0x80
;   add     a, l
;   ld      l, a
;   ld      a, h
;   adc     a, #0x00
;   ld      h, a
;   dec     d
;   jr      nz, 10$
    ld      hl, #(_patternTable + 0x0000)
    ld      de, #APP_SPRITE_GENERATOR_TABLE
    ld      bc, #0x0800
    call    LDIRVM
    
    ; パターンジェネレータの転送
    ld      hl, #(_patternTable + 0x0800)
    ld      de, #APP_PATTERN_GENERATOR_TABLE
    ld      bc, #0x0400
    call    LDIRVM
    
    ; カラーテーブルの初期化
;   ld      hl, #appColorTable
;   ld      de, #APP_COLOR_TABLE
;   ld      bc, #0x0020
;   call    LDIRVM
    ld      hl, #(_appColorTable + 0x0000)
    ld      de, #(_appColorTable + 0x0001)
    ld      bc, #(0x0020 - 0x0001)
    ld      (hl), #((VDP_COLOR_WHITE << 4) | VDP_COLOR_BLACK)
    ldir
    call    _AppTransferColorTable
    
    ; パターンネームの初期化
    ld      hl, #APP_PATTERN_NAME_TABLE
    xor     a
    ld      bc, #0x0300
    call    FILVRM
    
    ; 割り込み禁止の解除
    ei

    ; アプリケーションの初期化
    ld      hl, #appDefault
    ld      de, #_app
    ld      bc, #APP_LENGTH
    ldir
    
    ; 状態の初期化
    ld      a, #APP_STATE_TITLE_INITIALIZE
    ld      (_app + APP_STATE), a
    
    ; レジスタの復帰
    
    ; 終了
    ret

; アプリケーションを更新する
;
_AppUpdate::
    
    ; レジスタの保存

    ; 状態別の処理
    ld      hl, #10$
    push    hl
    ld      a, (_app + APP_STATE)
    add     a, a
    ld      e, a
    ld      d, #0x00
    ld      hl, #appProc
    add     hl, de
    ld      e, (hl)
    inc     hl
    ld      d, (hl)
    ex      de, hl
    jp      (hl)
;   pop     hl
10$:

    ; 乱数を混ぜる
    call    _SystemGetRandom

    ; デバッグ表示
    ld      hl, #(_debug + DEBUG_7)
    inc     (hl)
;   call    AppPrintDebug

    ; 更新の終了
90$:

    ; レジスタの復帰
    
    ; 終了
    ret

; 処理なし
;
_AppNull::

    ; レジスタの保存
    
    ; レジスタの復帰
    
    ; 終了
    ret

; カラーテーブルを転送する
;
_AppTransferColorTable::

    ; レジスタの保存
    push    hl
    push    bc
    push    de

    ; カラーテーブルの転送
    ld      hl, #_appColorTable
    ld      de, #APP_COLOR_TABLE
    ld      bc, #0x0020
    call    LDIRVM

    ; レジスタの復帰
    pop     de
    pop     bc
    pop     hl
    
    ; 終了
    ret

; 16bits, 5 桁の数値の 16→10 進数変換を行う
;
_AppGetDecimal16::

    ; レジスタの保存
    push    hl
    push    bc
    push    de

    ; hl < 値
    ; de < 10 進数

    ; 数値の変換
    ld      bc, #10000
    xor     a
100$:
    sbc     hl, bc
    jr      c, 101$
    inc     a
    jr      100$
101$:
    ld      (de), a
    inc     de
    add     hl, bc
    ld      bc, #1000
    xor     a
110$:
    sbc     hl, bc
    jr      c, 111$
    inc     a
    jr      110$
111$:
    ld      (de), a
    inc     de
    add     hl, bc
    ld      bc, #100
    xor     a
120$:
    sbc     hl, bc
    jr      c, 121$
    inc     a
    jr      120$
121$:
    ld      (de), a
    inc     de
    add     hl, bc
    ld      a, l
    ld      b, #10
    ld      c, #0x00
130$:
    sub     b
    jr      c, 131$
    inc     c
    jr      130$
131$:
    add     a, b
    ld      b, a
    ld      a, c
    ld      (de), a
    inc     de
    ld      a, b
    ld      (de), a
;   inc     de

    ; レジスタの復帰
    pop     de
    pop     bc
    pop     hl

    ; 終了
    ret

; 8bits, 3 桁の数値の 16→10 進数変換を行う
;
_AppGetDecimal8::

    ; レジスタの保存
    push    hl
    push    bc
    push    de

    ; a  < 値
    ; de < 10 進数

    ; 数値の変換
    ex      de, hl
    ld      bc, #((100 << 8) | 0x00)
100$:
    sub     b
    jr      c, 101$
    inc     c
    jr      100$
101$:
    ld      (hl), c
    inc     hl
    add     a, b
    ld      bc, #((10 << 8) | 0x00)
110$:
    sub     b
    jr      c, 111$
    inc     c
    jr      110$
111$:
    ld      (hl), c
    inc     hl
    add     a, b
    ld      (hl), a
;   inc     hl

    ; レジスタの復帰
    pop     de
    pop     bc
    pop     hl

    ; 終了
    ret

; デバッグ情報を表示する
;
AppPrintDebug:

    ; レジスタの保存

    ; デバッグ数値の表示
    ld      de, #(_patternName + 0x02e0)
    ld      hl, #appDebugStringNumber
    call    70$
    ld      hl, #_debug
    ld      b, #DEBUG_SIZE
10$:
    ld      a, (hl)
    call    80$
    inc     hl
    djnz    10$
    jr      90$

    ; 文字列の表示
70$:
    ld      a, (hl)
    sub     #0x20
    ret     c
    ld      (de), a
    inc     hl
    inc     de
    jr      70$

    ; 16 進数の表示
80$:
    push    af
    rrca
    rrca
    rrca
    rrca
    call    81$
    pop     af
    call    81$
    ret
81$:
    and     #0x0f
    cp      #0x0a
    jr      c, 82$
    add     a, #0x07
82$:
    add     a, #0x10
    ld      (de), a
    inc     de
    ret

    ; デバッグ表示の完了
90$:

    ; レジスタの復帰

    ; 終了
    ret

; 定数の定義
;

; VDP レジスタ値（スクリーン１）
;
videoScreen1:

    .db     0b00000000
    .db     0b10100000
    .db     APP_PATTERN_NAME_TABLE >> 10
    .db     APP_COLOR_TABLE >> 6
    .db     APP_PATTERN_GENERATOR_TABLE >> 11
    .db     APP_SPRITE_ATTRIBUTE_TABLE >> 7
    .db     APP_SPRITE_GENERATOR_TABLE >> 11
    .db     0b00000111

; カラーテーブル
;
;appColorTable:
;
;   .db     (VDP_COLOR_WHITE        << 4) | VDP_COLOR_BLACK,       (VDP_COLOR_WHITE        << 4) | VDP_COLOR_BLACK
;   .db     (VDP_COLOR_WHITE        << 4) | VDP_COLOR_BLACK,       (VDP_COLOR_WHITE        << 4) | VDP_COLOR_BLACK
;   .db     (VDP_COLOR_WHITE        << 4) | VDP_COLOR_BLACK,       (VDP_COLOR_WHITE        << 4) | VDP_COLOR_BLACK
;   .db     (VDP_COLOR_WHITE        << 4) | VDP_COLOR_BLACK,       (VDP_COLOR_WHITE        << 4) | VDP_COLOR_BLACK
;   .db     (VDP_COLOR_WHITE        << 4) | VDP_COLOR_BLACK,       (VDP_COLOR_WHITE        << 4) | VDP_COLOR_BLACK
;   .db     (VDP_COLOR_WHITE        << 4) | VDP_COLOR_BLACK,       (VDP_COLOR_WHITE        << 4) | VDP_COLOR_BLACK
;   .db     (VDP_COLOR_WHITE        << 4) | VDP_COLOR_BLACK,       (VDP_COLOR_WHITE        << 4) | VDP_COLOR_BLACK
;   .db     (VDP_COLOR_WHITE        << 4) | VDP_COLOR_BLACK,       (VDP_COLOR_WHITE        << 4) | VDP_COLOR_BLACK
;   .db     (VDP_COLOR_WHITE        << 4) | VDP_COLOR_BLACK,       (VDP_COLOR_WHITE        << 4) | VDP_COLOR_BLACK
;   .db     (VDP_COLOR_WHITE        << 4) | VDP_COLOR_BLACK,       (VDP_COLOR_WHITE        << 4) | VDP_COLOR_BLACK
;   .db     (VDP_COLOR_WHITE        << 4) | VDP_COLOR_BLACK,       (VDP_COLOR_WHITE        << 4) | VDP_COLOR_BLACK
;   .db     (VDP_COLOR_WHITE        << 4) | VDP_COLOR_BLACK,       (VDP_COLOR_WHITE        << 4) | VDP_COLOR_BLACK
;   .db     (VDP_COLOR_WHITE        << 4) | VDP_COLOR_BLACK,       (VDP_COLOR_WHITE        << 4) | VDP_COLOR_BLACK
;   .db     (VDP_COLOR_WHITE        << 4) | VDP_COLOR_BLACK,       (VDP_COLOR_WHITE        << 4) | VDP_COLOR_BLACK
;   .db     (VDP_COLOR_WHITE        << 4) | VDP_COLOR_BLACK,       (VDP_COLOR_WHITE        << 4) | VDP_COLOR_BLACK
;   .db     (VDP_COLOR_WHITE        << 4) | VDP_COLOR_BLACK,       (VDP_COLOR_WHITE        << 4) | VDP_COLOR_BLACK

; 状態別の処理
;
appProc:
    
    .dw     _AppNull
    .dw     _TitleInitialize
    .dw     _TitleUpdate
    .dw     _GameInitialize
    .dw     _GameUpdate

; アプリケーションの初期値
;
appDefault:

    .db     APP_STATE_NULL
    .db     APP_FRAME_NULL

; デバッグ
;
appDebugStringNumber:

    .ascii  "DBG="
    .db     0x00


; DATA 領域
;
    .area   _DATA

; 変数の定義
;

; アプリケーション
;
_app::

    .ds     APP_LENGTH

; カラーテーブル
;
_appColorTable::

    .ds     0x0020

