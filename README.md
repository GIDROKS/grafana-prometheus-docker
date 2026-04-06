# Grafana + Prometheus (Docker)

Минимальный стек под Windows с Docker Desktop: Prometheus, Grafana, готовый datasource и дашборд «Windows — обзор».

## Запуск

```bash
git clone <ссылка-на-этот-репозиторий>.git
cd grafana-prometheus-docker
docker compose up -d
```

- **Prometheus:** http://localhost:9090  
- **Grafana:** http://localhost:3000 — логин `admin`, пароль `admin` (поменяй после входа).

## Windows-метрики (опционально)

Дашборд рассчитан на [windows_exporter](https://github.com/prometheus-community/windows_exporter/releases) на порту **9182** на той же машине, где Docker Desktop. Можно поставить MSI или запустить `start-windows-exporter.ps1` рядом с скачанным `windows_exporter.exe`.

Без экспортера Prometheus и Grafana работают, но графики Windows будут пустыми.

## Остановка

```bash
docker compose down
```

Данные Prometheus/Grafana лежат в Docker volumes (`prometheus_data`, `grafana_data`).
