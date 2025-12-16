# mlops-train-automation

Невеликий приклад запуску тренувального пайплайна через AWS Step Functions і Lambda, описаний у Terraform, з автоматичним тригером із GitLab CI.

## Структура
- `terraform/main.tf` — ресурси AWS (IAM, Lambda, Step Function).
- `terraform/variables.tf` — змінні (регіон, префікс імен).
- `terraform/lambda/validate.py` — проста перевірка даних.
- `terraform/lambda/log_metrics.py` — логування метрик.
- `terraform/lambda/*.zip` — готові архіви для деплою.
- `.gitlab-ci.yml` — job, що викликає Step Function.

## Як зібрати Lambda-архіви
```bash
cd terraform/lambda
zip validate.zip validate.py
zip log_metrics.zip log_metrics.py
```

Альтернативно через Python (якщо `zip` недоступний):
```bash
cd terraform/lambda
python - <<'PY'
import zipfile, pathlib
base = pathlib.Path('.')
for name in ['validate', 'log_metrics']:
    src = base / f"{name}.py"
    dest = base / f"{name}.zip"
    with zipfile.ZipFile(dest, 'w', zipfile.ZIP_DEFLATED) as zf:
        zf.write(src, arcname=src.name)
    print(f"Created {dest}")
PY
```

## Деплой через Terraform
```bash
cd terraform
terraform init
terraform apply
```

Або з автоматичним підтвердженням:
```bash
terraform apply -auto-approve \
  -var="aws_region=<your-region>" \
  -var="project_name=mlops-train-automation"
```

Після `apply` запишіть ARN state machine з виходу або консолі для використання в CI.
Terraform також повертає `state_machine_arn` як output.

## Ручний запуск Step Function

### Через AWS Console
1. Зайдіть у AWS Management Console
2. Відкрийте сервіс **Step Functions**
3. Перейдіть до вкладки **State machines**
4. Знайдіть свою машину станів (наприклад: `mlops-train-automation-pipeline`)
5. Натисніть кнопку **Start execution**
6. У поле **Name** введіть: `train-<timestamp>` (наприклад: `train-1734220800`)
7. У поле **Input** введіть JSON:
```json
{
  "source": "manual",
  "commit": "test-commit"
}
```
8. Натисніть **Start execution** і слідкуйте за виконанням у реальному часі

### Через AWS CLI
```bash
aws stepfunctions start-execution \
  --state-machine-arn <STATE_MACHINE_ARN> \
  --name "train-$(date +%s)" \
  --input '{"source":"cli","note":"manual run"}'
```

## GitLab CI

GitLab CI автоматично запускає AWS Step Function при кожному пуші до репозиторію.

### Необхідні змінні CI/CD
- `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` або OIDC-конфіг (рекомендовано) з політикою `states:StartExecution` і правами на конкретну state machine.
- `AWS_DEFAULT_REGION` (відповідає `aws_region`, наприклад: `us-east-1`).
- `STATE_MACHINE_ARN` — ARN створеної state machine.
- (опційно при OIDC) `AWS_ROLE_ARN` + `AWS_WEB_IDENTITY_TOKEN_FILE`.

### Що відбувається в job
1. Встановлюється `awscli` через `pip install awscli`
2. Запускається Step Function з унікальною назвою (наприклад `train-1734220800`)
3. У вхідні дані передається:
   - `source: "gitlab-ci"`
   - `commit: SHA` останнього коміту (автоматично через `$CI_COMMIT_SHORT_SHA`)

### Приклад джоба
```yaml
stages:
  - train

train-model:
  stage: train
  image: python:3.11
  before_script:
    - pip install awscli
  script:
    - echo "🚀 Starting ML pipeline via Step Function"
    - |
       aws stepfunctions start-execution \
        --region us-east-1 \
        --state-machine-arn arn:aws:states:us-east-1:019959576624:stateMachine:MLOpsPipeline \
        --name "train-$(date +%s)" \
        --input "{\"source\":\"gitlab-ci\",\"commit\":\"$CI_COMMIT_SHORT_SHA\"}"
  rules:
    - if: "$CI_PIPELINE_SOURCE == 'push'"
```

## Приклад JSON, що передається
```json
{"source":"gitlab-ci","commit":"abc1234"}
```

## Приклад успішного виконання

### Відповідь від `aws stepfunctions start-execution`
```json
{
    "executionArn": "arn:aws:states:us-east-1:019959576624:execution:mlops-train-automation-pipeline:train-1734220800",
    "stateMachineArn": "arn:aws:states:us-east-1:019959576624:stateMachine:mlops-train-automation-pipeline",
    "name": "train-1734220800",
    "status": "SUCCEEDED",
    "startDate": "2025-12-15T14:30:15.238000+00:00",
    "stopDate": "2025-12-15T14:30:16.116000+00:00",
    "input": "{\"source\":\"gitlab-ci\",\"commit\":\"745e60cf\"}",
    "inputDetails": {
        "included": true
    },
    "output": "{\"status\": \"logged\"}",
    "outputDetails": {
        "included": true
    }
}
```

### CloudWatch Logs для Lambda validate
```
START RequestId: a1b2c3d4-e5f6-7890-abcd-ef1234567890 Version: $LATEST
Validating data...
END RequestId: a1b2c3d4-e5f6-7890-abcd-ef1234567890
REPORT RequestId: a1b2c3d4-e5f6-7890-abcd-ef1234567890	Duration: 45.23 ms	Billed Duration: 46 ms	Memory Size: 128 MB	Max Memory Used: 45 MB	Init Duration: 123.45 ms
```

### CloudWatch Logs для Lambda log_metrics
```
START RequestId: b2c3d4e5-f6a7-8901-bcde-f12345678901 Version: $LATEST
Logging metrics...
END RequestId: b2c3d4e5-f6a7-8901-bcde-f12345678901
REPORT RequestId: b2c3d4e5-f6a7-8901-bcde-f12345678901	Duration: 38.12 ms	Billed Duration: 39 ms	Memory Size: 128 MB	Max Memory Used: 42 MB	Init Duration: 98.76 ms
```

## Налаштування під себе
- Задайте `aws_region` і `project_name` у `terraform/variables.tf` або через `-var` при `terraform apply`.
- У `.gitlab-ci.yml` змініть `STATE_MACHINE_ARN` на ARN із output Terraform.
- За потреби замініть образ AWS CLI або додайте `before_script` з логіном у реєстр / підготовкою середовища.

## Логіка Step Function
1. `ValidateData` → викликає Lambda `validate.py`.
2. `LogMetrics` → викликає Lambda `log_metrics.py`.

Обидві функції повертають простий словник із статусом та echo вхідних даних, що ілюструє послідовність кроків пайплайна.
