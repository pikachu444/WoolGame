"""Reproducible local builds, using Godot's runtime resource and PCK APIs.

Usage: python Rebuild/tools/build.py [--android]
Requires the pinned tools already installed in Tools/Godot and Unity's Android SDK.
All intermediate files stay in BuildWork. Existing Unity source is never used.
"""
from __future__ import annotations
import argparse
import hashlib
import os
from pathlib import Path
import re
import shutil
import struct
import subprocess
import time
import zipfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
PROJECT = ROOT / "Rebuild"
OUTPUT = ROOT / "Builds/Rebuild"
WORK = ROOT / "BuildWork"
EVIDENCE = ROOT / "Evidence/Rebuild/Representative/Verification/Build"
GODOT = ROOT / "Tools/Godot/Godot_v4.7.2-stable_win64.exe"
APKTOOL = ROOT / "Tools/Godot/apktool_3.0.3.jar"
ANDROID = ROOT / "Tools/Unity/Editor/Data/PlaybackEngines/AndroidPlayer"
SDK = ANDROID / "SDK"
JAVA = ANDROID / "OpenJDK/bin/java.exe"
BUILD_TOOLS = SDK / "build-tools/36.0.0"
ENV = os.environ.copy()
ENV.setdefault("APPDATA", str(Path.home() / "AppData/Roaming"))
ENV.setdefault("LOCALAPPDATA", str(Path.home() / "AppData/Local"))
ENV.setdefault("PROCESSOR_ARCHITECTURE", "AMD64")
TEMPLATES = Path(ENV["APPDATA"]) / "Godot/export_templates/4.7.2.stable"


def run(args, log=None, env=None):
    result = subprocess.run([str(a) for a in args], env=env or ENV,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                            timeout=180,
                            creationflags=subprocess.CREATE_NO_WINDOW)
    try:
        result.stdout=result.stdout.decode("utf-8")
    except UnicodeDecodeError:
        result.stdout=result.stdout.decode("cp949",errors="replace")
    if log:
        Path(log).write_text(result.stdout, encoding="utf-8")
    if result.returncode or "SCRIPT ERROR:" in result.stdout or "\nERROR:" in result.stdout:
        raise RuntimeError(result.stdout)
    print(result.stdout.strip())
    return result.stdout


def desktop():
    for folder in (OUTPUT, WORK, EVIDENCE):
        folder.mkdir(parents=True, exist_ok=True)
    run([GODOT, "--headless", "--path", PROJECT, "-s", "res://tests/prepare_assets.gd"])
    run([GODOT, "--headless", "--path", PROJECT, "-s", "res://tests/verify_campaign.gd"], EVIDENCE / "rules.log")
    run([GODOT, "--headless", "--path", PROJECT, "-s", "res://tests/verify_stage_progression.gd"], EVIDENCE / "stage-progression.log")
    run([GODOT, "--headless", "--path", PROJECT, "-s", "res://tests/verify_representative.gd", "--", "--out", EVIDENCE.parent / "Representative"], EVIDENCE / "representative.log")
    profile = WORK / "TestProfile" / str(int(time.time()))
    profile.mkdir(parents=True, exist_ok=True)
    test_env = dict(ENV, APPDATA=str(profile))
    run([GODOT, "--headless", "--path", PROJECT, "-s", "res://tests/verify_ui.gd", "--", "--profile-dir", profile], EVIDENCE / "ui.log", test_env)
    run([GODOT, "--headless", "--path", PROJECT, "-s", "res://tests/build_pack.gd", "--", OUTPUT / "WoolRescue.pck"])
    shutil.copy2(TEMPLATES / "windows_release_x86_64.exe", OUTPUT / "WoolRescue.exe")
    for file in (PROJECT / "licenses").glob("*.txt"):
        shutil.copy2(file, OUTPUT / file.name)
    shutil.copy2(PROJECT / "art/FONT_LICENSE.txt", OUTPUT / "FONT_LICENSE.txt")
    shutil.copy2(PROJECT / "PLAYER_README.txt", OUTPUT / "읽어주세요.txt")
    package_windows()


def package_windows():
    names=["WoolRescue.exe","WoolRescue.pck","FONT_LICENSE.txt","GODOT_LICENSE.txt","GODOT_COPYRIGHT.txt","읽어주세요.txt"]
    with zipfile.ZipFile(OUTPUT / "WoolRescue-Windows.zip","w",zipfile.ZIP_DEFLATED,compresslevel=6) as archive:
        for name in names:
            archive.write(OUTPUT / name,"WoolRescue/"+name)


