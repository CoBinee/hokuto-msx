; Back.s : 背景
;


; モジュール宣言
;
    .module Back

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
    .include    "Enemy.inc"
    .include	"Back.inc"

; 外部変数宣言
;
    .globl  _patternTable

; マクロの定義
;


; CODE 領域
;
    .area   _CODE

; 背景を初期化する
;
_BackInitialize::

    ; レジスタの保存

    ; 背景の初期化
    ld      hl, #backDefault
    ld      de, #_back
    ld      bc, #BACK_LENGTH
    ldir

    ; 星の生成
    call    BackBuildStar

    ; パターンジェネレータの転送
    ld      hl, #(_patternTable + 0x11c0)
    ld      de, #(APP_PATTERN_GENERATOR_TABLE + 0x07c0)
    ld      bc, #0x0040
    call    LDIRVM

    ; カラーテーブルの設定
    ld      hl, #(_appColorTable + 0x0000)
    ld      de, #(_appColorTable + 0x0001)
    ld      bc, #(0x0010 - 0x0001)
    ld      (hl), #((VDP_COLOR_WHITE << 4) | VDP_COLOR_BLACK)
    ldir
    ld      a, #((VDP_COLOR_MEDIUM_GREEN << 4) | VDP_COLOR_BLACK)
    ld      (_appColorTable + 0x001f), a

    ; レジスタの復帰

    ; 終了
    ret


; 背景を更新する
;
_BackUpdate::

    ; レジスタの保存

    ; 初期化
    ld      a, (_back + BACK_STATE)
    or      a
    jr      nz, 09$

    ; 初期化の完了
    ld      hl, #(_back + BACK_STATE)
    inc     (hl)
09$:

    ; レジスタの復帰
    
    ; 終了
    ret

; 背景を描画する
;
_BackRender::
    
    ; レジスタの保存

    ; 画面のロード
    ld      a, (_back + BACK_FLAG)
    bit     #BACK_FLAG_LOAD_BIT, a
    jr      z, 190$

    ; 地面の描画
    ld      hl, #(_patternName + 18 * 0x0020 + 0x0000)
    ld      de, #(_patternName + 18 * 0x0020 + 0x0001)
    ld      bc, #(0x0020 - 0x0001)
    ld      (hl), #_BLK
    ldir

    ; ステータスの描画
    ld      hl, #backStatusLifeString
    ld      de, #((20 << 8) | 1)
    call    _GamePrintString
    ld      hl, #backStatusScoreString
    ld      de, #((22 << 8) | 1)
    call    _GamePrintString
    ld      hl, #backStatusNameString
    ld      de, #((20 << 8) | 15)
    call    _GamePrintString
;   ld      hl, #backStatusSpecialString
;   ld      de, #((22 << 8) | 15)
;   call    _GamePrintString

    ; ロードの完了
    ld      hl, #(_back + BACK_FLAG)
    res     #BACK_FLAG_LOAD_BIT, (hl)
190$:

    ; 北斗七星の描画
    ld      hl, #backBigDipperSprite
    ld      de, #(_sprite + 0x0024)
    ld      bc, #(0x0007 * 0x0004)
    ldir

    ; 星の描画
    ld      hl, #backStarSprite
    ld      de, #(_sprite + 0x0040)
    ld      bc, #(0x0010 * 0x0004)
    ldir

    ; フィールドのクリア
    ld      hl, #(_patternName + 10 * 0x0020 + 0x0000)
    ld      de, #(_patternName + 10 * 0x0020 + 0x0001)
    ld      bc, #(8 * 0x0020 - 0x0001)
    ld      (hl), #0x00
    ldir

    ; ステータスの描画
    call    _PlayerGetLife
    ld      de, #((20 << 8) | 7)
    call    _GamePrintValue
    call    _GameGetScore
    ld      de, #((22 << 8) | 7)
    call    _GamePrintValue
    call    _EnemyGetNameString
;   call    _EnemyGetLife
    ld      de, #((20 << 8) | 19)
    call    _GamePrintString
