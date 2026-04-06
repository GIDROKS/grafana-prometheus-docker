# Grafana + Prometheus + Loki (Docker)

Готовый стек для **Docker Desktop на Windows** (подойдёт и Linux/macOS): **Prometheus**, **Grafana**, **Loki** + **Promtail**, автоматически подключённые datasource-ы и дашборды **«Windows — обзор»** и **«Логи — Docker»**.

**Репозиторий:** https://github.com/GIDROKS/grafana-prometheus-docker

## Требования

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (или Docker Engine + Compose v2)
- Свободные порты **3000** (Grafana), **9090** (Prometheus), **3100** (Loki)

## Быстрый старт

```bash
git clone https://github.com/GIDROKS/grafana-prometheus-docker.git
cd grafana-prometheus-docker
docker compose up -d
```

Открой в браузере:

| Сервис     | URL                     |
|-----------|-------------------------|
| Prometheus | http://localhost:9090  |
| Grafana    | http://localhost:3000  |
| Loki       | http://localhost:3100/ready |

**Вход в Grafana:** `admin` / `admin` — после первого входа лучше сменить пароль.

Остановка:

```bash
docker compose down
```

Полное удаление контейнеров **и** данных метрик/логов/дашбордов:

```bash
docker compose down -v
```

## Что внутри

| Компонент    | Назначение |
|-------------|------------|
| **Prometheus** | Сбор и хранение метрик, retention 30 дней. |
| **Loki**       | Хранение логов, retention 7 дней. |
| **Promtail**   | Агент: собирает логи всех Docker-контейнеров и отправляет в Loki. |
| **Grafana**    | Визуализация; datasource-ы Prometheus и Loki подключены provisioning-ом. |

Дашборды (provisioning):
- **Windows — обзор** — CPU, RAM, диски (нужен windows_exporter).
- **Логи — Docker** — объём логов по сервисам, поиск, фильтр ошибок/предупреждений.

## Windows-метрики (опционально)

Дашборд «Windows — обзор» использует метрики [windows_exporter](https://github.com/prometheus-community/windows_exporter/releases) на **порту 9182** на хосте. Prometheus ходит на хост через **`host.docker.internal`**.

- Скачай **MSI** или **exe** с релизов windows_exporter.
- Рядом с репозиторием положи `windows_exporter.exe` и при необходимости запусти **`start-windows-exporter.ps1`** (или установи службу через MSI от администратора).

Без экспортера стек работает, но панели про CPU/RAM/диски будут без данных.

## Документация

- **[DOCS.md](DOCS.md)** — структура проекта, конфигурация, типичные проблемы.
- **[Как_поставить_Prometheus_на_Windows.md](Как_поставить_Prometheus_на_Windows.md)** — если нужен Prometheus **без Docker** (NSSM, служба Windows).

## Официальные ссылки

- [Prometheus — установка](https://prometheus.io/docs/prometheus/latest/installation/)
- [Grafana — Docker образ](https://grafana.com/docs/grafana/latest/setup-grafana/configure-docker/)
- [Loki — документация](https://grafana.com/docs/loki/latest/)
- [Promtail — конфигурация](https://grafana.com/docs/loki/latest/send-data/promtail/configuration/)

## Лицензия

Конфигурации в репозитории — на твоё усмотрение; образы Prometheus, Grafana и Loki под их собственными лицензиями.
