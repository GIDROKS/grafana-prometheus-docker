# Как поставить Prometheus на Windows (если по статье с Хабра не взлетело)

Привет. Я набросал нормальную пошаговую инструкцию, потому что на Хабре всё в куче и легко на чём-то споткнуться. Ниже два варианта: **проще — через Docker** (если он у тебя есть) и **как в той статье — голый Prometheus + NSSM**. Выбирай, что ближе.

---

## Вариант А. Через Docker (я бы начал с этого)

Если стоит **Docker Desktop** под Windows — Prometheus внутри Linux-контейнера живёт спокойнее, чем нативно, и меньше возни с службами.

1. Поставь Docker Desktop, если ещё нет, перезагрузись, убедись, что в трее кит зелёный и `docker run hello-world` в PowerShell отрабатывает.
2. Создай папку, например `C:\monitoring`, внутри папку `prometheus` и файл `prometheus\prometheus.yml` с таким содержимым (минимум, чтобы проверить):

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets: ["localhost:9090"]
```

1. В корне `C:\monitoring` положи файл `docker-compose.yml`:

```yaml
services:
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
    command:
      - --config.file=/etc/prometheus/prometheus.yml
```

1. В PowerShell: `cd C:\monitoring`, потом `docker compose up -d`.
2. Открой в браузере **[http://localhost:9090](http://localhost:9090)** — должен открыться интерфейс Prometheus. Вкладка **Status → Targets** — таргет `prometheus` в состоянии **UP**.

Если не открывается — смотри, не занят ли порт 9090 чем-то ещё, и не блокирует ли брандмауэр (для локалхоста обычно ок).

---

## Вариант Б. Как в статье: Prometheus на Windows + NSSM

Тут типичные причины, почему «не получилось»: не тот путь к `prometheus.exe`, **CMD не от администратора**, NSSM не той разрядности (нужен **win64**), опечатка в `prometheus.yml`, служба падает сразу после старта.

### Шаг 1. Скачать Prometheus

Зайди на [https://prometheus.io/download/](https://prometheus.io/download/) , возьми **prometheus … windows-amd64.zip** (не linux, не macos). Распакуй, например, в `C:\Prometheus` так, чтобы путь к exe был примерно такой:  
`C:\Prometheus\prometheus-2.xx.x.windows-amd64\prometheus.exe`  
(цифры версии могут отличаться — не страшно.)

### Шаг 2. Конфиг

В **той же папке**, где лежит `prometheus.exe`, должен лежать файл `**prometheus.yml`**. Если его нет — скопируй из архива или создай минимальный:

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets: ["localhost:9090"]
```

Важно: **отступы пробелами**, не табами. Иначе Prometheus при старте скажет, что конфиг битый.

### Шаг 3. Проверка без службы

Открой **cmd или PowerShell от имени администратора** (права по клику — «Запуск от имени администратора»).

Перейди в папку с `prometheus.exe`:

```text
cd C:\Prometheus\prometheus-2.xx.x.windows-amd64
```

Запусти вручную:

```text
prometheus.exe --config.file=prometheus.yml
```

Если в окне куча ошибок — читай первые строки: часто там «cannot find config» или yaml parse error. Если всё ок — в браузере **[http://localhost:9090](http://localhost:9090)** снова должен открыться Prometheus. Остановить — Ctrl+C в этом окне.

### Шаг 4. NSSM (служба Windows)

1. Скачай NSSM с [https://www.nssm.cc/download](https://www.nssm.cc/download) , распакуй. Для 64-битной Windows используй `**nssm.exe` из папки `win64`**, не из `win32`.
2. В **cmd от администратора** перейди в папку win64, например:

```text
cd C:\Tools\nssm-2.24\win64
```

1. Установка службы (пути подставь **свои**, в кавычках, если есть пробелы):

```text
nssm install Prometheus "C:\Prometheus\prometheus-2.xx.x.windows-amd64\prometheus.exe"
```

Откроется окно NSSM:

- На вкладке **Application** в **Path** уже должен быть путь к `prometheus.exe`.
- В **Startup directory** укажи папку, где лежат `prometheus.exe` и `prometheus.yml` (та же директория).
- В **Arguments** напиши:

```text
--config.file=C:\Prometheus\prometheus-2.xx.x.windows-amd64\prometheus.yml
```

(полный путь к yml, чтобы не гадать «откуда запустили».)

Сохрани, потом в том же cmd:

```text
nssm start Prometheus
```

1. Проверь: **services.msc** — служба **Prometheus** в состоянии **Running**. Браузер — **[http://localhost:9090](http://localhost:9090)**.

Если служба сразу **Stopped** — открой **Просмотр событий Windows → Журналы приложений** или в NSSM вкладка **I/O** / логирование, либо снова запусти `prometheus.exe` вручную из той папки и посмотри текст ошибки.

---

## Что проверить, если «вообще ничего не работает»

- **Порт 9090** занят? В PowerShell: `netstat -ano | findstr :9090` — если занят не Prometheus, смени порт (флаг `--web.listen-address=:9091` и в браузере тогда `http://localhost:9091`).
- **Антивирус** иногда режет незнакомый exe — на время проверки можно добавить папку в исключения.
- Путь к конфигу в аргументах службы **абсолютный** и файл реально там лежит.
- Для **windows_exporter** и сбора с твоей машины адрес в `prometheus.yml` должен быть `**localhost:9182`** (если экспортер на этой же Windows), а не `host.docker.internal` — это только для Docker.

---

## Если снова бесит

Напиши мне, на каком шаге стопор: «не ставится служба», «падает при старте», «страница не открывается» — и скинь текст ошибки из консоли или скрин из **Status → Targets**, если уже до веб-морды добрался. Разберём точечно.

Удачи.