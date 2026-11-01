import os
import re
import xml.etree.ElementTree as ET
from pathlib import Path

# Определяем базовые пути относительно директории res
RES_DIR = Path.cwd()
SRC_MAIN_DIR = RES_DIR.parent
KOTLIN_DIR = SRC_MAIN_DIR / "kotlin"
JAVA_DIR = SRC_MAIN_DIR / "java"

OUTPUT_FILE = RES_DIR / "design_analysis_report.txt"

def get_xml_colors():
    """Сбор цветов из values/colors.xml и themes.xml"""
    colors = {}
    values_dir = RES_DIR / "values"
    if not values_dir.exists():
        return colors

    for xml_file in values_dir.glob("*.xml"):
        try:
            tree = ET.parse(xml_file)
            root = tree.getroot()
            for elem in root:
                if elem.tag == "color" and "name" in elem.attrib:
                    colors[elem.attrib["name"]] = elem.text.strip() if elem.text else ""
        except Exception:
            continue
    return colors

def get_compose_colors(code_files):
    """Поиск объявлений цветов в Compose (Color(0x...))"""
    colors = set()
    pattern = re.compile(r"(val|var)\s+([A-Za-z0-9_]+)\s*=\s*(Color\(0x[0-9a-fA-F]+\))")
    for f in code_files:
        try:
            content = f.read_text(encoding="utf-8", errors="ignore")
            for match in pattern.finditer(content):
                colors.add(f"{match.group(2)} = {match.group(3)}")
        except Exception:
            continue
    return sorted(colors)

def get_fonts(code_files):
    """Сбор шрифтов из res/font и определений в коде"""
    fonts = {
        "files": [],
        "compose_references": set()
    }
    
    font_dir = RES_DIR / "font"
    if font_dir.exists():
        for f in font_dir.glob("*"):
            if f.is_file():
                fonts["files"].append(f.name)
                
    # Поиск FontFamily в Compose (Type.kt)
    pattern_compose = re.compile(r"FontFamily\s*\((.*?)\)", re.DOTALL)
    for f in code_files:
        try:
            content = f.read_text(encoding="utf-8", errors="ignore")
            matches = pattern_compose.findall(content)
            for m in matches:
                clean_ref = " ".join(m.split())
                if clean_ref:
                    fonts["compose_references"].add(clean_ref)
        except Exception:
            continue
    return fonts

def get_icons(code_files):
    """Сбор drawable-ресурсов и вызовов Icons.* в Compose"""
    drawables = []
    compose_icons = set()

    # Векторные и растровые иконки в drawable
    for d_path in RES_DIR.glob("drawable*"):
        if d_path.is_dir():
            for f in d_path.glob("*.xml"):
                drawables.append(f.name)

    # Поиск Compose Material Icons (включая Icons.Filled, Icons.Outlined, Icons.Default и др.)
    icon_pattern = re.compile(r"Icons\.(Filled|Outlined|Rounded|Sharp|TwoTone|Default)\.([A-Za-z0-9_]+)")
    
    for f in code_files:
        try:
            content = f.read_text(encoding="utf-8", errors="ignore")
            for match in icon_pattern.finditer(content):
                compose_icons.add(f"Icons.{match.group(1)}.{match.group(2)}")
        except Exception:
            continue

    return sorted(set(drawables)), sorted(compose_icons)

def main():
    # Находим все файлы с исходным кодом Kotlin / Java
    code_files = []
    for directory in [KOTLIN_DIR, JAVA_DIR]:
        if directory.exists():
            code_files.extend(list(directory.rglob("*.kt")))
            code_files.extend(list(directory.rglob("*.java")))

    xml_colors = get_xml_colors()
    compose_colors = get_compose_colors(code_files)
    fonts = get_fonts(code_files)
    drawables, compose_icons = get_icons(code_files)

    with open(OUTPUT_FILE, "w", encoding="utf-8") as out:
        out.write("==============================\n")
        out.write(" ДИЗАЙН-ЭЛЕМЕНТЫ ПРИЛОЖЕНИЯ \n")
        out.write("==============================\n\n")

        # 1. Цвета
        out.write("--- 1. ЦВЕТА ---\n")
        out.write("[XML Colors (values/colors.xml)]:\n")
        if xml_colors:
            for name, val in xml_colors.items():
                out.write(f"  - @color/{name}: {val}\n")
        else:
            out.write("  (Цвета в XML не найдены)\n")

        out.write("\n[Jetpack Compose Colors]:\n")
        if compose_colors:
            for c in compose_colors:
                out.write(f"  - {c}\n")
        else:
            out.write("  (Определения Compose Color() не найдены)\n")

        # 2. Шрифты
        out.write("\n--- 2. ШРИФТЫ ---\n")
        out.write("[Файлы шрифтов в res/font/]:\n")
        if fonts["files"]:
            for f in fonts["files"]:
                out.write(f"  - {f}\n")
        else:
            out.write("  (Шрифты в res/font/ отсутствуют)\n")

        out.write("\n[Семейства шрифтов в Compose/Kotlin]:\n")
        if fonts["compose_references"]:
            for ref in sorted(fonts["compose_references"]):
                out.write(f"  - FontFamily: {ref}\n")
        else:
            out.write("  (Кастомные FontFamily в коде не обнаружены)\n")

        # 3. Иконки
        out.write("\n--- 3. ИКОНКИ ---\n")
        out.write("[Compose Material Icons (из material.icons.extended)]:\n")
        if compose_icons:
            for icon in compose_icons:
                out.write(f"  - {icon}\n")
        else:
            out.write("  (Вызовы Icons.* в коде не найдены)\n")

        out.write(f"\n[Локальные Drawable ресурсы (всего {len(drawables)})]:\n")
        if drawables:
            for d in drawables:
                out.write(f"  - {d}\n")
        else:
            out.write("  (Файлы в папках drawable не найдены)\n")

    print(f"Готово! Результаты сохранены в файл:\n{OUTPUT_FILE}")

if __name__ == "__main__":
    main()