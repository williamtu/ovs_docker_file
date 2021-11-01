# escape=`
# I use some of the content from:
# https://github.com/aserdean/ovs_docker_file/blob/master/Dockerfile
# and add the DPDK windows built with OVS

ARG WIN_VER="ltsc2019"
FROM mcr.microsoft.com/windows/servercore:$WIN_VER AS BUILDTOOLS

# Downloa0d VS buildtool, choco installer, and WDK
ADD https://aka.ms/vs/16/release/vs_buildtools.exe C:\TEMP\vs_buildtools.exe
ADD https://chocolatey.org/install.ps1 C:\TEMP\choco-install.ps1
ADD https://go.microsoft.com/fwlink/?linkid=2085767 C:\TEMP\wdksetup.exe

# Let's be explicit about the shell that we're going to use.
SHELL ["cmd", "/S", "/C"]

# Download pthread4w
RUN mkdir c:\pthreads
RUN powershell Invoke-WebRequest 'ftp://sourceware.org/pub/pthreads-win32/pthreads-w32-2-9-1-release.zip' -OutFile 'C:\pthreads\pthreads-win32.zip'

# Install Build Tools. A 3010 error signals that requested operation is
# successfull but changes will not be effective until the system is rebooted.
RUN C:\TEMP\vs_buildtools.exe --quiet --wait --norestart --nocache --installPath C:\BuildTools --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Workload.MSBuildTools  --add Microsoft.VisualStudio.Component.VC.Runtimes.x86.x64.Spectre --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows10SDK.18362 --add Microsoft.VisualStudio.Component.VC.14.24.x86.x64 --add Microsoft.VisualStudio.Component.VC.14.24.x86.x64.Spectre || IF "%ERRORLEVEL%"=="3010" EXIT 0

# Install choco
RUN powershell C:\TEMP\choco-install.ps1

RUN choco install git -y
#RUN choco install msys2 --params "/NoUpdate /InstallDir:C:\msys2" -y
RUN choco install python3 -y
RUN choco install 7zip.install -y

RUN 7z x C:\pthreads\pthreads-win32.zip -OC:\pthreads

# OVS build using mingw and msys2
#RUN msys2_shell.cmd -defterm -no-start -use-full-path -c "pacman --noconfirm -S automake autoconf libtool make patch"
#RUN msys2_shell.cmd -defterm -no-start -use-full-path -c "cp `which python` `which python`3"
#RUN msys2_shell.cmd -defterm -no-start -use-full-path -c "mv /usr/bin/link /usr/bin/link_bkup"
RUN python -m pip install pypiwin32 --disable-pip-version-check

# Install WDK excluding WDK.vsix.
RUN C:\TEMP\wdksetup.exe /q

# Install WDK.vsix in manual manner.
RUN copy "C:\Program Files (x86)\Windows Kits\10\Vsix\VS2019\WDK.vsix" C:\TEMP\wdkvsix.zip
RUN powershell Expand-Archive C:\TEMP\wdkvsix.zip -DestinationPath C:\TEMP\wdkvsix
RUN robocopy.exe /e "C:\temp\wdkvsix\$MSBuild\Microsoft\VC\v160" "C:\BuildTools\MSBuild\Microsoft\VC\v160" || EXIT 0

#VCRUNTIME 2010
ADD https://download.microsoft.com/download/3/2/2/3224B87F-CFA0-4E70-BDA3-3DE650EFEBA5/vcredist_x64.exe C:\TEMP\vc_2010_x64.exe
RUN C:\TEMP\vc_2010_x64.exe /quiet /install

RUN choco install meson -y
RUN choco install llvm -y
RUN choco install pkgconfiglite -y
RUN choco install ctags -y

# ------------------- DPDK BUILD ----------------------
FROM BUILDTOOLS AS DPDK-BUILD 
# checkout DPDK commit e9123c467dbb due to API breakage on latest main
RUN cd C:\ && git clone --branch main https://dpdk.org/git/dpdk
RUN cd C:\dpdk && git checkout -b ovs-dpdk e9123c467dbb && meson build && ninja -C build

# Build netuio and virtio 
RUN cd C:\ && git clone git://dpdk.org/dpdk-kmods
RUN cd C:\dpdk-kmods\windows\netuio && c:\\BuildTools\\VC\\Auxiliary\\Build\\vcvarsall.bat x86_x64 10.0.18362.0 && msbuild
RUN cd C:\dpdk-kmods\windows\virt2phys && c:\\BuildTools\\VC\\Auxiliary\\Build\\vcvarsall.bat x86_x64 10.0.18362.0 && msbuild

# ------------------- OVS-DPDK BUILD ----------------------
FROM DPDK-BUILD AS OVS-DPDK-BUILD
# clone OVS
RUN cd C:\ && git clone --branch rfc1 https://github.com/smadaminov/ovs-dpdk-meson-issues.git

# install dpdk
RUN mkdir C:\TEMP\dpdk && powershell "$Env:DESTDIR=\"C:\TEMP\dpdk\"; cd C:\dpdk\; ninja -C build install"

# install pthread4w
RUN cd C:\ && git clone https://git.code.sf.net/p/pthreads4w/code pthreads4w-code && cd pthreads4w-code && C:\\BuildTools\\VC\\Auxiliary\\Build\\vcvarsall.bat x86_x64 10.0.18362.0 && nmake all install

RUN choco install vim -y

# OVS needs to use meson 0.59.2
RUN pip3 install meson==0.59.2 --user -U
RUN powershell New-Item -Type symbolicLink -Path C:\meson59.exe -value C:\Users\ContainerAdministrator\AppData\Roaming\Python\Python310\Scripts\meson.exe
RUN powershell "(Get-Content c:\PTHREADS-BUILT\include\_ptw32.h).replace('error \"Please upgrade', 'warning \"Please upgrade') | Set-Content c:\PTHREADS-BUILT\include\_ptw32.h"
RUN cd C:\ovs-dpdk-meson-issues\ovs && C:\meson59.exe build -Dwith-pthread=C:\PTHREADS-BUILT -Dwith-dpdk=C:\temp\dpdk\ -Dpkg_config_path=C:\temp\dpdk\lib\pkgconfig\ && ninja -C build 

SHELL ["cmd"]

CMD [ "cmd","/k","c:\\BuildTools\\VC\\Auxiliary\\Build\\vcvarsall.bat", "x86_x64", "10.0.18362.0", "&&", "msys2_shell.cmd", "-no-start", "-defterm", "-msys2", "-use-full-path" ]
