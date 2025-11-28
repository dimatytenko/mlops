# Lesson 3 — Containerization of ML-service

## Project structure
```
lesson-3/
├─ export_model.py
├─ inference.py
├─ imagenet_class_index.json
├─ requirements.txt
├─ Dockerfile.fat
├─ Dockerfile.slim
├─ report.md
└─ samples/ # test images
```

---

# Steps to run

## 1. Go to the project directory
```
cd lesson-3
```
## 2. Add test image
```
mkdir -p samples
curl -L -o samples/cat.jpg https://raw.githubusercontent.com/pytorch/hub/master/images/dog.jpg
```
## 3. Build Docker images

Fat image
```
docker build -f Dockerfile.fat -t lesson3-fat .
```

Slim image (multi-stage)
```
docker build -f Dockerfile.slim -t lesson3-slim .
```

## 4. Run inference
Fat
```
docker run --rm -v "$PWD/samples:/samples" lesson3-fat --image /samples/cat.jpg
```

Slim
```
docker run --rm -v "$PWD/samples:/samples" lesson3-slim --image /samples/cat.jpg
```

#Expected result:
```
Top predictions:
- Labrador_retriever: 0.62
- golden_retriever: 0.19
- flat-coated_retriever: 0.04
```
## 5. Compare images

Check size and number of layers:
## Size
```
docker images | grep lesson3
```

## Number of layers
```
docker history lesson3-fat  | wc -l
docker history lesson3-slim | wc -l
```
## Details of layers
```
docker history --no-trunc lesson3-fat
docker history --no-trunc lesson3-slim
```
