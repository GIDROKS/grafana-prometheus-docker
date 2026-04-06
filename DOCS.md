# Документация: Grafana + Prometheus (Docker)

## Что внутри

| Компонент   | Назначение |
|------------|------------|
| **Prometheus** | Сбор и хранение метрик (TSDB), API и веб-UI на `:9090`. |
| **Grafana**    | Визуализация, datasource к Prometheus уже прописан provisioning-ом. |
| **Provisioning** | При старте Grafana подхватывает datasource `Prometheus` (uid `prometheus`) и JSON-дашборд из папки `grafana/dashboards/`. |

## Структура репозитория

```text
docker-compose.yml          # Сервисы, тома, переменные окружения Grafana
prometheus/
  prometheus.yml            # scrape_configs: сам Prometheus + опционально Windows
grafana/
  provisioning/
    datasources/prometheus.yml   # Источник данных по умолчанию
    dashboards/default.yml        # Провайдер файловых дашбордов
  dashboards/
    windows-overview.json         # Дашборд «Windows — обзор»
start-windows-exporter.ps1  # Помощник запуска windows_exporter.exe на :9182
```

## Как связаны сервисы

1. Контейнер **Grafana** обращается к Prometheus по **`http://prometheus:9090`** (имя сервиса в Docker-сети compose).
2. **Prometheus** читает конфиг из `./prometheus/prometheus.yml`.
3. Job **`windows`** опрашивает **`host.docker.internal:9182`** — это хост Windows с Docker Desktop, где должен слушать **windows_exporter**.

На Linux без `host.docker.internal` может понадобиться добавить в сервис `prometheus`:

```yaml
extra_hosts:
  - "host.docker.internal:host-gateway"
```

и оставить тот же target, либо заменить target на IP хоста.

## Переменные Grafana (docker-compose)

| Переменная | Зачем |
|------------|--------|
| `GF_SECURITY_ADMIN_USER` / `GF_SECURITY_ADMIN_PASSWORD` | Учётка админа при **первом** создании БД Grafana. |
| `GF_SECURITY_COOKIE_SECURE=false` | Для входа по **http://** без HTTPS: иначе браузер может не сохранить сессию → «Login failed». |
| `GF_SERVER_ROOT_URL` | Должен совпадать с тем, как открываешь UI (например `http://localhost:3000/`). |
| `GF_USERS_DEFAULT_LANGUAGE=ru-RU` | Язык интерфейса по умолчанию. |

Если том `grafana_data` уже создан, смена пароля через env **не перезаписывает** существующего админа. Тогда сброс:

```bash
docker compose exec grafana grafana cli admin reset-admin-password НОВЫЙ_ПАРОЛЬ
```

## Данные и обновления

- **Тома:** `prometheus_data` (метрики), `grafana_data` (пользователи, настройки, всё не из provisioning).
- Обновление образов:

  ```bash
  docker compose pull
  docker compose up -d
  ```

- Перечитать конфиг Prometheus без рестарта (в compose включён `--web.enable-lifecycle`):

  ```bash
  curl -X POST http://localhost:9090/-/reload
  ```

  После правки `prometheus.yml` на диске.

## Проверка, что всё живо

1. **Prometheus → Status → Targets** — все job в состоянии **UP** (для `windows` нужен запущенный exporter на 9182).
2. **Grafana → Explore** — datasource Prometheus, запрос `up`, должны быть точки/строки.

## Типичные проблемы

| Симптом | Что проверить |
|---------|----------------|
| Grafana: Login failed при верном пароле | `GF_SECURITY_COOKIE_SECURE`, `GF_SERVER_ROOT_URL`, инкогнито, сброс пароля CLI. |
| Нет данных на дашборде Windows | Запущен ли windows_exporter на **9182**, открывается ли с хоста http://127.0.0.1:9182/metrics , target **windows** в Prometheus UP. |
| Порт занят | В `docker-compose.yml` сменить проброс, например `"9091:9090"`. |
| После `compose down -v` пропали дашборды из UI | Нормально: provisioning снова подтянет JSON из репозитория; кастомное, созданное только в UI, в томе `grafana_data` — оно удалено вместе с `-v`. |

## Безопасность

Конфиг заточен под **локальную** разработку и обучение. Для продакшена не выставляй порты наружу без TLS, смени пароли, ограничь доступ к Grafana и Prometheus.