def android():
    folder = WORK / "GodotAndroid"
    if not (folder / "apktool.yml").exists():
        run([JAVA, "-jar", APKTOOL, "d", "-s", "-o", folder, TEMPLATES / "android_debug.apk"])
    manifest = folder / "AndroidManifest.xml"
    text = manifest.read_text(encoding="utf-8")
    text = text.replace('package="com.godot.game"', 'package="com.woolrescue.game"')
    text = text.replace('android:authorities="com.godot.game.', 'android:authorities="com.woolrescue.game.')
    text = text.replace('android:screenOrientation="landscape"', 'android:screenOrientation="portrait"')
    text = text.replace('android:supportsPictureInPicture="true"', 'android:supportsPictureInPicture="false"')
    text = text.replace('android:icon="@mipmap/icon"', 'android:icon="@drawable/wool_icon"')
    namespace="http://schemas.android.com/apk/res/android"
    ET.register_namespace("android",namespace)
    xml=ET.fromstring(text)
    app=xml.find("application")
    main=next(a for a in app.findall("activity") if a.get("{"+namespace+"}name")=="com.godot.game.GodotApp")
    main.set("{"+namespace+"}exported","true")
    for alias in app.findall("activity-alias"):
        for intent in alias.findall("intent-filter"):
            main.append(intent)
        app.remove(alias)
    ET.ElementTree(xml).write(manifest,encoding="utf-8",xml_declaration=True)
    for strings in (folder / "res").glob("values*/strings.xml"):
        text = strings.read_text(encoding="utf-8")
        text = re.sub(r'(<string name="godot_project_name_string">).*?(</string>)', r'\1털실 구조대\2', text)
        strings.write_text(text, encoding="utf-8")
    icon_folder = folder / "res/drawable-nodpi"
    icon_folder.mkdir(exist_ok=True)
    shutil.copy2(PROJECT / "art/app_icon.png", icon_folder / "wool_icon.png")
    # Keep the native Android launch screen in the same visual direction as the game.
    for styles in (folder / "res").glob("values*/styles.xml"):
        text = styles.read_text(encoding="utf-8")
        def splash(match):
            block = match.group(0)
            block = re.sub(r'(<item name="(?:android:)?windowSplashScreenAnimatedIcon">).*?(</item>)', r'\1@drawable/wool_icon\2', block)
            block = re.sub(r'(<item name="(?:android:)?windowSplashScreenBackground">).*?(</item>)', r'\1#c5e1ef\2', block)
            block = re.sub(r'(<item name="android:windowSplashScreenBrandingImage">).*?(</item>)', r'\1@null\2', block)
            return block
        text = re.sub(r'<style name="GodotAppSplashTheme".*?</style>', splash, text, flags=re.S)
        styles.write_text(text, encoding="utf-8")
    settings = folder / "apktool.yml"
    text = settings.read_text(encoding="utf-8")
    text = re.sub(r"minSdkVersion: \d+", "minSdkVersion: 26", text)
    text = re.sub(r"versionName: .*", "versionName: 0.5.0", text)
    text = re.sub(r"versionCode: \d+", "versionCode: 5", text)
    for value in ("pck", "assets/_cl_"):
        if "\n- " + value + "\n" not in text:
            text += "\n- " + value + "\n"
    settings.write_text(text, encoding="utf-8")
    assets = folder / "assets"
    assets.mkdir(exist_ok=True)
    args = [b"--main-pack", b"res://game.pck"]
    (assets / "_cl_").write_bytes(struct.pack("<I", len(args)) + b"".join(struct.pack("<I", len(a)) + a for a in args))
    shutil.copy2(OUTPUT / "WoolRescue.pck", assets / "game.pck")
    license_dir = assets / "licenses"
    license_dir.mkdir(exist_ok=True)
    for file in (PROJECT / "licenses").glob("*.txt"):
        shutil.copy2(file, license_dir / file.name)
    shutil.copy2(PROJECT / "art/FONT_LICENSE.txt", license_dir / "FONT_LICENSE.txt")
    all_abis = WORK / "WoolRescue-all-unaligned.apk"
    run([JAVA, "-jar", APKTOOL, "b", "--aapt", BUILD_TOOLS / "aapt2.exe", folder, "-o", all_abis], EVIDENCE / "android-build.log")
    arm64 = WORK / "WoolRescue-arm64-unaligned.apk"
    with zipfile.ZipFile(all_abis) as source, zipfile.ZipFile(arm64, "w") as target:
        for entry in source.infolist():
            if entry.filename.startswith("lib/") and not entry.filename.startswith("lib/arm64-v8a/"):
                continue
            target.writestr(entry, source.read(entry.filename))
    aligned = WORK / "WoolRescue-aligned.apk"
    run([BUILD_TOOLS / "zipalign.exe", "-f", "-P", "16", "4", arm64, aligned])
    key = Path.home() / ".android/debug.keystore"
    if not key.exists():
        key = WORK / "wool-debug.keystore"
        if not key.exists():
            run([JAVA.parent / "keytool.exe", "-genkeypair", "-keystore", key, "-storepass", "android",
                 "-alias", "androiddebugkey", "-keypass", "android", "-keyalg", "RSA", "-keysize", "2048",
                 "-validity", "10000", "-dname", "CN=Android Debug,O=Android,C=US"])
    apk = OUTPUT / "WoolRescue-Android.apk"
    signer = BUILD_TOOLS / "lib/apksigner.jar"
    run([JAVA, "-jar", signer, "sign", "--ks", key, "--ks-key-alias", "androiddebugkey",
         "--ks-pass", "pass:android", "--key-pass", "pass:android", "--out", apk, aligned])
    run([JAVA, "-jar", signer, "verify", "--verbose", apk], EVIDENCE / "android-signature.log")
    run([BUILD_TOOLS / "zipalign.exe", "-c", "-P", "16", "4", apk], EVIDENCE / "android-alignment.log")
    metadata=run([BUILD_TOOLS / "aapt2.exe", "dump", "badging", apk], EVIDENCE / "android-package.log")
    assert "launchable-activity:" in metadata
    assert "godot-project-name" not in metadata
    with zipfile.ZipFile(apk) as archive:
        assert archive.read("assets/game.pck") == (OUTPUT / "WoolRescue.pck").read_bytes()
        assert archive.read("assets/_cl_") == (assets / "_cl_").read_bytes()
        assert "lib/arm64-v8a/libgodot_android.so" in archive.namelist()
    print("Android package verified. Device gameplay must be checked separately.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--android", action="store_true")
    args = parser.parse_args()
    desktop()
    if args.android:
        android()
    files = [file for file in OUTPUT.iterdir() if file.suffix in (".exe", ".pck", ".apk", ".zip")]
    (OUTPUT / "SHA256SUMS.txt").write_text("".join(hashlib.sha256(f.read_bytes()).hexdigest() + "  " + f.name + "\n" for f in files), encoding="utf-8")
