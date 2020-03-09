1. Build image:
```
PS C:\Users\User\test> docker build .
```
```
Sending build context to Docker daemon  4.608kB
Step 1/27 : ARG WIN_VER="ltsc2019"
Step 2/27 : FROM mcr.microsoft.com/windows/servercore:$WIN_VER
 ---> 81094f2483ae
Step 3/27 : ADD https://aka.ms/vs/16/release/vs_buildtools.exe C:\TEMP\vs_buildtools.exe
Downloading [==================================================>]  1.383MB/1.383MB

 ---> Using cache
 ---> d23d523dbaef
Step 4/27 : ADD https://chocolatey.org/install.ps1 C:\TEMP\choco-install.ps1
Downloading  22.66kB

 ---> Using cache
 ---> 6f53490a1af9
Step 5/27 : ADD https://go.microsoft.com/fwlink/?linkid=2085767 C:\TEMP\wdksetup.exe
Downloading [==================================================>]  1.321MB/1.321MB
 ---> Using cache
 ---> 984aab4b734f
Step 6/27 : SHELL ["cmd", "/S", "/C"]
 ---> Using cache
 ---> 557d9543e8bd
Step 7/27 : RUN mkdir c:\pthreads
 ---> Using cache
 ---> 2e20bab4c16c
Step 8/27 : RUN powershell Invoke-WebRequest 'ftp://sourceware.org/pub/pthreads-win32/pthreads-w32-2-9-1-release.zip' -OutFile 'C:\pthreads\pthreads-win32.zip'
 ---> Using cache
 ---> 7667016f7dfe
Step 9/27 : RUN C:\TEMP\vs_buildtools.exe --quiet --wait --norestart --nocache     --installPath C:\BuildTools     --add Microsoft.VisualStudio.Workload.VCTools     --add Microsoft.VisualStudio.Workload.MSBuildTools     --add Microsoft.VisualStudio.Component.VC.Runtimes.x86.x64.Spectre     --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64     --add Microsoft.VisualStudio.Component.Windows10SDK.18362     --add Microsoft.VisualStudio.Component.VC.14.24.x86.x64     --add Microsoft.VisualStudio.Component.VC.14.24.x86.x64.Spectre  || IF "%ERRORLEVEL%"=="3010" EXIT 0
 ---> Using cache
 ---> f27366570af7
Step 10/27 : RUN powershell C:\TEMP\choco-install.ps1
 ---> Using cache
 ---> 6741deb304f8
Step 11/27 : RUN choco install git -y
 ---> Using cache
 ---> 609124e55e4a
Step 12/27 : RUN choco install msys2 --params "/NoUpdate /InstallDir:C:\msys2" -y
 ---> Using cache
 ---> 024643daf485
Step 13/27 : RUN choco install python3 -y
 ---> Using cache
 ---> e512038b0ebd
Step 14/27 : RUN choco install 7zip.install -y
 ---> Using cache
 ---> 8c6e1ef4f6ce
Step 15/27 : RUN 7z x C:\pthreads\pthreads-win32.zip -OC:\pthreads
 ---> Using cache
 ---> 64f140fa2242
Step 16/27 : RUN msys2_shell.cmd -defterm -no-start -use-full-path -c "pacman --noconfirm -S automake autoconf libtool make patch"
 ---> Using cache
 ---> 244fe9f1fe7c
Step 17/27 : RUN msys2_shell.cmd -defterm -no-start -use-full-path -c "cp `which python` `which python`3"
 ---> Using cache
 ---> 3439143ec47d
Step 18/27 : RUN msys2_shell.cmd -defterm -no-start -use-full-path -c "mv /usr/bin/link /usr/bin/link_bkup"
 ---> Using cache
 ---> 7324b5c70b1e
Step 19/27 : RUN python3 -m pip install pypiwin32 --disable-pip-version-check
 ---> Using cache
 ---> c323ef54a268
Step 20/27 : RUN C:\TEMP\wdksetup.exe /q
 ---> Using cache
 ---> d8982c3e773d
Step 21/27 : RUN copy "C:\Program Files (x86)\Windows Kits\10\Vsix\VS2019\WDK.vsix" C:\TEMP\wdkvsix.zip
 ---> Using cache
 ---> c40c75de198c
Step 22/27 : RUN powershell Expand-Archive C:\TEMP\wdkvsix.zip -DestinationPath C:\TEMP\wdkvsix
 ---> Using cache
 ---> a8b4119f0be2
Step 23/27 : RUN robocopy.exe /e "C:\temp\wdkvsix\$MSBuild\Microsoft\VC\v160" "C:\BuildTools\MSBuild\Microsoft\VC\v160" || EXIT 0
 ---> Using cache
 ---> 9e99ba20da7b
Step 24/27 : ADD https://download.microsoft.com/download/3/2/2/3224B87F-CFA0-4E70-BDA3-3DE650EFEBA5/vcredist_x64.exe C:\TEMP\vc_2010_x64.exe
Downloading [==================================================>]  5.719MB/5.719MB
 ---> Using cache
 ---> 34e917c22b7d
Step 25/27 : RUN C:\TEMP\vc_2010_x64.exe /quiet /install
 ---> Using cache
 ---> 75a4a4e3d21e
Step 26/27 : SHELL ["cmd"]
 ---> Using cache
 ---> 34ef52ef29f8
Step 27/27 : CMD [ "cmd","/k","c:\\BuildTools\\VC\\Auxiliary\\Build\\vcvarsall.bat", "x86_x64", "10.0.18362.0", "&&", "msys2_shell.cmd", "-no-start", "-defterm", "-msys2", "-use-full-path" ]
 ---> Using cache
 ---> e696c240e60d
Successfully built e696c240e60d
```

2. Run container based on that image:
```
PS C:\Users\User\test> docker run -it e696c240e60d
```

3. Clone and build OVS
```
# git clone https://github.com/openvswitch/ovs && cd ovs
# ./boot.sh && ./configure CC=./build-aux/cccl LD="$(which link)"     LIBS="-lws2_32 -lShlwapi -liphlpapi -lwbemuuid -lole32 -loleaut32"     --prefix="C:/openvswitch/usr"     --localstatedir="C:/openvswitch/var"     --sysconfdir="C:/openvswitch/etc"     --with-pthread="c:/pthreads/Pre-built.2/" --with-vstudiotargetver="Win10" && make -j8
```
