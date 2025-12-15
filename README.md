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
terraform apply -auto-approve \
  -var="aws_region=<your-region>" \
  -var="project_name=mlops-train-automation"
```
Після `apply` запишіть ARN state machine з виходу або консолі для використання в CI.
Terraform також повертає `state_machine_arn` як output.

## Ручний запуск Step Function
Через AWS CLI:
```bash
aws stepfunctions start-execution \
  --state-machine-arn <STATE_MACHINE_ARN> \
  --name "train-$(date +%s)" \
  --input '{"source":"cli","note":"manual run"}'
```
Або через AWS Console: зайдіть у Step Functions → оберіть state machine → Start execution → вставте JSON вище.

## GitLab CI
Job `train-model` у `.gitlab-ci.yml` викликає Step Function на кожен push.
Необхідні змінні CI/CD:
- `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` або OIDC-конфіг (рекомендовано) з політикою `states:StartExecution` і правами на конкретну state machine.
- `AWS_DEFAULT_REGION` (відповідає `aws_region`).
- `STATE_MACHINE_ARN` — ARN створеної state machine.
- (опційно при OIDC) `AWS_ROLE_ARN` + `AWS_WEB_IDENTITY_TOKEN_FILE`.

Приклад джоба:
```yaml
train-model:
  stage: train
  image: amazon/aws-cli:2.15.0
  script:
    - aws stepfunctions start-execution \
        --state-machine-arn "$STATE_MACHINE_ARN" \
        --name "train-$(date +%s)" \
        --input "{\"source\":\"gitlab-ci\",\"commit\":\"$CI_COMMIT_SHORT_SHA\"}"
  rules:
    - if: "$CI_PIPELINE_SOURCE == 'push'"
```

## Приклад JSON, що передається
```json
{"source":"gitlab-ci","commit":"abc1234"}
```

## Приклад виводу
- `aws stepfunctions start-execution ...` повертає:
```json
{
  "executionArn": "arn:aws:states:us-east-1:123456789012:execution:mlops-train-automation-pipeline:train-1700000000",
  "startDate": 1700000000.0
}
```
- CloudWatch Logs для Lambda можуть містити:
```
START RequestId: ... Version: $LATEST
Validating data...
END RequestId: ...
Logging metrics...
```

## Налаштування під себе
- Задайте `aws_region` і `project_name` у `terraform/variables.tf` або через `-var` при `terraform apply`.
- У `.gitlab-ci.yml` змініть `STATE_MACHINE_ARN` на ARN із output Terraform.
- За потреби замініть образ AWS CLI або додайте `before_script` з логіном у реєстр / підготовкою середовища.

## Логіка Step Function
1. `ValidateData` → викликає Lambda `validate.py`.
2. `LogMetrics` → викликає Lambda `log_metrics.py`.

Обидві функції повертають простий словник із статусом та echo вхідних даних, що ілюструє послідовність кроків пайплайна.