;   call    _GamePrintValue
    call    _PlayerGetSpecialString
    ld      de, #((22 << 8) | 15)
    call    _GamePrintString

    ; レジスタの復帰
    
    ; 終了
    ret

; 星を生成する
;
BackBuildStar:

    ; レジスタの保存

    ; スプライトの生成
    ld      hl, #backStarSprite
    ld      bc, #0x0800
10$:
    call    _SystemGetRandom
    and     #0x78
    cp      #0x50
    jr      nc, 10$
    dec     a
    ld      (hl), a
    inc     hl
    call    _SystemGetRandom
    and     #0x18
    add     a, c
    ld      (hl), a
    inc     hl
    ld      (hl), #0x02
    inc     hl
11$:
    call    _SystemGetRandom
    and     #0x0f
    cp      #0x02
    jr      c, 11$
    ld      (hl), a
    inc     hl
12$:
    call    _SystemGetRandom
    and     #0x78
    cp      #0x50
    jr      nc, 12$
    dec     a
    ld      (hl), a
    inc     hl
    call    _SystemGetRandom
    and     #0x18
    add     a, c
    ld      (hl), a
    inc     hl
    ld      (hl), #0x01
    inc     hl
13$:
    call    _SystemGetRandom
    and     #0x0f
    cp      #0x02
    jr      c, 13$
    ld      (hl), a
    inc     hl
    ld      a, c
    add     a, #0x20
    ld      c, a
    djnz    10$

    ; レジスタの復帰
    
    ; 終了
    ret

; 定数の定義
;

; 背景の初期値
;
backDefault:

    .db     BACK_STATE_NULL
    .db     BACK_FLAG_LOAD ; BACK_FLAG_NULL

; ステータス
;
backStatusLifeString:

    .db     _KTA, _K_I, _KRI, _Kyo, _KKU, _EQU, 0x00

backStatusScoreString:

    .db     ___S, ___C, ___O, ___R, ___E, _EQU, 0x00

backStatusNameString:

    .db     _KTE, _KKI, ____, _EQU, 0x00

backStatusSpecialString:

    .db     _KWA, _KSA, _KSN, _EQU, 0x00

; 北斗七星
;
backBigDipperSprite:

    .db     ( 1 / 2) * 0x08 - 0x01, ((39 - 4) / 2) * 0x08, (( 1 % 2) * 0x02) + ((39 - 4) % 2) + 0x03, VDP_COLOR_WHITE
    .db     ( 3 / 2) * 0x08 - 0x01, ((34 - 4) / 2) * 0x08, (( 3 % 2) * 0x02) + ((34 - 4) % 2) + 0x03, VDP_COLOR_WHITE
    .db     ( 4 / 2) * 0x08 - 0x01, ((42 - 4) / 2) * 0x08, (( 4 % 2) * 0x02) + ((42 - 4) % 2) + 0x03, VDP_COLOR_WHITE
    .db     ( 6 / 2) * 0x08 - 0x01, ((39 - 4) / 2) * 0x08, (( 6 % 2) * 0x02) + ((39 - 4) % 2) + 0x03, VDP_COLOR_WHITE
    .db     ( 9 / 2) * 0x08 - 0x01, ((38 - 4) / 2) * 0x08, (( 9 % 2) * 0x02) + ((38 - 4) % 2) + 0x03, VDP_COLOR_WHITE
    .db     (12 / 2) * 0x08 - 0x01, ((40 - 4) / 2) * 0x08, ((12 % 2) * 0x02) + ((40 - 4) % 2) + 0x03, VDP_COLOR_WHITE
    .db     (13 / 2) * 0x08 - 0x01, ((43 - 4) / 2) * 0x08, ((13 % 2) * 0x02) + ((43 - 4) % 2) + 0x03, VDP_COLOR_WHITE


; DATA 領域
;
    .area   _DATA

; 変数の定義
;

; 背景
;
_back::
    
    .ds     BACK_LENGTH

; 星
;
backStarSprite:

    .ds     0x0010 * 0x0004
