import json
import math
import os
import random

TEAL = [0, 0.898, 0.8]  # 00E5CC
CYAN = [0, 1.0, 1.0]    # 00FFFF

def kf_ease():
    return {"x": [0.4], "y": [0.0]}, {"x": [0.2], "y": [1.0]}

def make_shape_layer(name, shape_type, size_kf, pos_kf, color, stroke_width, opacity_kf=None, rotation_kf=0, dash=None, in_p=0, out_p=300):
    if opacity_kf is None:
        opacity_kf = [{"t": 0, "s": [100]}]
    elif not isinstance(opacity_kf, list):
        opacity_kf = [{"t": 0, "s": [opacity_kf]}]
        
    if not isinstance(rotation_kf, list):
        rotation_kf = [{"t": 0, "s": [rotation_kf]}]
        
    shape_it = []
    
    # helper for easing
    def attach_easings(kfs):
        if not isinstance(kfs, list):
            return kfs
        for i in range(len(kfs) - 1):
            if isinstance(kfs[i], dict) and "t" in kfs[i] and "s" in kfs[i]:
                kfs[i]["i"], kfs[i]["o"] = kf_ease()
        return kfs

    size_kf = attach_easings(size_kf)
    pos_kf = attach_easings(pos_kf)
    opacity_kf = attach_easings(opacity_kf)
    rotation_kf = attach_easings(rotation_kf)
    
    if shape_type == "el":
        shape_it.append({"d": 1, "ty": "el", "s": {"a": 1 if isinstance(size_kf, list) and len(size_kf)>1 else 0, "k": size_kf} if isinstance(size_kf, list) else {"a": 0, "k": size_kf}, "p": {"a": 0, "k": [0,0]}, "nm": "Ellipse"})
    
    if stroke_width > 0:
        stroke = {"ty": "st", "c": {"a": 0, "k": color}, "o": {"a": 0, "k": 100}, "w": {"a": 0, "k": stroke_width}, "lc": 2, "lj": 2, "nm": "Stroke"}
        if dash:
            stroke["d"] = dash
        shape_it.append(stroke)
    else:
        shape_it.append({"ty": "fl", "c": {"a": 0, "k": color}, "o": {"a": 0, "k": 100}, "nm": "Fill"})
        
    shape_it.append({"ty": "tr", "p": {"a": 0, "k": [0,0]}, "a": {"a": 0, "k": [0,0]}, "s": {"a": 0, "k": [100,100]}, "r": {"a": 0, "k": 0}, "o": {"a": 0, "k": 100}})
    
    return {
        "ty": 4, "nm": name, "sr": 1,
        "ks": {
            "o": {"a": 1 if len(opacity_kf) > 1 else 0, "k": opacity_kf},
            "p": {"a": 1 if isinstance(pos_kf, list) and len(pos_kf) > 1 else 0, "k": pos_kf},
            "a": {"a": 0, "k": [0,0,0]},
            "s": {"a": 0, "k": [100,100,100]},
            "r": {"a": 1 if len(rotation_kf) > 1 else 0, "k": rotation_kf}
        },
        "ao": 0,
        "shapes": [{"ty": "gr", "it": shape_it, "nm": "Group"}],
        "ip": in_p, "op": out_p, "st": 0, "bm": 0
    }

layers = []

# Phase 1: Converging dots & lines (0-90)
random.seed(42)
for i in range(16):
    angle = (i / 16) * math.pi * 2 + random.uniform(-0.1, 0.1)
    dist = random.uniform(250, 400)
    sx = 250 + math.cos(angle) * dist
    sy = 250 + math.sin(angle) * dist
    
    delay = random.randint(0, 30)
    end_scale = random.uniform(4, 8)
    
    layers.append(make_shape_layer(f"Dot_{i}", "el", 
        [end_scale, end_scale], 
        [
            {"t": delay, "s": [sx,sy]}, 
            {"t": min(90, delay+50), "s": [250, 250]}
        ], 
        TEAL if i % 2 == 0 else CYAN, 0, 
        [{"t": 0, "s": [0]}, {"t": delay, "s": [100]}, {"t": 85, "s": [100]}, {"t": 90, "s": [0]}], 
        0, None, in_p=delay, out_p=90
    ))

