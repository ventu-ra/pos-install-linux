import uv
import os
import subprocess

# Comando principal que será a base da sua CLI
@uv.command
def install(distro: str = "arch"):
  """Instala pacotes dependendo da distribuição Linux"""

  if distro == 'fedora':
    subprocess.run(['sudo', 'dnf', 'install', '-y' 'gnome-shell','git'])
    print('Fedora')
  elif distro =='arch':
    print("arch")
  else:
    uv.error(f"Distribuição {distro}não suportada")

if __name__ == '__main__':
  uv.run()

