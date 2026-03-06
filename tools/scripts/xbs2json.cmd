@echo off
setlocal
if "%~2"=="" (
  echo Usage: %~nx0 ^<input.xbs^> ^<output.json^>
  exit /b 1
)
python "%~dp0xbs_tool.py" xbs2json -i "%~1" -o "%~2"
endlocal
