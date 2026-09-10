class_name MorseCode
extends RefCounted


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


## 符号を文字化する。[br]
## 出来ない場合は空文字を返す。
static func decode(code: int) -> String:
	return MORSE_TABLE.get(code, "")


## 文字を符号化可能か。
static func can_encode(character: String) -> bool:
	return MORSE_TABLE.values().has(character.to_upper())


## 文字を符号化。[br]
## 存在しない場合、0を返す。
static func encode(character: String) -> int:
	var normalized := character.to_upper()
	for code: int in MORSE_TABLE:
		if MORSE_TABLE[code] == normalized:
			return code
	return 0
