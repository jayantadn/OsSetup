import subprocess
import time
import shutil
import sys
from pathlib import Path


PROJECT_NAME = "flutter_bench_app"


def run(cmd, cwd=None):
    print(f"\n>>> {' '.join(cmd)}")
    start = time.perf_counter()
    subprocess.run(cmd, cwd=cwd, check=True)
    end = time.perf_counter()
    return end - start


def ensure_flutter():
    try:
        subprocess.run(
            ["flutter", "--version"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=True,
        )
    except Exception:
        print("❌ Flutter not found in PATH")
        sys.exit(1)


def prompt_build_mode():
    print("\nSelect build target:")
    print("  1) Web (flutter build web --release)")
    print("  2) APK (flutter build apk --release)")
    print("  3) Both")

    choice = input("\nEnter choice [1/2/3]: ").strip()

    if choice == "1":
        return "web"
    elif choice == "2":
        return "apk"
    elif choice == "3":
        return "both"
    else:
        print("❌ Invalid choice")
        sys.exit(1)


def create_project(project_dir, timings):
    if project_dir.exists():
        print("Removing existing project directory...")
        shutil.rmtree(project_dir)

    timings["flutter_create"] = run(
        ["flutter", "create", PROJECT_NAME]
    )


def enable_web(timings):
    timings["enable_web"] = run(
        ["flutter", "config", "--enable-web"]
    )


def pub_get(project_dir, timings):
    timings["pub_get"] = run(
        ["flutter", "pub", "get"],
        cwd=project_dir
    )


def build_web(project_dir, timings):
    timings["build_web_release"] = run(
        ["flutter", "build", "web", "--release"],
        cwd=project_dir
    )


def build_apk(project_dir, timings):
    timings["build_apk_release"] = run(
        ["flutter", "build", "apk", "--release"],
        cwd=project_dir
    )


def print_results(timings):
    print("\n===== BENCHMARK RESULTS =====")
    total = 0.0
    for step, seconds in timings.items():
        print(f"{step:24s}: {seconds:.2f} sec")
        total += seconds
    print(f"{'TOTAL':24s}: {total:.2f} sec")


def main():
    ensure_flutter()
    mode = prompt_build_mode()

    project_dir = Path(PROJECT_NAME)
    timings = {}

    try:
        create_project(project_dir, timings)
        pub_get(project_dir, timings)

        if mode in ("web", "both"):
            enable_web(timings)
            build_web(project_dir, timings)

        if mode in ("apk", "both"):
            build_apk(project_dir, timings)

    except subprocess.CalledProcessError as e:
        print("\n❌ Command failed:", e)
        sys.exit(1)

    print_results(timings)


if __name__ == "__main__":
    main()

