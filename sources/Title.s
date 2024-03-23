; Title.s : タイトル
;


; モジュール宣言
;
    .module Title

; 参照ファイル
;
    .include    "bios.inc"
    .include    "vdp.inc"
    .include    "System.inc"
    .include    "Sound.inc"
    .include    "App.inc"
    .include    "Code.inc"
    .include	"Title.inc"

; 外部変数宣言
;
    .globl  _patternTable

; マクロの定義
;


; CODE 領域
;
    .area   _CODE

; タイトルを初期化する
;
_TitleInitialize::
    
    ; レジスタの保存
    
    ; スプライトのクリア
    call    _SystemClearSprite
    
    ; パターンネームのクリア
    xor     a
    call    _SystemClearPatternName
    
    ; タイトルの初期化
    ld      hl, #titleDefault
    ld      de, #_title
    ld      bc, #TITLE_LENGTH
    ldir

    ; パターンジェネレータの転送
    ld      hl, #(_patternTable + 0x0e00)
    ld      de, #(APP_PATTERN_GENERATOR_TABLE + 0x0600)
    ld      bc, #0x0200
    call    LDIRVM

    ; カラーテーブルの転送
    ld      hl, #(_appColorTable + 0x0018 + 0x0000)
    ld      de, #(_appColorTable + 0x0018 + 0x0001)
    ld      bc, #(0x0008 - 0x0001)
    ld      (hl), #((VDP_COLOR_WHITE << 4) | VDP_COLOR_BLACK)
    ldir
    call    _AppTransferColorTable

    ; 転送の設定
    ld      hl, #_SystemUpdatePatternName
    ld      (_transfer), hl

    ; 描画の開始
    ld      hl, #(_videoRegister + VDP_R1)
    set     #VDP_R1_BL, (hl)
    
    ; 処理の設定
    ld      hl, #TitlePrologue
    ld      (_title + TITLE_PROC_L), hl
    xor     a
    ld      (_title + TITLE_STATE), a

    ; 状態の設定
    ld      a, #APP_STATE_TITLE_UPDATE
    ld      (_app + APP_STATE), a
    
    ; レジスタの復帰
    
    ; 終了
    ret

; タイトルを更新する
;
_TitleUpdate::
    
    ; レジスタの保存
    
    ; スプライトのクリア
    call    _SystemClearSprite

    ; 状態別の処理
    ld      hl, #10$
    push    hl
    ld      hl, (_title + TITLE_PROC_L)
    jp      (hl)
;   pop     hl
10$:

    ; フレームの更新
    ld      hl, #(_title + TITLE_FRAME)
    inc     (hl)

    ; レジスタの復帰
    
    ; 終了
    ret

; 何もしない
;
TitleNull:

    ; レジスタの保存

    ; レジスタの復帰

    ; 終了
    ret

; プロローグ
;
TitlePrologue:

    ; レジスタの保存

    ; 初期化
    ld      a, (_title + TITLE_STATE)
    or      a
    jr      nz, 09$

    ; カウントの設定
    xor     a
    ld      (_title + TITLE_COUNT), a

    ; アニメーションの設定
    xor     a
    ld      (_title + TITLE_ANIMATION), a

    ; 画面のクリア
    xor     a
    call    _SystemClearPatternName

    ; 初期化の完了
    ld      hl, #(_title + TITLE_STATE)
    inc     (hl)
09$:

    ; プロローグの表示
    call    TitlePrintPrologue

    ; SPACE キーの入力
    ld      a, (_input + INPUT_BUTTON_SPACE)
    dec     a
    jr      z, 18$

    ; アニメーションの更新
    ld      hl, #(_title + TITLE_ANIMATION)
    inc     (hl)
    ld      a, (hl)
    and     #0x07
    jr      nz, 19$

    ; カウントの更新
    ld      hl, #(_title + TITLE_COUNT)
    inc     (hl)
    ld      e, (hl)
    ld      d, #0x00
    ld      hl, #titleStringPrologue
    add     hl, de
    ld      a, (hl)
    or      a
    jr      nz, 19$

    ; 処理の更新
