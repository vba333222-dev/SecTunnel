import json
import os

# Colors
TEAL = [0, 0.898, 0.8]  # 00E5CC
CYAN = [0, 1.0, 1.0]    # 00FFFF
DARK = [0.086, 0.086, 0.121] # 16161F

def make_shape_layer(name, size, pos, color, stroke_width, rotation_keyframes, dash=None):
    layer = {
        "ddd": 0, "ind": 1, "ty": 4, "nm": name, "sr": 1,
        "ks": {
            "o": {"a": 0, "k": 100},
            "p": {"a": 0, "k": pos},
            "a": {"a": 0, "k": [0,0,0]},
            "s": {"a": 0, "k": [100,100,100]},
            "r": {
                "a": 1,
                "k": rotation_keyframes
            }
        },
        "ao": 0,
        "shapes": [
            {
                "ty": "gr",
                "it": [
                    {
                        "d": 1, "ty": "el", 
                        "s": {"a": 0, "k": size}, 
                        "p": {"a": 0, "k": [0,0]},
                        "nm": "Ellipse Path 1"
                    },
                    {
                        "ty": "st",
                        "c": {"a": 0, "k": color},
                        "o": {"a": 0, "k": 100},
                        "w": {"a": 0, "k": stroke_width},
                        "lc": 2, "lj": 2, "ml": 4, "nm": "Stroke 1",
                        "d": dash if dash else []
                    },
                    {
                        "ty": "tr",
                        "p": {"a": 0, "k": [0,0]},
                        "a": {"a": 0, "k": [0,0]},
                        "s": {"a": 0, "k": [100,100]},
                        "r": {"a": 0, "k": 0},
                        "o": {"a": 0, "k": 100}
                    }
                ],
                "nm": "Ellipse 1", "np": 3, "cix": 2, "bm": 0, "ix": 1, "mn": "ADBE Vector Group"
            }
        ],
        "ip": 0, "op": 120, "st": 0, "bm": 0
    }
    return layer

def build_lottie(layers, w=500, h=500, frames=120):
    return {
        "v": "5.5.2", "fr": 60, "ip": 0, "op": frames, 
        "w": w, "h": h, "nm": "Animation", "ddd": 0, 
        "assets": [], "layers": layers
    }

def create_loading():
    k1 = [{"i": {"x": [0.833], "y": [0.833]}, "o": {"x": [0.167], "y": [0.167]}, "t": 0, "s": [0]},
          {"t": 120, "s": [360]}]
    k2 = [{"i": {"x": [0.833], "y": [0.833]}, "o": {"x": [0.167], "y": [0.167]}, "t": 0, "s": [360]},
          {"t": 120, "s": [0]}]
          
    dash1 = [{"n": "d", "nm": "Dash", "v": {"a":0, "k": 100}}, {"n": "g", "nm": "Gap", "v": {"a":0, "k": 80}}]
    dash2 = [{"n": "d", "nm": "Dash", "v": {"a":0, "k": 50}}, {"n": "g", "nm": "Gap", "v": {"a":0, "k": 120}}]

    layers = [
        make_shape_layer("Outer", [200,200], [250,250], TEAL, 8, k1, dash1),
        make_shape_layer("Inner", [150,150], [250,250], CYAN, 4, k2, dash2)
    ]
    return build_lottie(layers)

def create_dashboard_empty():
    k1 = [{"t": 0, "s": [0]}, {"t": 180, "s": [360]}]
    dash1 = [{"n": "d", "nm": "Dash", "v": {"a":0, "k": 300}}, {"n": "g", "nm": "Gap", "v": {"a":0, "k": 50}}]
    
    layer = make_shape_layer("Shield Base", [300,300], [250,250], TEAL, 2, k1, dash1)
    # add a slow pulsing inner node
    pulse = {
        "ddd": 0, "ind": 2, "ty": 4, "nm": "Core", "sr": 1,
        "ks": {
            "o": {
                "a": 1,
                "k": [
                    {"t": 0, "s": [30]},
                    {"t": 90, "s": [100]},
                    {"t": 180, "s": [30]}
                ]
            },
            "p": {"a": 0, "k": [250,250]},
            "a": {"a": 0, "k": [0,0]},
            "s": {
                "a": 1,
                "k": [
                    {"t": 0, "s": [50,50]},
                    {"t": 90, "s": [150,150]},
                    {"t": 180, "s": [50,50]}
                ]
            },
            "r": {"a": 0, "k": 0}
        },
        "ao": 0,
        "shapes": [
            {
                "ty": "gr", "it": [
                    {"d": 1, "ty": "el", "s": {"a": 0, "k": [50,50]}, "p": {"a": 0, "k": [0,0]}, "nm": "Ellipse"},
                    {"ty": "fl", "c": {"a": 0, "k": TEAL}, "o": {"a": 0, "k": 100}, "nm": "Fill"},
                    {"ty": "tr", "p": {"a": 0, "k": [0,0]}, "a": {"a": 0, "k": [0,0]}, "s": {"a": 0, "k": [100,100]}, "r": {"a": 0, "k": 0}, "o": {"a": 0, "k": 100}}
                ]
            }
        ],
        "ip": 0, "op": 180, "st": 0, "bm": 0
    }
    
    return build_lottie([layer, pulse], frames=180)

def create_connecting():
    # Fast horizontal dashes
    layers = []
    for i in range(3):
        k = [{"t": 0, "s": [0]}, {"t": 60, "s": [360]}]
        dash = [{"n": "d", "nm": "Dash", "v": {"a":0, "k": 150}}, {"n": "g", "nm": "Gap", "v": {"a":0, "k": 200}}]
        layers.append(make_shape_layer(f"Ring {i}", [200 + i*40, 200 + i*40], [250,250], CYAN if i%2==0 else TEAL, 3, k, dash))
    return build_lottie(layers, frames=60)

os.makedirs('assets/lottie', exist_ok=True)
with open('assets/lottie/loading.json', 'w') as f:
    json.dump(create_loading(), f)
with open('assets/lottie/dashboard_empty.json', 'w') as f:
    json.dump(create_dashboard_empty(), f)
with open('assets/lottie/connecting.json', 'w') as f:
    json.dump(create_connecting(), f)
    
print("Lottie files generated successfully.")
