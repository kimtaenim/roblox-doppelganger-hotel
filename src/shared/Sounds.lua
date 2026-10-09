-- 배경 소리 번호 목록이에요.
-- 소리마다 후보를 여러 개 적어 두면, 앞에서부터 재생되는 첫 번째 번호를 써요.
-- 바꾸고 싶으면: Studio 도구 상자(Toolbox) → 마켓 → 오디오에서 소리를 찾고,
-- 오른쪽 클릭 → "자산 ID 복사" 한 번호를 "rbxassetid://번호" 모양으로 맨 앞에 넣으면 돼요.
return {
	ClockTick = { "rbxassetid://8966275754", "rbxassetid://850256806", "rbxassetid://13689969462", "rbxassetid://72673807427497" },
	Owl = { "rbxassetid://138183136" },
	Bat = { "rbxassetid://6136804563" },
	ElevatorDing = { "rbxassetid://7527328153", "rbxassetid://4462044869", "rbxassetid://237877850" },
	Scream = { "rbxassetid://6754147732", "rbxassetid://6150329916", "rbxassetid://7152458214", "rbxassetid://8819324666" },
	PoliceSiren = { "rbxassetid://1555732147", "rbxassetid://2195502769", "rbxassetid://156721873", "rbxassetid://175964948" },
	-- 야간 순찰 배경음악 : assets 폴더의 wav 파일을 Studio에서 올린 뒤 번호를 넣어 주세요.
	-- (Studio 위쪽 [창] → 자산 관리자 → 가져오기 → 파일 선택 → 올라간 오디오를 오른쪽 클릭 → "자산 ID 복사")
	MarimbaNote = {}, -- assets/marimba_C5.wav (마림바 "도" 한 음)
	RadioStatic = {}, -- assets/radio_static.wav (무전기 지직 소리, 반복)
}
