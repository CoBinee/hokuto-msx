; Sound.inc : サウンド
;


; マクロの定義
;

; BGM
SOUND_BGM_NULL                  =   0x00

; SE
SOUND_SE_NULL                   =   0x00
SOUND_SE_BOOT                   =   0x01
SOUND_SE_CLICK                  =   0x02
SOUND_SE_ATTACK                 =   0x03
SOUND_SE_DAMAGE                 =   0x04
SOUND_SE_GUARD                  =   0x05

; 外部関数宣言
;

    .globl  _SoundPlayBgm
    .globl  _SoundPlaySe
    .globl  _SoundStop
    .globl  _SoundIsPlayBgm
    .globl  _SoundIsPlaySe

; 外部変数宣言
;
