# Grafana + Prometheus (Docker)

Готовый стек для **Docker Desktop на Windows** (подойдёт и Linux/macOS): **Prometheus**, **Grafana**, автоматически подключённый datasource и дашборд **«Windows — обзор»**.

**Репозиторий:** https://github.com/GIDROKS/grafana-prometheus-docker

## Требования

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (или Docker Engine + Compose v2)
- Свободные порты **3000** (Grafana) и **9090** (Prometheus)

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

**Вход в Grafana:** `admin` / `admin` — после первого входа лучше сменить пароль.

Остановка:

```bash
docker compose down
```

Полное удаление контейнеров **и** данных метрик/дашбордов:

```bash
docker compose down -v
```

## Windows-метрики (опционально)

Дашборд использует метрики [windows_exporter](https://github.com/prometheus-community/windows_exporter/releases) на **порту 9182** на хосте (там же, где крутится Docker Desktop). Prometheus в контейнере ходит на хост через **`host.docker.internal`**.

- Скачай **MSI** или **exe** с релизов windows_exporter.
- Рядом с репозиторием положи `windows_exporter.exe` и при необходимости запусти **`start-windows-exporter.ps1`** (или установи службу через MSI от администратора).

Без экспортера стек работает, но панели про CPU/RAM/диски будут без данных.

## Документация

- **[DOCS.md](DOCS.md)** — структура проекта, конфигурация, типичные проблемы.
- **[Как_поставить_Prometheus_на_Windows.md](Как_поставить_Prometheus_на_Windows.md)** — если нужен Prometheus **без Docker** (NSSM, служба Windows).

## Официальные ссылки

- [Prometheus — установка (в т.ч. Docker)](https://prometheus.io/docs/prometheus/latest/installation/)
- [Grafana — Docker образ](https://grafana.com/docs/grafana/latest/setup-grafana/configure-docker/)

## Лицензия

Конфигурации в репозитории — на твоё усмотрение; образы Prometheus и Grafana под их собственными лицензиями.
