@echo off
setlocal ENABLEDELAYEDEXPANSION

REM ================================================
REM gen_pb.bat —— 一键生成 all.pb
REM 放置位置：项目根目录（与 Assets、Tools 同级）
REM ================================================

REM 1️⃣ 定位项目根（脚本自身所在目录）
set "PROJECT_ROOT=%~dp0"

REM 2️⃣ 配置 protoc 可执行文件路径
set "PROTOC=%PROJECT_ROOT%Tools\protoc-31.0-win64\bin\protoc.exe"

REM 3️⃣ 配置 .proto 源文件夹和输出文件
set "PROTO_DIR=%PROJECT_ROOT%Assets\3rd\Proto"
set "OUT_FILE=%PROJECT_ROOT%Assets\StreamingAssets\Proto\all.pb"

echo [DEBUG] PROJECT_ROOT = %PROJECT_ROOT%
echo [DEBUG] PROTOC       = %PROTOC%
echo [DEBUG] PROTO_DIR    = %PROTO_DIR%
echo [DEBUG] OUT_FILE     = %OUT_FILE%
echo.

REM 4️⃣ 检查 protoc 是否存在
if not exist "%PROTOC%" (
  echo [ERROR] protoc.exe not found at %PROTOC%
  pause
  exit /b 1
)

REM 5️⃣ 确保输出目录存在
if not exist "%PROJECT_ROOT%Assets\StreamingAssets\Proto" (
  mkdir "%PROJECT_ROOT%Assets\StreamingAssets\Proto"
)

REM 6️⃣ 调用 protoc 一次性把所有 .proto 编译到 all.pb
echo Generating descriptor set to %OUT_FILE% ...
"%PROTOC%" ^
  --proto_path="%PROTO_DIR%" ^
  --include_imports ^
  --descriptor_set_out="%OUT_FILE%" ^
  "%PROTO_DIR%\*.proto"

if errorlevel 1 (
  echo [ERROR] protoc failed
  pause
  exit /b 1
)

echo [OK] Generated %OUT_FILE%
pause
