import json
import math
import os

BLUE = [0.4, 0.7, 1.0]      # Light blue
GREY = [0.6, 0.6, 0.65]     # Light grey
GREEN = [0.2, 0.8, 0.4]     # Success green
RED = [0.9, 0.3, 0.3]       # Error red
TEAL = [0, 0.898, 0.8]      # TealAccent

def kf_ease():
    return {"x": [0.4], "y": [0.0]}, {"x": [0.2], "y": [1.0]}

def attach_easings(kfs):
    if not isinstance(kfs, list):
        return kfs
    for i in range(len(kfs) - 1):
        if isinstance(kfs[i], dict) and "t" in kfs[i] and "s" in kfs[i]:
            kfs[i]["i"], kfs[i]["o"] = kf_ease()
    return kfs

def make_shape_layer(name, shape_type, size_kf, pos_kf, color, stroke_width, opacity_kf=None, rotation_kf=0, dash=None, in_p=0, out_p=180, path_data=None):
    if opacity_kf is None:
        opacity_kf = [{"t": 0, "s": [100]}]
    elif not isinstance(opacity_kf, list):
        opacity_kf = [{"t": 0, "s": [opacity_kf]}]
    if not isinstance(rotation_kf, list):
        rotation_kf = [{"t": 0, "s": [rotation_kf]}]
        
    size_kf = attach_easings(size_kf)
    pos_kf = attach_easings(pos_kf)
    opacity_kf = attach_easings(opacity_kf)
    rotation_kf = attach_easings(rotation_kf)
    
    shape_it = []
    
    if shape_type == "el":
        shape_it.append({"d": 1, "ty": "el", "s": {"a": 1 if isinstance(size_kf, list) and len(size_kf)>1 else 0, "k": size_kf} if isinstance(size_kf, list) else {"a": 0, "k": size_kf}, "p": {"a": 0, "k": [0,0]}, "nm": "Ellipse"})
    elif shape_type == "rc":
        shape_it.append({"ty": "rc", "d": 1, "s": {"a": 1 if isinstance(size_kf, list) and len(size_kf)>1 else 0, "k": size_kf} if isinstance(size_kf, list) else {"a": 0, "k": size_kf}, "p": {"a": 0, "k": [0,0]}, "r": {"a": 0, "k": 4}, "nm": "Rect"})
    elif shape_type == "sh" and path_data:
        shape_it.append({"ty": "sh", "ks": {"a": 1 if isinstance(path_data, list) else 0, "k": path_data}, "nm": "Path"})

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

def create_network_loading():
    # Radar sweep
    layers = []
    layers.append(make_shape_layer("Radar BG", "el", [200,200], [250,250], GREY, 2, 30))
    layers.append(make_shape_layer("Radar Dash", "el", [150,150], [250,250], BLUE, 1, 50, 0,
        [{"n": "d", "nm": "Dash", "v": {"a":0, "k": 10}}, {"n": "g", "nm": "Gap", "v": {"a":0, "k": 20}}]
    ))
    # Sweeping wedge (simulated with a thick stroked circle segment inside a mask, or just a spinning arc)
    layers.append(make_shape_layer("Radar Sweep", "el", [180,180], [250,250], BLUE, 20, 100,
        [{"t": 0, "s": [0]}, {"t": 120, "s": [360]}],
        [{"n": "d", "nm": "Dash", "v": {"a":0, "k": 100}}, {"n": "g", "nm": "Gap", "v": {"a":0, "k": 500}}],
        out_p=120
    ))
    return {"v": "5.5.2", "fr": 60, "ip": 0, "op": 120, "w": 500, "h": 500, "nm": "NetworkLoading", "layers": layers}

def create_empty_profiles():
    # A dashed empty box that floats gently, with a small question mark floating above
    layers = []
    # Box body
    layers.append(make_shape_layer("Box", "rc", [160, 120], 
        [{"t": 0, "s": [250, 260]}, {"t": 90, "s": [250, 240]}, {"t": 180, "s": [250, 260]}], 
        GREY, 3, 100, 0,
        [{"n": "d", "nm": "Dash", "v": {"a":0, "k": 15}}, {"n": "g", "nm": "Gap", "v": {"a":0, "k": 15}}]
    ))
    # Question mark dot
    layers.append(make_shape_layer("Dot", "el", [10,10],
        [{"t": 15, "s": [250, 200]}, {"t": 105, "s": [250, 180]}, {"t": 195, "s": [250, 200]}],
        TEAL, 0
    ))
    # Question mark curve
    q_path = {"i": [[0,-15], [15,0], [0,10]], "o": [[0,15], [-15,0], [0,0]], "v": [[20, 150], [250, 130], [250, 170]], "c": False}
    # Using simple shape for Q curve: upper arc
    layers.append(make_shape_layer("Q_Arc", "el", [40, 40],
        [{"t": 10, "s": [250, 160]}, {"t": 100, "s": [250, 140]}, {"t": 190, "s": [250, 160]}],
        TEAL, 3, 100, 0,
        [{"n": "d", "nm": "Dash", "v": {"a":0, "k": 60}}, {"n": "g", "nm": "Gap", "v": {"a":0, "k": 100}}]
    ))
    return {"v": "5.5.2", "fr": 60, "ip": 0, "op": 180, "w": 500, "h": 500, "nm": "EmptyProfiles", "layers": layers}

