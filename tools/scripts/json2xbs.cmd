@echo off
setlocal
if "%~2"=="" (
  echo Usage: %~nx0 ^<input.json^> ^<output.xbs^>
  exit /b 1
)
python "%~dp0xbs_tool.py" json2xbs -i "%~1" -o "%~2"
endlocal