18$:
    ld      hl, #TitleIdle
    ld      (_title + TITLE_PROC_L), hl
    xor     a
    ld      (_title + TITLE_STATE), a
19$:

    ; レジスタの復帰

    ; 終了
    ret

; タイトルを待機する
;
TitleIdle:

    ; レジスタの保存

    ; 初期化
    ld      a, (_title + TITLE_STATE)
    or      a
    jr      nz, 09$

    ; 画面のクリア
    xor     a
    call    _SystemClearPatternName

    ; タイトルの表示
    call    TitlePrintTitle

    ; 初期化の完了
    ld      hl, #(_title + TITLE_STATE)
    inc     (hl)
09$:

    ; 0x01 : キー入力
10$:
    ld      a, (_title + TITLE_STATE)
    dec     a
    jr      nz, 20$

    ; SPACE キーの入力
    ld      a, (_input + INPUT_BUTTON_SPACE)
    dec     a
    jr      nz, 19$

    ; SE の再生
    ld      a, #SOUND_SE_BOOT
    call    _SoundPlaySe

    ; アニメーションの設定
    ld      a, #0x60
    ld      (_title + TITLE_ANIMATION), a

    ; 状態の更新
    ld      hl, #(_title + TITLE_STATE)
    inc     (hl)
19$:
    jr      90$

    ; 0x02 : サウンドの再生
20$:
;   dec     a
;   jr      nz, 30$

    ; アニメーションの更新
    ld      hl, #(_title + TITLE_ANIMATION)
    dec     (hl)
    jr      nz, 29$

    ; 画面のクリア
    xor     a
    call    _SystemClearPatternName
    
    ; 状態の更新
    ld      a, #APP_STATE_GAME_INITIALIZE
    ld      (_app + APP_STATE), a
29$:
    jr      90$

    ; 待機の完了
90$:

    ; レジスタの復帰

    ; 終了
    ret

; プロローグを表示する
;
TitlePrintPrologue:

    ; レジスタの保存
    push    hl
    push    bc
    push    de

    ; 文字列の表示
    ld      a, (_title + TITLE_COUNT)
    cp      #0x20
    jr      nc, 10$
    inc     a
    ld      b, a
    ld      a, #0x20
    sub     b
    ld      e, a
    ld      d, #12
    ld      hl, #titleStringPrologue
    jr      19$
10$:
    sub     #0x1f
    ld      e, a
    ld      d, #0x00
    ld      hl, #titleStringPrologue
    add     hl, de
    ld      de, #((12 << 8) | 0)
    ld      b, #0x20
19$:
    call    TitlePrintString

    ; レジスタの復帰
    pop     de
    pop     bc
    pop     hl

    ; 終了
    ret

; タイトルを表示する
;
TitlePrintTitle:

    ; レジスタの保存
    push    hl
    push    bc
    push    de

    ; タイトルの描画
    ld      hl, #titleStringTitle
    ld      b, #0x20
10$:
    ld      a, (hl)
    cp      #0xff
    jr      z, 19$
    ld      e, a
    inc     hl
    ld      d, (hl)
    inc     hl
    call    TitlePrintString
11$:
    ld      a, (hl)
    inc     hl
    or      a
    jr      nz, 11$
    jr      10$
19$:

    ; レジスタの復帰
    pop     de
    pop     bc
    pop     hl

    ; 終了
    ret

; 文字列を表示する
;
TitlePrintString::

    ; レジスタの保存
    push    hl
    push    bc
    push    de
    
    ; hl < 文字列
    ; de < Y/X 位置
    ; b  < 長さ

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
    djnz    10$
19$:

    ; レジスタの復帰
    pop     de
    pop     bc
    pop     hl

    ; 終了
    ret

