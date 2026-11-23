# RR Escritorio · RR ALIADOS

Deja cualquier Linux (Ubuntu, Debian, Mint, Pop!_OS) con el **escritorio RR**: XFCE con los colores de RR ALIADOS,
íconos fucsia, cursor Bibata, fondos RR que rotan cada 5 min, barra superior negra con menú RR, reloj mostaza,
Plank abajo (se esconde solo) con el panel **Apps RR**, y ventanas que abren maximizadas.

## Instalar (una línea en la terminal)

```bash
curl -fsSL https://raw.githubusercontent.com/rraliadosteam-prog/rr-escritorio/main/install.sh | bash
```

Qué hace:

1. Revisa tu Linux y te pide la contraseña de **sudo** una vez.
2. Instala XFCE, Plank, el menú Whisker y lo que falte (sin cambiar tu pantalla de inicio).
3. Guarda una copia de tu configuración en `~/rr-escritorio-respaldo/FECHA`.
4. Copia temas, íconos, fuentes, fondos y programas RR a tu carpeta personal.
5. Deja **XFCE como sesión por defecto**. Tu escritorio anterior **no se borra**: lo eliges en la pantalla de inicio.
6. Avisa 10 segundos y **cierra la sesión** (Ctrl+C para cancelar). Al entrar, la primera vez se aplica todo solo.

Se puede correr dos veces sin problema.

## Deshacer

```bash
bash ~/.local/share/rr-escritorio/desinstalar.sh
```

Restaura tu configuración original y vuelve a dejar tu sesión de antes. No borra nada: lo de RR se mueve a
`~/rr-escritorio-respaldo/desinstalado-FECHA`. Los paquetes quedan instalados.

## Requisitos

- Linux con `apt` (Ubuntu 22.04+, Debian 12+, Mint 21+). Fedora y Arch: a medias (best-effort).
- Usuario con sudo e internet. Descarga aprox.: 25 MB del paquete RR + 150–300 MB de paquetes si no tienes XFCE.

## Opciones para pruebas

- `RR_NO_LOGOUT=1` no cierra la sesión al final.
- `RR_REF=rama` instala desde otra rama del repo.

Créditos y licencias: ver [CREDITOS.md](CREDITOS.md).