def create_action_success():
    # Circle draws in, then checkmark draws in, slight bounce
    layers = []
    # Checkmark path
    v = [[220, 250], [240, 270], [280, 230]]
    path = {"i": [[0,0], [0,0], [0,0]], "o": [[0,0], [0,0], [0,0]], "v": v, "c": False}
    
    # Needs trim paths for drawing effect, but we can simulate with scale & opacity for simplicity, 
    # or use dash offset trick if supported. Let's just do a scale up with bounce.
    
    scale_bounce = [
        {"t": 0, "s": [0,0]},
        {"t": 20, "s": [120,120]},
        {"t": 35, "s": [90,90]},
        {"t": 50, "s": [100,100]}
    ]
    
    layers.append(make_shape_layer("Check", "sh", [100,100], [250,250], GREEN, 8, 100, 0, None, 15, 120, path))
    # The 'make_shape_layer' doesn't auto-apply scale to the group for paths easily unless we nest.
    # We will inject scale into the ks object manually.
    layers[0]["ks"]["s"] = {"a": 1, "k": attach_easings([
        {"t": 15, "s": [0,0]},
        {"t": 35, "s": [120,120]},
        {"t": 50, "s": [100,100]}
    ])}
    
    # Outer circle
    layers.append(make_shape_layer("Circle", "el", 
        attach_easings([{"t": 0, "s": [0,0]}, {"t": 20, "s": [120,120]}, {"t": 35, "s": [95,95]}, {"t": 50, "s": [100,100]}]),
        [250,250], GREEN, 4, 100, 0, None, 0, 120
    ))
    
    return {"v": "5.5.2", "fr": 60, "ip": 0, "op": 120, "w": 500, "h": 500, "nm": "ActionSuccess", "layers": layers}

def create_connection_error():
    # Trembling X inside a broken circle
    layers = []
    
    tremble_pos = []
    for i in range(10, 50, 4):
        tremble_pos.append({"t": i, "s": [250 + (i%3 - 1)*8, 250 + (i%5 - 2)*8]})
    tremble_pos.insert(0, {"t": 0, "s": [250,250]})
    tremble_pos.append({"t": 50, "s": [250,250]})
    attach_easings(tremble_pos)
    
    # X part 1
    p1 = {"i": [[0,0],[0,0]], "o": [[0,0],[0,0]], "v": [[-30,-30], [30,30]], "c": False}
    l1 = make_shape_layer("X1", "sh", [100,100], tremble_pos, RED, 6, 100, 0, None, 0, 120, p1)
    
    # X part 2
    p2 = {"i": [[0,0],[0,0]], "o": [[0,0],[0,0]], "v": [[30,-30], [-30,30]], "c": False}
    l2 = make_shape_layer("X2", "sh", [100,100], tremble_pos, RED, 6, 100, 0, None, 0, 120, p2)
    
    # Broken circle
    sz = attach_easings([{"t": 0, "s": [0,0]}, {"t": 20, "s": [120,120]}])
    c1 = make_shape_layer("Circle", "el", sz, [250,250], RED, 4, 100, 0, 
        [{"n": "d", "nm": "Dash", "v": {"a":0, "k": 40}}, {"n": "g", "nm": "Gap", "v": {"a":0, "k": 30}}],
        0, 120
    )
    
    layers.extend([l1, l2, c1])
    return {"v": "5.5.2", "fr": 60, "ip": 0, "op": 120, "w": 500, "h": 500, "nm": "ConnectionError", "layers": layers}

os.makedirs('assets/lottie', exist_ok=True)
with open('assets/lottie/network_loading.json', 'w') as f:
    json.dump(create_network_loading(), f)
with open('assets/lottie/empty_profiles.json', 'w') as f:
    json.dump(create_empty_profiles(), f)
with open('assets/lottie/action_success.json', 'w') as f:
    json.dump(create_action_success(), f)
with open('assets/lottie/connection_error.json', 'w') as f:
    json.dump(create_connection_error(), f)
    
print("Feedback Lotties generated successfully.")
