# Документация: Grafana + Prometheus + Loki (Docker)

## Что внутри

| Компонент    | Назначение |
|-------------|------------|
| **Prometheus** | Сбор и хранение метрик (TSDB), API и веб-UI на `:9090`. Retention — 30 дней. |
| **Loki**       | Хранение и поиск логов, API на `:3100`. Retention — 7 дней. |
| **Promtail**   | Агент сбора логов. Подключается к Docker-сокету, находит все контейнеры, читает их stdout/stderr и отправляет в Loki. |
| **Grafana**    | Визуализация; datasource-ы Prometheus и Loki прописаны provisioning-ом. |

## Структура репозитория

```text
docker-compose.yml                    # Сервисы, тома, healthcheck-и
prometheus/
  prometheus.yml                      # scrape_configs: Prometheus, Loki, Windows
loki/
  loki-config.yml                     # Хранилище, retention, schema
promtail/
  promtail-config.yml                 # Docker SD, relabeling, pipeline
grafana/
  provisioning/
    datasources/
      prometheus.yml                  # Источник данных Prometheus
      loki.yml                        # Источник данных Loki
    dashboards/default.yml            # Провайдер файловых дашбордов
  dashboards/
    windows-overview.json             # Дашборд «Windows — обзор»
    docker-logs.json                  # Дашборд «Логи — Docker»
start-windows-exporter.ps1           # Помощник запуска windows_exporter.exe
```

## Как связаны сервисы

1. **Grafana** обращается к Prometheus по `http://prometheus:9090` и к Loki по `http://loki:3100` (имена сервисов в Docker-сети compose).
2. **Prometheus** скрейпит метрики с самого себя, Loki и (опционально) windows_exporter на хосте.
3. **Promtail** подключается к Docker-сокету (`/var/run/docker.sock`), автоматически находит все контейнеры compose-проекта и читает их логи. Логи отправляются в Loki с лейблами `service`, `container`, `compose_project`, `logstream`.
4. **Loki** принимает логи от Promtail, хранит в TSDB на файловой системе (том `loki_data`).
5. Job **`windows`** в Prometheus опрашивает `host.docker.internal:9182` — хост Windows с Docker Desktop, где должен слушать windows_exporter.

На Linux без `host.docker.internal` может понадобиться добавить в сервис `prometheus`:

```yaml
extra_hosts:
  - "host.docker.internal:host-gateway"
```

## Healthcheck-и

Все основные сервисы имеют healthcheck, что гарантирует правильный порядок запуска:

| Сервис     | Endpoint              | Кто ждёт              |
|-----------|-----------------------|------------------------|
| Prometheus | `/-/healthy`          | Grafana                |
| Loki       | `/ready`              | Promtail, Grafana      |
| Grafana    | `/api/health`         | —                      |

`depends_on` с `condition: service_healthy` означает, что зависимый сервис не стартует, пока healthcheck не пройдёт.

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

## Дашборд «Логи — Docker»

Автоматически подключённый дашборд с логами всех Docker-контейнеров стека.

**Переменные дашборда:**
- **Сервис** — мульти-выбор: фильтрация по compose-сервису (prometheus, grafana, loki, promtail).
- **Поиск** — текстовое поле: фильтрация строк лога по подстроке (регулярное выражение).

**Панели:**
- **Всего строк** — общее количество строк лога за выбранный период.
- **Ошибки** — строки, содержащие `error`, `panic`, `fatal`, `critical` (зелёный = 0, красный > 0).
- **Предупреждения** — строки с `warn` / `warning` (зелёный = 0, жёлтый > 0).
- **Объём логов по сервисам** — гистограмма (stacked bars) с разбивкой по сервису.
- **Журнал** — полный поток логов с сортировкой, деталями лейблов и поиском.

## Данные и обновления

- **Тома:** `prometheus_data` (метрики, 30 дней), `grafana_data` (пользователи, настройки), `loki_data` (логи, 7 дней).
- Обновление образов:

  ```bash
  docker compose pull
  docker compose up -d
  ```

- Перечитать конфиг Prometheus без рестарта (в compose включён `--web.enable-lifecycle`):

  ```bash
  curl -X POST http://localhost:9090/-/reload
  ```

## Проверка, что всё живо

1. **Prometheus → Status → Targets** — все job (`prometheus`, `loki`, `windows`) в состоянии **UP**.
2. **Grafana → Explore** — datasource Prometheus, запрос `up`, должны быть точки.
3. **Grafana → Explore** — datasource Loki, запрос `{service=~".+"}`, должны быть логи.
4. **Grafana → Dashboards → Логи — Docker** — видны логи контейнеров, гистограмма заполняется.

## Типичные проблемы

| Симптом | Что проверить |
|---------|----------------|
| Grafana: Login failed при верном пароле | `GF_SECURITY_COOKIE_SECURE`, `GF_SERVER_ROOT_URL`, инкогнито, сброс пароля CLI. |
| Нет данных на дашборде Windows | Запущен ли windows_exporter на **9182**, открывается ли с хоста http://127.0.0.1:9182/metrics, target **windows** в Prometheus UP. |
| Нет логов в Loki / на дашборде | `docker compose logs promtail` — есть ли ошибки. Promtail должен найти контейнеры через Docker-сокет. Loki target в Prometheus должен быть UP. |
| Порт занят | В `docker-compose.yml` сменить проброс, например `"9091:9090"`. |
| После `compose down -v` пропали данные | Нормально: provisioning снова подтянет datasource-ы и JSON-дашборды из репозитория; кастомное, созданное только в UI, удалится вместе с томами. |

## Безопасность

Конфиг заточен под **локальную** разработку и обучение. Для продакшена не выставляй порты наружу без TLS, смени пароли, ограничь доступ к Grafana, Prometheus и Loki.
