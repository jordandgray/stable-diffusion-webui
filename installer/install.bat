@echo off

@rem This script will install git and conda (if not found on the PATH variable)
@rem  using micromamba (an 8mb static-linked single-file binary, conda replacement).
@rem For users who already have git and conda, this step will be skipped.

@rem Then, it'll run the webui.cmd file to continue with the installation as usual.

@rem This enables a user to install this project without manually installing conda and git.

echo "Installing Sygil WebUI.."
echo.

@rem config
set MAMBA_ROOT_PREFIX=%cd%\installer_files\mamba
set INSTALL_ENV_DIR=%cd%\installer_files\env
set MICROMAMBA_DOWNLOAD_URL=https://github.com/cmdr2/stable-diffusion-ui/releases/download/v1.1/micromamba.exe
set REPO_URL=https://github.com/Sygil-Dev/sygil-webui.git
@rem Change the download URL to Sygil repo's release URL
@rem We need to mirror micromamba.exe, because the official download URL uses tar.bz2 compression
@rem  which Windows can't unzip natively.
@rem https://mamba.readthedocs.io/en/latest/installation.html#windows
set umamba_exists=F

@rem figure out whether git and conda needs to be installed
if exist "%INSTALL_ENV_DIR%" set PATH=%INSTALL_ENV_DIR%;%INSTALL_ENV_DIR%\Library\bin;%INSTALL_ENV_DIR%\Scripts;%INSTALL_ENV_DIR%\Library\usr\bin;%PATH%

set PACKAGES_TO_INSTALL=

call conda --version >.tmp1 2>.tmp2
if "%ERRORLEVEL%" NEQ "0" set PACKAGES_TO_INSTALL=%PACKAGES_TO_INSTALL% conda

call git --version >.tmp1 2>.tmp2
if "%ERRORLEVEL%" NEQ "0" set PACKAGES_TO_INSTALL=%PACKAGES_TO_INSTALL% git

call "%MAMBA_ROOT_PREFIX%\micromamba.exe" --version >.tmp1 2>.tmp2
if "%ERRORLEVEL%" EQU "0" set umamba_exists=T

@rem (if necessary) install git and conda into a contained environment
if "%PACKAGES_TO_INSTALL%" NEQ "" (
    @rem download micromamba
    if "%umamba_exists%" == "F" (
        echo "Downloading micromamba from %MICROMAMBA_DOWNLOAD_URL% to %MAMBA_ROOT_PREFIX%\micromamba.exe"

        mkdir "%MAMBA_ROOT_PREFIX%"
        call curl -L "%MICROMAMBA_DOWNLOAD_URL%" > "%MAMBA_ROOT_PREFIX%\micromamba.exe"

        @rem test the mamba binary
        echo Micromamba version:
        call "%MAMBA_ROOT_PREFIX%\micromamba.exe" --version
    )

    @rem create the installer env
    if not exist "%INSTALL_ENV_DIR%" (
        call "%MAMBA_ROOT_PREFIX%\micromamba.exe" create -y --prefix "%INSTALL_ENV_DIR%"
    )

    echo "Packages to install:%PACKAGES_TO_INSTALL%"

    call "%MAMBA_ROOT_PREFIX%\micromamba.exe" install -y --prefix "%INSTALL_ENV_DIR%" -c conda-forge %PACKAGES_TO_INSTALL%

    if not exist "%INSTALL_ENV_DIR%" (
        echo "There was a problem while installing%PACKAGES_TO_INSTALL% using micromamba. Cannot continue."
        pause
        exit /b
    )
)

set PATH=%INSTALL_ENV_DIR%;%INSTALL_ENV_DIR%\Library\bin;%INSTALL_ENV_DIR%\Scripts;%INSTALL_ENV_DIR%\Library\usr\bin;%PATH%

@rem get the repo (and load into the current directory)
if not exist ".git" (
    call git config --global init.defaultBranch master
    call git init
    call git remote add origin %REPO_URL%
    call git fetch
    call git checkout origin/master -ft
)

@rem activate the base env
call conda activate

@rem make the models dir
mkdir models\ldm\stable-diffusion-v1

@rem install the project
call webui.cmd

@rem finally, tell the user that they need to download the ckpt
echo.
echo "Now you need to install the weights for the stable diffusion model."
echo "Please follow the steps related to models weights at https://sd-webui.github.io/stable-diffusion-webui/docs/1.windows-installation.html#cloning-the-repo to complete the installation"

@rem it would be nice if the weights downloaded automatically, and didn't need the user to do this manually.

pause
