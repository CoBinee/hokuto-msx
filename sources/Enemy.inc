; Enemy.inc : エネミー
;


; マクロの定義
;

; エネミー
ENEMY_TYPE                      =   0x00
ENEMY_PROC_L                    =   0x01
ENEMY_PROC_H                    =   0x02
ENEMY_STATE                     =   0x03
ENEMY_FLAG                      =   0x04
ENEMY_POSITION_X                =   0x05
ENEMY_POSITION_Y                =   0x06
ENEMY_LIFE_L                    =   0x07
ENEMY_LIFE_H                    =   0x08
ENEMY_ATTACK                    =   0x09
ENEMY_ANIMATION                 =   0x0a
ENEMY_PATTERN_L                 =   0x0b
ENEMY_PATTERN_H                 =   0x0c
ENEMY_SPEECH_L                  =   0x0d
ENEMY_SPEECH_H                  =   0x0e
ENEMY_SPEECH_X                  =   0x0f
ENEMY_SPEECH_Y                  =   0x10
ENEMY_TALK_L                    =   0x11
ENEMY_TALK_H                    =   0x12
ENEMY_ARROW_X                   =   0x13
ENEMY_ARROW_Y                   =   0x14
ENEMY_WAVE_X                    =   0x15
ENEMY_WAVE_Y                    =   0x16
ENEMY_WAVE_SIZE                 =   0x17
ENEMY_LENGTH                    =   0x18

; 種類
ENEMY_TYPE_NULL                 =   0x00
ENEMY_TYPE_SHITAPPA             =   0x01
ENEMY_TYPE_SPADE                =   0x02
ENEMY_TYPE_DIA                  =   0x03
ENEMY_TYPE_CLUB                 =   0x04
ENEMY_TYPE_HEART                =   0x05
ENEMY_TYPE_REI                  =   0x06
ENEMY_TYPE_JAGI                 =   0x07
ENEMY_TYPE_JUDA                 =   0x08
ENEMY_TYPE_SHEW                 =   0x09
ENEMY_TYPE_RAOH                 =   0x0a

; 処理
ENEMY_PROC_NULL                 =   0x00

; 状態
ENEMY_STATE_NULL                =   0x00

; フラグ
ENEMY_FLAG_NULL                 =   0x00
ENEMY_FLAG_ACTIVE_BIT           =   0x00
ENEMY_FLAG_ACTIVE               =   (1 << ENEMY_FLAG_ACTIVE_BIT)
ENEMY_FLAG_HIT_BIT              =   0x01
ENEMY_FLAG_HIT                  =   (1 << ENEMY_FLAG_HIT_BIT)
ENEMY_FLAG_ARROW_BIT            =   0x02
ENEMY_FLAG_ARROW                =   (1 << ENEMY_FLAG_ARROW_BIT)
ENEMY_FLAG_WAVE_BIT             =   0x03
ENEMY_FLAG_WAVE                 =   (1 << ENEMY_FLAG_WAVE_BIT)

; 位置
ENEMY_POSITION_NULL             =   0x00

; 体力
ENEMY_LIFE_NULL                 =   0x00

; 攻撃方法
ENEMY_ATTACK_NULL               =   0x00
ENEMY_ATTACK_ARROW              =   0x01
ENEMY_ATTACK_NANTO              =   0x02
ENEMY_ATTACK_HOKUTO             =   0x03
ENEMY_ATTACK_HIKO               =   0x04

; アニメーション
ENEMY_ANIMATION_NULL            =   0x00
ENEMY_ANIMATION_WALK            =   0x21
ENEMY_ANIMATION_ATTACK          =   0x10
ENEMY_ANIMATION_SPECIAL         =   0x08
ENEMY_ANIMATION_DAMAGE          =   0x08
ENEMY_ANIMATION_DOWN            =   0x80
ENEMY_ANIMATION_BOMB            =   0x80
ENEMY_ANIMATION_SPEECH          =   0x40
ENEMY_ANIMATION_SILENT          =   0x30

; パターン
ENEMY_PATTERN_NULL              =   0x00
ENEMY_PATTERN_STAND             =   0x00
ENEMY_PATTERN_HIKO_0            =   0x01
ENEMY_PATTERN_HIKO_1            =   0x02
ENEMY_PATTERN_HIKO_2            =   0x03
ENEMY_PATTERN_HIKO_3            =   0x04
ENEMY_PATTERN_HIKO_4            =   0x05
ENEMY_PATTERN_HYAKURETSUKEN_0   =   0x06
ENEMY_PATTERN_HYAKURETSUKEN_1   =   0x07
ENEMY_PATTERN_JUHAZAN_0         =   0x08
ENEMY_PATTERN_JUHAZAN_1         =   0x09

; 台詞
ENEMY_SPEECH_NULL               =   0x00

; 会話
ENEMY_TALK_NULL                 =   0x00
ENEMY_TALK_OWNER                =   0x01
ENEMY_TALK_OTHER                =   0x02
ENEMY_TALK_SILENT               =   0x03

; 矢
ENEMY_ARROW_NULL                =   0x00

; 衝撃波
ENEMY_WAVE_NULL                 =   0x00
ENEMY_WAVE_SIZE_MAX             =   0x0a

; 外部関数宣言
;

    .globl  _EnemyInitialize
    .globl  _EnemyUpdate
    .globl  _EnemyRender
    .globl  _EnemyMove
    .globl  _EnemyGetType
    .globl  _EnemyGetNameString
    .globl  _EnemyGetLife
    .globl  _EnemyGetAttack
    .globl  _EnemySetPattern
    .globl  _EnemyClearSpeech
    .globl  _EnemySetSpeech
    .globl  _EnemyLock
    .globl  _EnemyUnlock
    .globl  _EnemyHit
    .globl  _EnemyTakeDamage
    .globl  _EnemyTakeSpecial

; 外部変数宣言
;

    .globl  _enemy
