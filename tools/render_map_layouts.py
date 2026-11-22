from PIL import Image, ImageDraw, ImageFont
import os, random

FONT = r"C:\Users\Administrator\Documents\Codex\TrollHunt\assets\fonts\NotoSansSC-Regular.otf"
OUT = r"C:\Users\Administrator\Documents\Codex\2026-11-20\new-chat-2\outputs\concepts\layouts"

W, H = 1600, 1000
BG = (20, 17, 14)
PANEL = (34, 29, 23)
GRID = (58, 50, 40)
GOLD = (228, 186, 92)
TEXT = (242, 238, 228)
MUTED = (168, 158, 140)

COLORS = {
    "safe": (58, 148, 96),
    "combat": (172, 126, 62),
    "elite": (214, 122, 48),
    "boss": (196, 56, 50),
    "water": (54, 108, 158),
    "lava": (208, 78, 38),
    "ice": (110, 170, 200),
    "entrance": (64, 168, 188),
    "path": (198, 168, 108),
}

def font(size):
    return ImageFont.truetype(FONT, size)

F_TITLE = font(48)
F_SUB = font(22)
F_PANEL = font(24)
F_LABEL = font(17)
F_SMALL = font(15)


def dungeon_layer(name, size, seed, rooms=5, hazard=None):
    rng = random.Random(seed)
    zones = []
    centers = []
    cols = 3
    cell = size / 3.0
    for i in range(rooms):
        cx = (i % cols + 0.5) * cell + rng.uniform(-8, 8)
        cy = (i // cols + 0.5) * cell + rng.uniform(-8, 8)
        w = rng.uniform(14, 20)
        h = rng.uniform(12, 18)
        kind = "elite" if i == rooms - 1 else "combat"
        zones.append(dict(x=cx - w / 2, y=cy - h / 2, w=w, h=h, label=f"房间{i+1}", type=kind))
        centers.append((cx, cy))
    if hazard:
        hx, hy = size * 0.5, size * 0.5
        zones.append(dict(x=hx - 12, y=hy - 9, w=24, h=18, label=hazard, type="water" if hazard != "岩浆" else "lava"))
    return dict(name=name, size=(size, size), zones=zones, paths=[centers], boss=None)


MAPS = [
    dict(
        id="01", name="黄沙岗", level="Lv 1–8", boss="无 BOSS", note="新手刷级场，高密度、低伤害、3 秒刷新",
        layers=[dict(name="地表 100×100", size=(100, 100), paths=[[(13, 14), (24, 34), (44, 44), (64, 30), (70, 68)]], boss=None,
                     zones=[
                         dict(x=4, y=5, w=18, h=16, label="出生营地", type="safe"),
                         dict(x=10, y=26, w=32, h=26, label="枯木坡", type="combat"),
                         dict(x=56, y=56, w=30, h=26, label="流沙坑", type="combat"),
                         dict(x=52, y=20, w=24, h=18, label="废弃车阵·精英", type="elite"),
                         dict(x=84, y=84, w=10, h=8, label="传送点", type="entrance"),
                     ])],
    ),
    dict(
        id="02", name="沙地遗迹", level="Lv 8–16", boss="沙虫王", note="野外 140×140 + 三层地宫 80×80",
        layers=[
            dict(name="野外 140×140", size=(140, 140), paths=[[(16, 16), (45, 60), (66, 66), (100, 70), (80, 118)]], boss=None,
                 zones=[
                     dict(x=6, y=6, w=18, h=16, label="绿洲补给点", type="safe"),
                     dict(x=50, y=48, w=30, h=28, label="遗迹广场", type="combat"),
                     dict(x=28, y=80, w=58, h=16, label="沙海古道", type="combat"),
                     dict(x=88, y=52, w=24, h=40, label="断柱回廊·精英", type="elite"),
                     dict(x=72, y=112, w=14, h=12, label="地宫入口", type="entrance"),
                 ]),
            dungeon_layer("地宫一层·墓道", 80, 201, rooms=5),
            dungeon_layer("地宫二层·地宫", 80, 202, rooms=6, hazard="流沙"),
            dict(name="地宫三层·巢穴 60×60", size=(60, 60), paths=[[(8, 50), (18, 34), (30, 30)]], boss=(30, 30),
                 zones=[
                     dict(x=18, y=15, w=24, h=24, label="沙虫王巢", type="boss"),
                     dict(x=6, y=40, w=14, h=12, label="入口", type="entrance"),
                 ]),
        ],
    ),
    dict(
        id="03", name="幽影森林", level="Lv 16–24", boss="千年树妖", note="野外 150×150 + 三层树根迷宫",
        layers=[
            dict(name="野外 150×150", size=(150, 150), paths=[[(22, 20), (38, 66), (70, 48), (104, 96), (74, 124)]], boss=None,
                 zones=[
                     dict(x=12, y=12, w=18, h=16, label="猎人营地", type="safe"),
                     dict(x=20, y=54, w=34, h=16, label="迷雾小径", type="combat"),
                     dict(x=54, y=30, w=40, h=30, label="荧光沼泽", type="water"),
                     dict(x=94, y=88, w=28, h=26, label="树妖祭坛·精英", type="elite"),
                     dict(x=68, y=118, w=14, h=12, label="树洞入口", type="entrance"),
                 ]),
            dungeon_layer("根须迷宫一层", 80, 301, rooms=7),
            dungeon_layer("腐化池二层", 80, 302, rooms=5, hazard="毒雾"),
            dict(name="树心三层 55×55", size=(55, 55), paths=[[(8, 46), (20, 34), (28, 28)]], boss=(28, 28),
                 zones=[
                     dict(x=16, y=15, w=24, h=22, label="树心", type="boss"),
                     dict(x=6, y=42, w=12, h=10, label="入口", type="entrance"),
                 ]),
        ],
    ),
    dict(
        id="04", name="寒霜堡垒", level="Lv 24–32", boss="冰霜巨龙", note="外城 120×120 + 四层要塞",
        layers=[
            dict(name="外城 120×120", size=(120, 120), paths=[[(60, 110), (58, 82), (58, 56), (60, 30), (60, 10)]], boss=None,
                 zones=[
                     dict(x=46, y=70, w=28, h=18, label="校场·安全", type="safe"),
                     dict(x=50, y=100, w=22, h=14, label="关隘", type="combat"),
                     dict(x=18, y=38, w=82, h=12, label="城墙", type="combat"),
                     dict(x=22, y=22, w=26, h=16, label="兵营·精英", type="elite"),
                     dict(x=72, y=20, w=24, h=16, label="冰窖", type="ice"),
                     dict(x=54, y=6, w=12, h=12, label="龙巢入口", type="entrance"),
                 ]),
            dungeon_layer("城墙一层", 75, 401, rooms=5),
            dungeon_layer("兵营二层", 75, 402, rooms=6),
            dungeon_layer("冰窖三层", 75, 403, rooms=4, hazard="冰面"),
            dict(name="龙巢 60×60", size=(60, 60), paths=[[(8, 50), (20, 34), (30, 30)]], boss=(30, 30),
                 zones=[
                     dict(x=17, y=15, w=26, h=24, label="冰霜巨龙", type="boss"),
                     dict(x=6, y=46, w=12, h=10, label="入口", type="entrance"),
                 ]),
        ],
    ),
    dict(
        id="05", name="熔岩深渊", level="Lv 32–40", boss="炎魔", note="五层矿洞，每层 80×80，单线向下",
        layers=[
            dict(name="矿口一层", size=(80, 80), paths=[[(40, 72), (40, 50), (30, 34), (40, 14)]], boss=None,
                 zones=[
                     dict(x=28, y=54, w=24, h=16, label="矿口营地", type="safe"),
                     dict(x=12, y=18, w=20, h=16, label="矿道", type="combat"),
                     dict(x=50, y=18, w=20, h=16, label="矿道", type="combat"),
                     dict(x=34, y=4, w=12, h=10, label="下层入口", type="entrance"),
                 ]),
            dungeon_layer("熔岩河二层", 80, 501, rooms=5, hazard="岩浆"),
            dungeon_layer("铁索桥三层", 80, 502, rooms=4, hazard="岩浆"),
            dungeon_layer("火魔殿四层", 80, 503, rooms=6, hazard="岩浆"),
            dict(name="炎魔巢五层 60×60", size=(60, 60), paths=[[(8, 50), (20, 34), (30, 30)]], boss=(30, 30),
                 zones=[
                     dict(x=16, y=14, w=28, h=26, label="炎魔", type="boss"),
                     dict(x=6, y=46, w=12, h=10, label="入口", type="entrance"),
                 ]),
        ],
    ),
    dict(
        id="06", name="黄泉鬼域", level="Lv 40–47", boss="鬼王", note="鬼城 130×130 + 四层地府",
        layers=[
            dict(name="鬼城 130×130", size=(130, 130), paths=[[(65, 118), (65, 90), (44, 64), (65, 40), (65, 12)]], boss=None,
                 zones=[
                     dict(x=10, y=100, w=18, h=16, label="鬼市·安全", type="safe"),
                     dict(x=56, y=98, w=18, h=18, label="鬼门关", type="entrance"),
                     dict(x=30, y=52, w=28, h=18, label="黄泉路", type="combat"),
                     dict(x=80, y=50, w=26, h=18, label="奈何桥", type="water"),
                     dict(x=52, y=20, w=26, h=22, label="阎罗殿入口", type="elite"),
                 ]),
            dungeon_layer("黄泉路一层", 80, 601, rooms=6),
            dungeon_layer("奈何桥二层", 80, 602, rooms=4, hazard="黄泉"),
            dungeon_layer("阎罗殿三层", 80, 603, rooms=6),
            dict(name="鬼王座 60×60", size=(60, 60), paths=[[(8, 50), (20, 34), (30, 30)]], boss=(30, 30),
                 zones=[
                     dict(x=16, y=14, w=28, h=26, label="鬼王", type="boss"),
                     dict(x=6, y=46, w=12, h=10, label="入口", type="entrance"),
                 ]),
        ],
    ),
    dict(
        id="07", name="天空浮岛", level="Lv 47–53", boss="雷鹏", note="群岛 160×160 + 三层风眼",
        layers=[
            dict(name="群岛 160×160", size=(160, 160), paths=[[(20, 130), (48, 104), (86, 118), (116, 84), (96, 44), (58, 36)]], boss=None,
                 zones=[
                     dict(x=10, y=118, w=20, h=18, label="起飞台·安全", type="safe"),
                     dict(x=36, y=92, w=30, h=26, label="风带", type="combat"),
                     dict(x=76, y=100, w=28, h=26, label="断桥", type="combat"),
                     dict(x=104, y=70, w=30, h=26, label="雷瀑·精英", type="elite"),
                     dict(x=88, y=28, w=24, h=26, label="风眼入口", type="entrance"),
                     dict(x=44, y=22, w=22, h=20, label="残岛", type="combat"),
                 ]),
            dungeon_layer("风眼外层", 70, 701, rooms=5, hazard="强风"),
            dungeon_layer("风眼内层", 70, 702, rooms=5, hazard="强风"),
            dict(name="雷鹏巢 55×55", size=(55, 55), paths=[[(8, 46), (20, 34), (28, 28)]], boss=(28, 28),
                 zones=[
                     dict(x=16, y=15, w=24, h=22, label="雷鹏", type="boss"),
                     dict(x=6, y=42, w=12, h=10, label="入口", type="entrance"),
                 ]),
        ],
    ),
    dict(
        id="08", name="海底龙宫", level="Lv 53–60", boss="龙王", note="外海 140×140 + 四层龙宫",
        layers=[
            dict(name="外海 140×140", size=(140, 140), paths=[[(16, 120), (44, 96), (70, 70), (70, 40), (70, 14)]], boss=None,
                 zones=[
                     dict(x=8, y=108, w=20, h=16, label="珊瑚林", type="combat"),
                     dict(x=36, y=86, w=24, h=18, label="沉船", type="combat"),
                     dict(x=58, y=58, w=26, h=22, label="宫门", type="entrance"),
                     dict(x=58, y=28, w=26, h=18, label="珍珠殿·安全", type="safe"),
                     dict(x=92, y=64, w=30, h=26, label="龙柱阵·精英", type="elite"),
                 ]),
            dungeon_layer("龙宫长廊", 80, 801, rooms=5, hazard="水压"),
            dungeon_layer("珍珠殿二层", 80, 802, rooms=5),
            dungeon_layer("龙柱阵三层", 80, 803, rooms=6, hazard="水压"),
            dict(name="龙王殿 60×60", size=(60, 60), paths=[[(8, 50), (20, 34), (30, 30)]], boss=(30, 30),
                 zones=[
                     dict(x=16, y=14, w=28, h=26, label="龙王", type="boss"),
                     dict(x=6, y=46, w=12, h=10, label="入口", type="entrance"),
                 ]),
        ],
    ),
    dict(
        id="09", name="魔域·血月", level="Lv 60+", boss="魔尊", note="终局野外 160×160 + 五层魔殿",
        layers=[
            dict(name="血月荒原 160×160", size=(160, 160), paths=[[(18, 138), (40, 108), (76, 96), (80, 60), (80, 20)]], boss=None,
                 zones=[
                     dict(x=8, y=122, w=20, h=18, label="祭坛·安全", type="safe"),
                     dict(x=30, y=96, w=30, h=24, label="血月荒原", type="combat"),
                     dict(x=66, y=84, w=28, h=20, label="魔军营地", type="elite"),
                     dict(x=60, y=52, w=26, h=22, label="血池", type="lava"),
                     dict(x=70, y=8, w=20, h=16, label="魔殿入口", type="entrance"),
                 ]),
            dungeon_layer("魔殿一层", 90, 901, rooms=6),
            dungeon_layer("魔殿二层", 90, 902, rooms=6),
            dungeon_layer("魔殿三层", 90, 903, rooms=6, hazard="血雾"),
            dungeon_layer("魔殿四层", 90, 904, rooms=6, hazard="血雾"),
            dict(name="魔尊殿 60×60", size=(60, 60), paths=[[(8, 50), (20, 34), (30, 30)]], boss=(30, 30),
                 zones=[
                     dict(x=15, y=13, w=30, h=28, label="魔尊", type="boss"),
                     dict(x=6, y=46, w=12, h=10, label="入口", type="entrance"),
                 ]),
        ],
    ),
    dict(
        id="10", name="擂台·天下第一", level="Lv 20+", boss="每 5 波", note="50×50 竞技场，10 波连战，三档难度",
        layers=[dict(name="擂台 50×50", size=(50, 50), paths=[[(25, 46), (25, 25)]], boss=(25, 25),
                     zones=[
                         dict(x=10, y=10, w=30, h=30, label="中央石台", type="boss"),
                         dict(x=21, y=1, w=8, h=6, label="北门", type="entrance"),
                         dict(x=21, y=43, w=8, h=6, label="南门", type="entrance"),
                         dict(x=1, y=21, w=6, h=8, label="西门", type="entrance"),
                         dict(x=43, y=21, w=6, h=8, label="东门", type="entrance"),
                     ])],
    ),
]


def draw_layer(draw, layer, box):
    x0, y0, x1, y1 = box
    pw, ph = x1 - x0, y1 - y0
    draw.rounded_rectangle([int(v) for v in box], radius=10, fill=PANEL, outline=(70, 60, 46), width=2)

    draw.text((x0 + 14, y0 + 10), layer["name"], font=F_PANEL, fill=TEXT)
    w, h = layer["size"]
    scale = min((pw - 40) / w, (ph - 90) / h)
    ox = x0 + (pw - w * scale) / 2
    oy = y0 + 58 + (ph - 70 - h * scale) / 2

    def tx(v):
        return ox + v * scale

    def ty(v):
        return oy + v * scale

    draw.rectangle([ox, oy, ox + w * scale, oy + h * scale], fill=(28, 24, 19), outline=(80, 68, 50), width=1)
    step = 10 if w <= 100 else 20
    for gx in range(step, w, step):
        draw.line([(tx(gx), oy), (tx(gx), oy + h * scale)], fill=GRID, width=1)
    for gy in range(step, h, step):
        draw.line([(ox, ty(gy)), (ox + w * scale, ty(gy))], fill=GRID, width=1)

    for path in layer.get("paths", []):
        pts = [(tx(px), ty(py)) for px, py in path]
        if len(pts) > 1:
            draw.line(pts, fill=COLORS["path"], width=max(2, int(scale * 1.2)), joint="curve")

    for z in layer["zones"]:
        color = COLORS.get(z["type"], COLORS["combat"])
        rect = [tx(z["x"]), ty(z["y"]), tx(z["x"] + z["w"]), ty(z["y"] + z["h"])]
        draw.rectangle(rect, fill=color, outline=(240, 232, 214), width=1)
        label = z["label"]
        lx = rect[0] + 4
        ly = rect[1] + 3
        draw.text((lx + 1, ly + 1), label, font=F_LABEL, fill=(0, 0, 0))
        draw.text((lx, ly), label, font=F_LABEL, fill=(250, 248, 240))

    boss = layer.get("boss")
    if boss:
        bx, by = tx(boss[0]), ty(boss[1])
        draw.ellipse([bx - 7, by - 7, bx + 7, by + 7], fill=(255, 80, 60), outline=(255, 220, 160), width=2)

    draw.text((x0 + 14, y1 - 24), f"{w}×{h} 格 · 1 格 = 1 米", font=F_SMALL, fill=MUTED)


def grid_boxes(n, x0, y0, x1, y1):
    if n == 1:
        rows, cols = 1, 1
    elif n == 2:
        rows, cols = 1, 2
    elif n <= 4:
        rows, cols = 2, 2
    else:
        rows, cols = 2, 3
    gap = 18
    bw = (x1 - x0 - gap * (cols - 1)) / cols
    bh = (y1 - y0 - gap * (rows - 1)) / rows
    boxes = []
    for i in range(n):
        r, c = divmod(i, cols)
        bx = x0 + c * (bw + gap)
        by = y0 + r * (bh + gap)
        boxes.append((bx, by, bx + bw, by + bh))
    return boxes


def render_map(m):
    img = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(img)

    d.text((60, 42), f"{m['id']}  {m['name']}", font=F_TITLE, fill=GOLD)
    d.text((60, 104), f"{m['level']}   BOSS：{m['boss']}   {m['note']}", font=F_SUB, fill=MUTED)

    boxes = grid_boxes(len(m["layers"]), 60, 150, 1540, 900)
    for layer, box in zip(m["layers"], boxes):
        draw_layer(d, layer, box)

    legend = [("safe", "安全区"), ("combat", "战斗区"), ("elite", "精英"), ("boss", "BOSS"), ("entrance", "入口"), ("water", "水域/毒雾"), ("lava", "岩浆/血池")]
    lx = 60
    for key, label in legend:
        d.rectangle([lx, 928, lx + 18, 946], fill=COLORS[key])
        d.text((lx + 26, 926), label, font=F_SMALL, fill=TEXT)
        lx += 150

    d.text((1180, 926), "俯视结构示意图 · 非最终美术", font=F_SMALL, fill=MUTED)
    path = os.path.join(OUT, f"{m['id']}_{m['name'].replace('·', '_')}.png")
    img.save(path)
    return path


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for m in MAPS:
        print(render_map(m))
