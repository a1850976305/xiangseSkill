@echo off
setlocal
if "%~2"=="" (
  echo Usage: %~nx0 ^<input.json^> ^<output_prefix^>
  exit /b 1
)
python "%~dp0xbs_tool.py" roundtrip -i "%~1" -p "%~2"
endlocal
