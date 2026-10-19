# pwnbox-macos

Окружение для запуска и отладки Linux x86-64 ELF на Apple Silicon (M1/M2/M3).
Собрано под CTF и реверс: нужен был стенд, где бинарь можно и запустить, и отладить.

## Проблема

- x86-64 ELF на arm64 macOS не запускается: `exec format error`.
- Rosetta 2 запускает x86-64, но не поддерживает `ptrace`, поэтому `gdb` под ней падает
  (`Cannot PTRACE_GETREGS`). Отладки нет.
- `qemu-user` умеет и запускать, и отдавать gdbstub, но к нему нужен `gdb-multiarch`:
  обычный gdb не собран с поддержкой x86-64 target.
- pwndbg с qemu 8.2 (ubuntu 24.04) падает с `QEMU internal SIGSEGV`. Поэтому база
  qemu-образа — Debian trixie (qemu 10).

## Режимы

| Режим | Команда | База | Что внутри |
|---|---|---|---|
| Запуск / эксплойты | `./pwnbox` | ubuntu:24.04, amd64 (Rosetta) | gcc, g++, python3, pwntools, socat, netcat, strace, ltrace, readelf, objdump |
| Отладка x86-64 | `./qemu-gdb <bin>` | debian:trixie, arm64 | qemu-user, gdb-multiarch, pwndbg, libc6:amd64 |
| Отладка Mach-O (arm64) | `pwndbg-lldb` | macOS | ставится отдельно, в репозиторий не входит |

Текущая папка монтируется в `/work` (rw), поэтому работать можно прямо в каталоге с задачей.

## Установка

```bash
git clone https://github.com/krevetkqqq/pwnbox-macos.git
cd pwnbox-macos
chmod +x pwnbox qemu-gdb qgdb
```

Первый запуск сам собирает образ (несколько минут).

Требования: macOS на Apple Silicon, Docker Desktop, Xcode Command Line Tools.
Образы занимают около 2 ГБ.

## Использование

```bash
# запуск бинаря и сборка эксплойтов (x86-64, Rosetta)
./pwnbox ./chall
./pwnbox gcc -o exp exp.c
./pwnbox python3 exp.py

# отладка x86-64: qemu-user поднимает gdbstub, gdb-multiarch подключается
./qemu-gdb ./chall
./qemu-gdb ./chall arg1 arg2

# чужая libc
QGDB_QEMU_ARGS="-L ./sysroot" ./qemu-gdb ./chall
```

Внутри qemu-образа доступна команда `qgdb`:

```bash
qgdb ./chall [args...]
```

Переменные: `QGDB_PORT` (порт gdbstub, по умолчанию 12345), `QGDB_WAIT`
(пауза перед подключением, по умолчанию 1 с), `QGDB_QEMU_ARGS` (доп. флаги qemu).

## Ограничения

- `gdb` внутри Rosetta не работает — это ограничение Rosetta, не образа.
  Отладка только через `./qemu-gdb` или нативный lldb.
- `qemu-user` эмулирует syscall'ы: часть антидебаг-проверок и работа с потоками
  ведут себя иначе, чем на реальном x86-64. Для задач с ядром нужен
  `qemu-system` или железо.
- Скорость под qemu-user ниже нативной; для тяжёлого брутфорса это заметно.
- Абсолютные пути и симлинки внутри бинаря могут не резолвиться после монтирования.

## Структура

```
Dockerfile        образ pwnbox (amd64, Rosetta)
Dockerfile.qemu   образ pwnbox-qemu (arm64, qemu-user + gdb-multiarch)
pwnbox            запуск контейнера pwnbox
qemu-gdb          запуск контейнера отладки
qgdb              скрипт внутри контейнера: qemu-x86_64 + gdb-multiarch
```
