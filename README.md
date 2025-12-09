
## 1. Як запустити Terraform

Перейдіть до директорії з Terraform конфігурацією:
```sh
cd terraform/argocd
```

Ініціалізація Terraform:
```sh
terraform init
```

Перевірка плану:
```sh
terraform plan
```

Застосування змін:
```sh
terraform apply
```

Підтвердьте `yes`.

---

## 2. Як перевірити, що ArgoCD працює

Перевіряємо namespace:

```sh
kubectl get ns
```
 - В нашому випадку:
NAME              STATUS   AGE
default           Active   4h16m
infra-tools       Active   3h12m
kube-node-lease   Active   4h16m
kube-public       Active   4h16m
kube-system       Active   4h16m

Перевіряємо поди ArgoCD:
```sh
kubectl get pods -n infra-tools
```

Має бути кілька pod-ів з префіксом `argocd-`, наприклад:
- `argocd-application-controller-*`
- `argocd-applicationset-controller-*`
- `argocd-dex-server-*`
- `argocd-notifications-controller-*`
- `argocd-redis-*`
- `argocd-repo-server-*`
- `argocd-server-*`
---

## 3. Як відкрити UI ArgoCD

### Отримати пароль адміністратора

```sh
kubectl -n infra-tools get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode
```

### Port-forward до UI

```sh
kubectl port-forward svc/argocd-server -n infra-tools 8080:443
```

Після цього зайти у браузер:

👉 [https://localhost:8080](https://localhost:8080)

(Потрібно погодитися на небезпечне підключення.)

### Логін:

* **Username:** admin
* **Password:** що отримали вище


## 4. Як перевірити, що деплой виконано

Список ArgoCD Applications:

```sh
kubectl get applications -n infra-tools
```

Опис Application:

```sh
kubectl describe application nginx -n infra-tools
```

Перевірити поди, що створені Helm-чартом:

```sh
kubectl get pods -n application
```

Перевірити ресурси:

```sh
kubectl get all -n application
```

---

## 5. Налаштування ArgoCD для моніторингу Git-репозиторію

Після розгортання ArgoCD потрібно налаштувати підключення до Git-репозиторію через UI або CLI:

### Через UI:
1. Відкрийте ArgoCD UI (див. розділ 3)
2. Перейдіть до Settings → Repositories
3. Додайте новий репозиторій:
   - Type: `git`
   - Repository URL: `https://github.com/dimatytenko/goit-argo`
   - Для Public репозиторію додаткові налаштування не потрібні

### Через CLI:
```sh
argocd repo add https://github.com/dimatytenko/goit-argo --type git
```

### Створення Application через ArgoCD

Після додавання репозиторію, створіть Application через UI або застосуйте маніфест:

```sh
kubectl apply -f https://raw.githubusercontent.com/dimatytenko/goit-argo/main/namespaces/application/nginx.yaml
```

Або якщо репозиторій вже клонований локально:
```sh
kubectl apply -f namespaces/application/nginx.yaml
```

---

## 6. Відкрити доступ до сервісу nginx

Після успішного деплою nginx через ArgoCD, можна отримати доступ до сервісу:

### Варіант 1: Port-forward (для тестування)

```sh
kubectl port-forward svc/nginx -n application 8081:80
```

Після цього відкрийте в браузері: http://localhost:8081

### Варіант 2: LoadBalancer (для продакшену)

Якщо потрібен зовнішній доступ, змініть тип сервісу на LoadBalancer у файлі `goit-argo/namespaces/application/nginx.yaml`:

```yaml
service:
  type: LoadBalancer
```

Після зміни закомітьте та запуште зміни в Git-репозиторій. ArgoCD автоматично синхронізує зміни.

Перевірити зовнішній IP:
```sh
kubectl get svc nginx -n application
```

---

## 7. Посилання на репозиторій з application.yaml

**Git-репозиторій:** https://github.com/dimatytenko/goit-argo

Структура репозиторію:
```
goit-argo
├── namespaces
│  ├── application
│  │  ├── nginx.yaml
│  │  └── ns.yaml
│  └── infra-tools
│    └── ns.yaml
└── README.md
```