# Spiraling inner arcs (0-90)
for i in range(4):
    angle = (i / 4) * math.pi * 2
    sz = [{"t": 0, "s": [400, 400]}, {"t": 90, "s": [20, 20]}]
    layers.append(make_shape_layer(f"Arc_{i}", "el", 
        sz,
        [250,250], 
        CYAN, 3, 
        [{"t": 0, "s": [0]}, {"t": 20, "s": [100]}, {"t": 85, "s": [100]}, {"t": 90, "s": [0]}], 
        [
            {"t": 0, "s": [math.degrees(angle)]}, 
            {"t": 90, "s": [math.degrees(angle) + 270]}
        ],
        [{"n": "d", "nm": "Dash", "v": {"a":0, "k": 30}}, {"n": "g", "nm": "Gap", "v": {"a":0, "k": 180}}], 
        in_p=0, out_p=90
    ))

# Phase 2: Core forms & Shockwave (90-150)
layers.append(make_shape_layer("Shockwave", "el", 
    [{"t": 88, "s": [0,0]}, {"t": 130, "s": [600,600]}], 
    [250,250], 
    CYAN, 4, 
    [{"t": 88, "s": [100]}, {"t": 130, "s": [0]}], 
    0, None, in_p=88, out_p=130
))

# Central core appears at 88
# Outer dashed ring (spins slowly)
layers.append(make_shape_layer("Core Outer", "el", 
    [{"t": 88, "s": [0,0]}, {"t": 110, "s": [140,140]}, {"t": 120, "s": [130,130]}], 
    [250,250], TEAL, 2, 100,
    [{"t": 88, "s": [0]}, {"t": 300, "s": [180]}],
    [{"n": "d", "nm": "Dash", "v": {"a":0, "k": 120}}, {"n": "g", "nm": "Gap", "v": {"a":0, "k": 40}}],
    in_p=88, out_p=300
))

# Mid solid ring (pulses)
layers.append(make_shape_layer("Core Mid", "el", 
    [
        {"t": 88, "s": [0,0]}, 
        {"t": 115, "s": [110,110]}, 
        {"t": 125, "s": [100,100]},
        {"t": 210, "s": [95,95]},
        {"t": 290, "s": [105,105]},
        {"t": 300, "s": [100,100]}
    ],
    [250,250], CYAN, 4, 100,
    0, None,
    in_p=88, out_p=300
))

# Center solid fill (Shield/Globe abstraction)
layers.append(make_shape_layer("Core Solid", "el", 
    [
        {"t": 88, "s": [0,0]}, 
        {"t": 105, "s": [85,85]}, 
        {"t": 115, "s": [75,75]},
        {"t": 180, "s": [75,75]},
        {"t": 240, "s": [70,70]},
        {"t": 300, "s": [75,75]}
    ],
    [250,250], TEAL, 0, 
    [
        {"t": 88, "s": [0]}, 
        {"t": 100, "s": [100]},
        {"t": 150, "s": [100]},
        {"t": 225, "s": [60]},
        {"t": 300, "s": [100]}
    ],
    0, None,
    in_p=88, out_p=300
))

# Lottie Structure
lottie = {
    "v": "5.5.2", "fr": 60, "ip": 0, "op": 300, 
    "w": 500, "h": 500, "nm": "SplashHero", "ddd": 0, 
    "assets": [], "layers": layers
}

os.makedirs('assets/lottie', exist_ok=True)
with open('assets/lottie/splash_hero.json', 'w') as f:
    json.dump(lottie, f)

print("splash_hero.json generated successfully.")
