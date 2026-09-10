class_name MorseCode
extends RefCounted


## 先頭の番兵ビットに短点を0、長点を1として連結した符号と英数字の対応表。
const MORSE_TABLE: Dictionary[int, String] = {
	0b1_0: "E",
	0b1_1: "T",
			
	0b1_00: "I",
	0b1_01: "A",
			
	0b1_10: "N",
	0b1_11: "M",
			
	0b1_000: "S",
	0b1_001: "U",
	0b1_010: "R",
	0b1_011: "W",
			
	0b1_100: "D",
	0b1_101: "K",
	0b1_110: "G",
	0b1_111: "O",
			
	0b1_0000: "H",
	0b1_0001: "V",
	0b1_0010: "F",
	0b1_0100: "L",
	0b1_0110: "P",
	0b1_0111: "J",
			
	0b1_1000: "B",
	0b1_1001: "X",
	0b1_1010: "C",
	0b1_1100: "Z",
	0b1_1011: "Y",
	0b1_1101: "Q",
			
	0b1_11111: "0",
	0b1_01111: "1",
	0b1_00111: "2",
	0b1_00011: "3",
	0b1_00001: "4",
	0b1_00000: "5",
	0b1_10000: "6",
	0b1_11000: "7",
	0b1_11100: "8",
	0b1_11110: "9",
}


## [param code] のモールス符号に対応する英数字を返す。
## 対応する文字がない場合は空文字を返す。
static func decode(code: int) -> String:
	return MORSE_TABLE.get(code, "")


## [param character] を大文字の英数字としてモールス符号化できるかを返す。
static func can_encode(character: String) -> bool:
	return MORSE_TABLE.values().has(character.to_upper())


## [param character] を大文字として扱い、対応するモールス符号へ変換する。
## 対応する符号が存在しない場合は0を返す。
static func encode(character: String) -> int:
	var normalized := character.to_upper()
	for code: int in MORSE_TABLE:
		if MORSE_TABLE[code] == normalized:
			return code
	return 0