; 数値を表示する
;
TitlePrintValue::

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
    ld      de, #titleValue
    call    _AppGetDecimal16
    pop     de

    ; 文字列の描画
    ld      hl, #(titleValue + 0x0001)
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

; 定数の定義
;

; タイトルの初期値
;
titleDefault:

    .dw     TITLE_PROC_NULL
    .db     TITLE_STATE_NULL
    .db     TITLE_FLAG_NULL
    .db     TITLE_FRAME_NULL
    .db     TITLE_COUNT_NULL
    .db     TITLE_ANIMATION_NULL

; 文字列
;
titleStringPrologue:

    .db     ___2, ___0, ___0, ___0, _YEA, _KNO, ____, _KRE, _KKI, _KSI, ____, _KWO, ____, _KKI, _KSA, _KSN, _KMI, ____
    .db     _K_U, _KKE, _KTU, _KKA, _KSN, _KRE, _KTE, _KKI, _KTA, ____
    .db     _K_O, _KSO, _KRU, _KHE, _KSN, _KKI, ____, _K_A, _KNN, _KSA, _KTU, _KKE, _KNN, ____, _KKA, _KSN, ____, _K_A, _Ktu, _KTA, _DOT, ____
    .db     _KSO, _KNO, _KNA, ____, _KWO, ____, _KLB, _KHO, _KKU, _KTO, ____, _KSI, _KNN, _KKE, _KNN, _KRB, _EXC, _EXC, ____
    .db     _KTE, _KNN, _KKU, _K_U, ____, _KNI, ____, _KTU, _KRA, _KNA, _KRU, ____, ___7, _KTU, _KNO, ____, _KHO, _KSI, _KNO, ____, _KMO, _KTO, ____
    .db     _K_I, _Ktu, _KSI, _KSO, _K_U, _KTE, _KSN, _KNN, ____, _KNO, ____, _KHO, _KKU, _KTO, _KSI, _KNN, _KKE, _KNN, ____, _KWO, ____, _KME, _KKU, _KSN, _Ktu, _KTE, ____
    .db     _KHI, _KKE, _KSN, _KKI, ____, _KHA, ____, _KKU, _KRI, _KKA, _K_E, _KSA, _KRE, _KRU, _DOT, ____
    .db     _DOT, _DOT, _DOT, _DOT, _DOT, _DOT, ____
    .db     _KLB, _KSE, _K_I, _KKI, _KMA, _KTU, _KKI, _Kyu, _K_U, _KSE, _K_I, _KSI, _Kyu, ____, _KTE, _KSN, _KNN, _KSE, _KTU, _KRB, ____
    .db     _KYO, _KRI, ____, _KHA, _KSN, _Ktu, _KSU, _K_I, ____
    .db     _DOT, _DOT, _DOT, _DOT, _DOT, _DOT
    .db     ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____
    .db     ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____, ____
    .db     0x00

