# zapret2-openwrt 🚀

[![GitHub release](https://img.shields.io/github/v/release/Dushnilin/zapret2-openwrt?color=blue&style=flat-square)](https://github.com/Dushnilin/zapret2-openwrt/releases)
[![OpenWrt Version](https://img.shields.io/badge/OpenWrt-23.05%20%7C%2025.12%2B-green?style=flat-square&logo=openwrt)](https://openwrt.org)
[![License](https://img.shields.io/badge/License-MIT-orange.style=flat-square)](https://opensource.org/licenses/MIT)
[![Upstream Sync](https://img.shields.io/badge/Upstream-bol--van%2Fzapret2-brightgreen?style=flat-square&logo=github)](https://github.com/bol-van/zapret2)

**Zapret2** — мощный комплекс утилит для автономного обхода DPI (Deep Packet Inspection) и блокировок сетевого трафика.

Данный репозиторий представляет собой **автоматизированный форк и систему автосборки пакетов** OpenWrt для `zapret2` с графическим веб-интерфейсом **LuCI**.

---

## 📌 Благодарности и Происхождение (Credits & Lineage)

Проект создан на основе разработок двух ключевых авторов сообщества:

- 👑 **[bol-van / zapret2](https://github.com/bol-van/zapret2)** — **Автор оригинального Zapret / Zapret2**. Разработчик ядра `nfqws2`, утилит `ip2net`, `mdig`, инструмента диагностики `blockcheck2` и стратегий обхода DPI.
- 🛠️ **[remittor / zapret-openwrt](https://github.com/remittor/zapret-openwrt)** — **Автор адаптации под OpenWrt**. Создатель архитектуры интеграции `zapret` в экосистему OpenWrt (UCI-конфигурация, сервисные скрипты `init.d`, горячая перезагрузка) и веб-интерфейса **LuCI** (`luci-app-zapret2`).

### ⚙️ Что делает данный репозиторий (`Dushnilin/zapret2-openwrt`):
1. **Авто-синхронизация с upstream**: GitHub Actions раз в 6 часов опрашивает репозиторий `bol-van/zapret2`. Как только `bol-van` выпускает новый релиз, данный репозиторий автоматически подтягивает обновления.
2. **Сборка для всех архитектур**: Собирает готовые пакеты для 9 архитектурных семейств OpenWrt (`aarch64`, `arm_cortex-a7/a8/a9/a15`, `mips_24kc`, `mipsel_24kc`, `mips64`, `x86_64`, `i386`, `riscv64`, `powerpc`).
3. **Поддержка нового менеджера пакетов APK**: Собирает как традиционные `.ipk` (opkg для OpenWrt 23.05+), так и подписанные `.apk` (для OpenWrt 25.12+).

---

## 📦 Установка

### 📶 OpenWrt 25.12+ (Менеджер пакетов APK)
```sh
# 1. Добавление публичного ключа подписи
wget -O /etc/apk/keys/zapret2-dushnilin.pub https://github.com/Dushnilin/zapret2-openwrt/releases/latest/download/zapret2-dushnilin.pub

# 2. Скачивание пакета zapret2 под вашу архитектуру и LuCI UI
wget -O /tmp/zapret2.apk "https://github.com/Dushnilin/zapret2-openwrt/releases/latest/download/zapret2_$(. /etc/os-release; echo "$OPENWRT_ARCH").apk"
wget -O /tmp/luci-app-zapret2.apk https://github.com/Dushnilin/zapret2-openwrt/releases/latest/download/luci-app-zapret2.apk

# 3. Установка
apk add /tmp/zapret2.apk /tmp/luci-app-zapret2.apk
```

### 📶 OpenWrt 23.05+ (Менеджер пакетов OPKG)
```sh
# 1. Скачивание пакета zapret2 под вашу архитектуру и LuCI UI
wget -O /tmp/zapret2.ipk "https://github.com/Dushnilin/zapret2-openwrt/releases/latest/download/zapret2_$(. /etc/os-release; echo "$OPENWRT_ARCH").ipk"
wget -O /tmp/luci-app-zapret2.ipk https://github.com/Dushnilin/zapret2-openwrt/releases/latest/download/luci-app-zapret2.ipk

# 2. Установка
opkg update
opkg install /tmp/zapret2.ipk /tmp/luci-app-zapret2.ipk
```

После установки сервис запускается автоматически. Графическая настройка доступна в меню **LuCI → Службы → Zapret2**.

---

## 🖼️ Веб-интерфейс LuCI

![Zapret2 LuCI UI](https://github.com/user-attachments/assets/4ad3eac5-44a6-493c-a001-997d0c1a36eb)

---

## 💻 Локальная синхронизация для разработчиков

Для проверки обновлений или ручной синхронизации в репозитории доступен скрипт:

```bash
# Проверить наличие новых версий upstream у bol-van/zapret2
./sync-upstream.sh --check

# Обновить Makefile локально
./sync-upstream.sh

# Обновить и сразу отправить в ветку zap1 для автосборки релиза
./sync-upstream.sh --push
```

---

## 📜 Лицензия

Лицензия проекта — **MIT**, в соответствии с исходными репозиториями [bol-van/zapret2](https://github.com/bol-van/zapret2) и [remittor/zapret-openwrt](https://github.com/remittor/zapret-openwrt).
