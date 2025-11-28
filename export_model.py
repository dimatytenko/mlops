# export_model.py
import argparse
import torch
import torchvision as tv


def get_model(name: str):
    name = name.lower()
    if name == "mobilenet_v2":
        weights = tv.models.MobileNet_V2_Weights.IMAGENET1K_V1
        model = tv.models.mobilenet_v2(weights=weights)
    else:
        raise ValueError(f"Unsupported model: {name}")
    model.eval()
    return model


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--model", default="mobilenet_v2")
    p.add_argument("--out", default="model.pt")
    args = p.parse_args()

    model = get_model(args.model)
    # Try script → if not, fallback to trace
    try:
        scripted = torch.jit.script(model)
    except Exception:
        example = torch.randn(1, 3, 224, 224)
        scripted = torch.jit.trace(model, example)

    scripted.save(args.out)
    print(f"Saved TorchScript to {args.out}")
