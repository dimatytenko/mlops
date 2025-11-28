# inference.py
import argparse
import json
import torch
from PIL import Image
import torchvision.transforms as T

IMAGENET_MEAN = (0.485, 0.456, 0.406)
IMAGENET_STD = (0.229, 0.224, 0.225)


def load_labels(path="imagenet_class_index.json"):
    import os
    import json

    # 1) Try: JSON dictionary {"0": ["wnid","label"], ...}
    try:
        with open(path, "r") as f:
            idx_to_labels = json.load(f)
        return {int(k): v[1] for k, v in idx_to_labels.items()}
    except Exception:
        pass
    # 2) Try: TXT list (one line per class)
    txt_path = "imagenet_classes.txt"
    if os.path.exists(txt_path):
        with open(txt_path, "r") as f:
            lines = [ln.strip() for ln in f if ln.strip()]
        return {i: name for i, name in enumerate(lines)}
    # 3) Fallback: simply return index as string
    return {i: str(i) for i in range(1000)}


def preprocess(path):
    img = Image.open(path).convert("RGB")
    tfm = T.Compose(
        [
            T.Resize(256),
            T.CenterCrop(224),
            T.ToTensor(),
            T.Normalize(IMAGENET_MEAN, IMAGENET_STD),
        ]
    )
    x = tfm(img).unsqueeze(0)
    return x


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True)
    ap.add_argument("--model", default="model.pt")
    ap.add_argument("--labels", default="imagenet_class_index.json")
    ap.add_argument("--topk", type=int, default=3)
    args = ap.parse_args()

    device = "cpu"
    model = torch.jit.load(args.model, map_location=device)
    model.eval()

    x = preprocess(args.image)
    with torch.no_grad():
        logits = model(x)
        probs = torch.softmax(logits, dim=1)
        topk = torch.topk(probs, k=args.topk)
    labels_map = load_labels(args.labels)

    print("Top predictions:")
    for p, idx in zip(topk.values[0].tolist(), topk.indices[0].tolist()):
        print(f"- {labels_map.get(idx, str(idx))}: {p:.4f}")
