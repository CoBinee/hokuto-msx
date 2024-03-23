; Title.inc : タイトル
;


; マクロの定義
;

; スプライト
TITLE_SPRITE_NULL               =   0x00

; タイトル
TITLE_PROC_L                    =   0x00
TITLE_PROC_H                    =   0x01
TITLE_STATE                     =   0x02
TITLE_FLAG                      =   0x03
TITLE_FRAME                     =   0x04
TITLE_COUNT                     =   0x05
TITLE_ANIMATION                 =   0x06
TITLE_LENGTH                    =   0x07

; 処理
TITLE_PROC_NULL                 =   0x00

; 状態
TITLE_STATE_NULL                =   0x00

; フラグ
TITLE_FLAG_NULL                 =   0x00

; フレーム
TITLE_FRAME_NULL                =   0x00

; カウント
TITLE_COUNT_NULL                =   0x00

; アニメーション
TITLE_ANIMATION_NULL            =   0x00

; 外部関数宣言
;

    .globl  _TitleInitialize
    .globl  _TitleUpdate
    
; 外部変数宣言
;

    .globl  _title
