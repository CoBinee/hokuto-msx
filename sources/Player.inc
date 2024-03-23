; Player.inc : プレイヤ
;


; マクロの定義
;

; プレイヤ
PLAYER_PROC_L                   =   0x00
PLAYER_PROC_H                   =   0x01
PLAYER_STATE                    =   0x02
PLAYER_FLAG                     =   0x03
PLAYER_POSITION_X               =   0x04
PLAYER_POSITION_Y               =   0x05
PLAYER_LIFE_L                   =   0x06
PLAYER_LIFE_H                   =   0x07
PLAYER_POWER                    =   0x08
PLAYER_SPECIAL                  =   0x09
PLAYER_GUARD                    =   0x0a
PLAYER_DAMAGE                   =   0x0b
PLAYER_ANIMATION                =   0x0c
PLAYER_PATTERN_L                =   0x0d
PLAYER_PATTERN_H                =   0x0e
PLAYER_SPEECH_L                 =   0x0f
PLAYER_SPEECH_H                 =   0x10
PLAYER_SPEECH_X                 =   0x11
PLAYER_SPEECH_Y                 =   0x12
PLAYER_TALK_L                   =   0x13
PLAYER_TALK_H                   =   0x14
PLAYER_PARAM_0                  =   0x15
PLAYER_PARAM_1                  =   0x16
PLAYER_PARAM_2                  =   0x17
PLAYER_PARAM_3                  =   0x18
PLAYER_LENGTH                   =   0x19

; 処理
PLAYER_PROC_NULL                =   0x00

; 状態
PLAYER_STATE_NULL               =   0x00

; フラグ
PLAYER_FLAG_NULL                =   0x00
PLAYER_FLAG_ACTIVE_BIT          =   0x00
PLAYER_FLAG_ACTIVE              =   (1 << PLAYER_FLAG_ACTIVE_BIT)
PLAYER_FLAG_HIT_BIT             =   0x01
PLAYER_FLAG_HIT                 =   (1 << PLAYER_FLAG_HIT_BIT)
PLAYER_FLAG_DEAD_BIT            =   0x07
PLAYER_FLAG_DEAD                =   (1 << PLAYER_FLAG_DEAD_BIT)

; 位置
PLAYER_POSITION_NULL            =   0x00

; 体力
PLAYER_LIFE_NULL                =   0x00

; 力
PLAYER_POWER_NULL               =   0x00
PLAYER_POWER_MAXIMUM            =   0x07

; 技
PLAYER_SPECIAL_NULL             =   0x00
PLAYER_SPECIAL_HIKO             =   0x00
PLAYER_SPECIAL_ZANKAIKEN        =   0x01
PLAYER_SPECIAL_HYAKURETSUKEN    =   0x02
PLAYER_SPECIAL_HAGANKEN         =   0x03
PLAYER_SPECIAL_KAIKOTSUKEN      =   0x04
PLAYER_SPECIAL_JUHAZAN          =   0x05
PLAYER_SPECIAL_LENGTH           =   0x06

; 防御
PLAYER_GUARD_NULL               =   0xff
PLAYER_GUARD_FRAME              =   0x05

; ダメージ
PLAYER_DAMAGE_NULL              =   0x00

; アニメーション
PLAYER_ANIMATION_NULL           =   0x00
PLAYER_ANIMATION_JUMP           =   0x0c
PLAYER_ANIMATION_LAND           =   0x04
PLAYER_ANIMATION_ATTACK         =   0x08
PLAYER_ANIMATION_DAMAGE         =   0x10
PLAYER_ANIMATION_DEAD           =   0x20
PLAYER_ANIMATION_SPEECH         =   0x40
PLAYER_ANIMATION_SILENT         =   0x30

; パターン
PLAYER_PATTERN_NULL             =   0x00

; 台詞
PLAYER_SPEECH_NULL              =   0x00

; 会話
PLAYER_TALK_NULL                =   0x00
PLAYER_TALK_OWNER               =   0x01
PLAYER_TALK_OTHER               =   0x02
PLAYER_TALK_SILENT              =   0x03

; パラメータ
PLAYER_PARAM_NULL               =   0x00

; 外部関数宣言
;

    .globl  _PlayerInitialize
    .globl  _PlayerUpdate
    .globl  _PlayerRender
    .globl  _PlayerMove
    .globl  _PlayerGetLife
    .globl  _PlayerGetDistance
    .globl  _PlayerGetSpecialString
    .globl  _PlayerClearSpeech
    .globl  _PlayerSetSpeech
    .globl  _PlayerLock
    .globl  _PlayerUnlock
    .globl  _PlayerHit
    .globl  _PlayerGuard
    .globl  _PlayerTakeDamage
    .globl  _PlayerIsDead

; 外部変数宣言
;

    .globl  _player
