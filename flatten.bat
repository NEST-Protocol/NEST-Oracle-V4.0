@echo off
set /a tm1=%time:~0,2%*1
if %tm1% LSS 10 set tm1=0%tm1%
set dir=%date:~0,4%%date:~5,2%%date:~8,2%%tm1%%tm2%%tm3%%time:~3,2%%time:~6,2%

echo 创建文件夹: opensrc\%dir%\
mkdir opensrc\%dir%\

cd contracts
for %%i in (*.sol) do ( 
echo 处理: %%i 
npx hardhat flatten %%i > ..\opensrc\%dir%\%%i
dotnet.exe ..\opensrc\replace.dll "..\opensrc\%dir%\%%i" "..\opensrc\%dir%\%%i" "// SPDX-License-Identifier:" "//" 9
)

echo %dir%
pause