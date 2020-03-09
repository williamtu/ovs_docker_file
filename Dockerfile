# escape=`

ARG WIN_VER="ltsc2019"

FROM mcr.microsoft.com/windows/servercore:$WIN_VER

ADD https://aka.ms/vs/16/release/vs_buildtools.exe C:\TEMP\vs_buildtools.exe
ADD https://chocolatey.org/install.ps1 C:\TEMP\choco-install.ps1
ADD https://go.microsoft.com/fwlink/?linkid=2085767 C:\TEMP\wdksetup.exe

# Let's be explicit about the shell that we're going to use.
SHELL ["cmd", "/S", "/C"]
RUN mkdir c:\pthreads
RUN powershell Invoke-WebRequest 'ftp://sourceware.org/pub/pthreads-win32/pthreads-w32-2-9-1-release.zip' -OutFile 'C:\pthreads\pthreads-win32.zip'

# Install Build Tools. A 3010 error signals that requested operation is
# successfull but changes will not be effective until the system is rebooted.
RUN C:\TEMP\vs_buildtools.exe --quiet --wait --norestart --nocache `
    --installPath C:\BuildTools `
    --add Microsoft.VisualStudio.Workload.VCTools `
    --add Microsoft.VisualStudio.Workload.MSBuildTools `
    --add Microsoft.VisualStudio.Component.VC.Runtimes.x86.x64.Spectre `
    --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
    --add Microsoft.VisualStudio.Component.Windows10SDK.18362 `
    --add Microsoft.VisualStudio.Component.VC.14.24.x86.x64 `
    --add Microsoft.VisualStudio.Component.VC.14.24.x86.x64.Spectre `
 || IF "%ERRORLEVEL%"=="3010" EXIT 0

RUN powershell C:\TEMP\choco-install.ps1

RUN choco install git -y
RUN choco install msys2 --params "/NoUpdate /InstallDir:C:\msys2" -y
RUN choco install python3 -y
RUN choco install 7zip.install -y

RUN 7z x C:\pthreads\pthreads-win32.zip -OC:\pthreads

RUN msys2_shell.cmd -defterm -no-start -use-full-path -c "pacman --noconfirm -S automake autoconf libtool make patch"
RUN msys2_shell.cmd -defterm -no-start -use-full-path -c "cp `which python` `which python`3"
RUN msys2_shell.cmd -defterm -no-start -use-full-path -c "mv /usr/bin/link /usr/bin/link_bkup"
RUN python3 -m pip install pypiwin32 --disable-pip-version-check

# Install WDK excluding WDK.vsix.
RUN C:\TEMP\wdksetup.exe /q

# Install WDK.vsix in manual manner.
RUN copy "C:\Program Files (x86)\Windows Kits\10\Vsix\VS2019\WDK.vsix" C:\TEMP\wdkvsix.zip
RUN powershell Expand-Archive C:\TEMP\wdkvsix.zip -DestinationPath C:\TEMP\wdkvsix
RUN robocopy.exe /e "C:\temp\wdkvsix\$MSBuild\Microsoft\VC\v160" "C:\BuildTools\MSBuild\Microsoft\VC\v160" || EXIT 0

#VCRUNTIME 2010
ADD https://download.microsoft.com/download/3/2/2/3224B87F-CFA0-4E70-BDA3-3DE650EFEBA5/vcredist_x64.exe C:\TEMP\vc_2010_x64.exe
RUN C:\TEMP\vc_2010_x64.exe /quiet /install

SHELL ["cmd"]

CMD [ "cmd","/k","c:\\BuildTools\\VC\\Auxiliary\\Build\\vcvarsall.bat", "x86_x64", "10.0.18362.0", "&&", "msys2_shell.cmd", "-no-start", "-defterm", "-msys2", "-use-full-path" ]
