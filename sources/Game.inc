; Game.inc : ゲーム
;


; マクロの定義
;

; スプライト
GAME_SPRITE_NULL                =   0x00
GAME_SPRITE_PLAYER              =   0x00
GAME_SPRITE_ENEMY               =   0x20

; ゲーム
GAME_PROC_L                     =   0x00
GAME_PROC_H                     =   0x01
GAME_STATE                      =   0x02
GAME_FLAG                       =   0x03
GAME_FRAME                      =   0x04
GAME_COUNT                      =   0x05
GAME_SCORE_L                    =   0x06
GAME_SCORE_H                    =   0x07
GAME_LENGTH                     =   0x08

; 処理
GAME_PROC_NULL                  =   0x00

; 状態
GAME_STATE_NULL                 =   0x00

; フラグ
GAME_FLAG_NULL                  =   0x00

; フレーム
GAME_FRAME_NULL                 =   0x00

; カウント
GAME_COUNT_NULL                 =   0x00

; スコア
GAME_SCORE_NULL                 =   0x00
GAME_SCORE_MAXIMUM              =   9999
GAME_SCORE_SEIKENDUKI           =   1
GAME_SCORE_ASHIGERI             =   2
GAME_SCORE_GUARD                =   5
GAME_SCORE_WIN                  =   10

; 外部関数宣言
;

    .globl  _GameInitialize
    .globl  _GameUpdate
    .globl  _GameGetScore
    .globl  _GameAddScore
    .globl  _GameGetSpeechPosition
    .globl  _GamePrintString
    .globl  _GamePrintValue
    .globl  _GamePrintPattern
    
; 外部変数宣言
;

    .globl  _game