titleStringTitle:

    .db     6, 1
    .db     _LES, _LES, _LES, _LSB, ____, _KHO, _KKU, _KTO, _Ktu, _KHO, _KPS, _K_I, _K_O, _KTO, _KKO, ____, _RSB, _GRT, _GRT, _GRT, 0x00
    .db     3, 5
    .db     _KKE, _KNN, _KTA, _KRO, _K_U, ____, _KWO, _K_A, _KYA, _KTU, _Ktu, _KTE, ____, ___1, ___0, _KSI, _Kyu, _KRU, _K_I, ____, _KNO, ____, _KTE, _KKI, ____, _KTO, 0x00
    .db     11, 6
    .db     _KTA, _KTA, _KKA, _Ktu, _KTE, _KKU, _KTA, _KSN, _KSA, _K_I, _DOT, 0x00
    .db     1, 7
    .db     _KKI, _KMI, _KHA, ____, _KHO, _KKU, _KTO, _KSI, _KNN, _KKE, _KNN, ____, _KTE, _KSN, _KNN, _KSI, _Kyo, _K_U, _KSI, _Kya, ____, _KNI, ____, _KNA, _KRE, _KRU, _KKA, ____, _EXC, _EXC, 0x00
    .db     11, 10
    .db     ___K, ___E, ___Y, ____, _KNO, ____, _KSE, _KTU, _KME, _K_I, 0x00
    .db     1, 11
    .db     _BLT, _BHZ, _BRT, 0x00
    .db     1, 12
    .db     _BVT, _A_L, _BVT, ____, ____, ____, ____, _KMA, _K_E, _K_I, _KTO, _KSN, _K_U, 0x00
    .db     1, 13
    .db     _BLB, _BHZ, _BRB, 0x00
    .db     16, 11
    .db     _BLT, _BHZ, _BRT, 0x00
    .db     16, 12
    .db     _BVT, _A_R, _BVT, ____, ____, ____, ____, _K_U, _KSI, _KRO, _K_I, _KTO, _KSN, _K_U, 0x00
    .db     16, 13
    .db     _BLB, _BHZ, _BRB, 0x00
    .db     1, 14
    .db     _BLT, _BHZ, _BRT, _BLT, _BHZ, _BRT, 0x00
    .db     1, 15
    .db     _BVT, _A_L, _BVT, _BVT, _A_U, _BVT, ____, _KMA, _K_E, ___J, ___U, ___M, ___P, 0x00
    .db     1, 16
    .db     _BLB, _BHZ, _BRB, _BLB, _BHZ, _BRB, 0x00
    .db     16, 14
    .db     _BLT, _BHZ, _BRT, _BLT, _BHZ, _BRT, 0x00
    .db     16, 15
    .db     _BVT, _A_R, _BVT, _BVT, _A_U, _BVT, ____, _K_U, _KSI, _KRO, ___J, ___U, ___M, ___P, 0x00
    .db     16, 16
    .db     _BLB, _BHZ, _BRB, _BLB, _BHZ, _BRB, 0x00
    .db     1, 17
    .db     _BLT, _BHZ, _BRT, 0x00
    .db     1, 18
    .db     _BVT, ____, _BVT, ____, ____, ____, ____, _KSE, _K_I, _KKE, _KNN, _KTU, _KSN, _KKI, 0x00
    .db     1, 19
    .db     _BLB, _BHZ, _BRB, 0x00
    .db     16, 17
    .db     _BLT, _BHZ, _BRT, _BLT, _BHZ, _BRT, 0x00
    .db     16, 18
    .db     _BVT, ____, _BVT, _BVT, _A_U, _BVT, ____, _K_A, _KSI, _KKE, _KSN, _KRI, 0x00
    .db     16, 19
    .db     _BLB, _BHZ, _BRB, _BLB, _BHZ, _BRB, 0x00
    .db     1, 20
    .db     _BLT, _BHZ, _BHZ, _BHZ, _BRT, 0x00
    .db     1, 21
    .db     _BVT, ___S, ___F, ___T, _BVT, ____, ____, _KWA, _KSA, _KSN, _KWO, _KTA, _KSN, _KSU, 0x00
    .db     1, 22
    .db     _BLB, _BHZ, _BHZ, _BHZ, _BRB, 0x00
    .db     16, 20
    .db     _BLT, _BHZ, _BRT, 0x00
    .db     16, 21
    .db     _BVT, _A_D, _BVT, ____, ____, ____, ____, _KWA, _KSA, _KSN, _KWO, _KKA, _K_E, _KRU, 0x00
    .db     16, 22
    .db     _BLB, _BHZ, _BRB, ____, ____, ____, ____, _KNI, _KSI, _KSI, _KNN, _KKU, _K_U, _KHA, 0x00
    .db     0xff

; DATA 領域
;
    .area   _DATA

; 変数の定義
;

; タイトル
;
_title::

    .ds     TITLE_LENGTH

; 数値
;
titleValue:

    .ds     0x05

