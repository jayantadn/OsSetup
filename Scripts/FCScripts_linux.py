#!/usr/bin/env python3
"""
fc_linux_backup.py

Linux-only replacement for FCScripts.py (Windows bits removed).
Uses tar (via Python's tarfile) as archive tool.

Default backup path is set via DEFAULT_BACKUP_DIR.
"""

import argparse
import tarfile
import os
import sys
import shutil
import time
from pathlib import Path

# === Default backup path (change as needed) ===
DEFAULT_BACKUP_DIR = "/mnt/c/Users/jyd1kor/OneDrive - Bosch Group/Main/Backup"


def die(msg, rc=1):
    print("ERROR:", msg, file=sys.stderr)
    sys.exit(rc)


def make_timestamp():
    return time.strftime("%Y%m%d_%H%M%S_", time.localtime())


def compress(paths, outpath=None, gzip=True):
    paths = [Path(p) for p in paths]
    for p in paths:
        if not p.exists():
            die(f"Path does not exist: {p}")

    if outpath:
        outpath = Path(outpath)
    else:
        if len(paths) == 1:
            outpath = paths[0].with_suffix('.tar.gz') if gzip else paths[0].with_suffix('.tar')
        else:
            parent = paths[0].parent or Path.cwd()
            outpath = parent.joinpath(parent.name + ('.tar.gz' if gzip else '.tar'))

    mode = 'w:gz' if gzip else 'w'
    try:
        with tarfile.open(outpath, mode) as tf:
            for p in paths:
                tf.add(p, arcname=p.name)
    except Exception as e:
        die(f"Failed to create archive {outpath}: {e}")
    print(f"Created archive: {outpath}")
    return outpath


def uncompress(archive, dest=None):
    archive = Path(archive)
    if not archive.exists():
        die(f"Archive does not exist: {archive}")
    if dest is None:
        dest = archive.parent
    else:
        dest = Path(dest)
        dest.mkdir(parents=True, exist_ok=True)

    try:
        with tarfile.open(archive, 'r:*') as tf:
            members = tf.getmembers()
            top_levels = set(m.name.split('/')[0] for m in members if m.name)
            if len(top_levels) > 1:
                outdir = dest.joinpath(archive.stem)
                outdir.mkdir(parents=True, exist_ok=True)
                tf.extractall(path=outdir)
                print(f"Extracted {archive} -> {outdir}")
            else:
                tf.extractall(path=dest)
                print(f"Extracted {archive} -> {dest}")
    except Exception as e:
        die(f"Failed to extract {archive}: {e}")


def _verify_archive(path):
    try:
        with tarfile.open(path, 'r:*') as tf:
            for _ in tf.getmembers()[:1]:
                break
        return True
    except Exception as e:
        print(f"Archive verification failed for {path}: {e}", file=sys.stderr)
        return False


def backup_dir(src_dir, bupdir, keep=None, gzip=True):
    src = Path(src_dir).resolve()
    if not src.exists():
        die(f"Source path does not exist: {src}")
    if not src.is_dir():
        die(f"BackupDir expects a directory: {src}")

    bup = Path(bupdir).expanduser().resolve()
    bup.mkdir(parents=True, exist_ok=True)

    timestamp = make_timestamp()
    temp_dir = Path("/tmp")
    local_archive = temp_dir.joinpath(f"{src.name}.tar.gz" if gzip else f"{src.name}.tar")
    if local_archive.exists():
        local_archive = temp_dir.joinpath(f"{src.name}_{os.getpid()}.tar.gz")

    print(f"Compressing {src} -> {local_archive} ...")
    compress([src], outpath=local_archive, gzip=gzip)

    if not _verify_archive(local_archive):
        try:
            local_archive.unlink()
        except Exception:
            pass
        die("Archive verification failed; aborting BackupDir.")

    final_name = f"{timestamp}{local_archive.name}"
    final_path = bup.joinpath(final_name)
    try:
        shutil.move(str(local_archive), final_path)
    except Exception as e:
        die(f"Could not move archive to backup dir: {e}")

    try:
        final_path.chmod(0o644)
    except Exception:
        pass

    print(f"Backup created: {final_path}")

    if keep is not None:
        try:
            keep = int(keep)
            pattern = f"{src.name}"
            backups = sorted(
                [p for p in bup.iterdir() if p.is_file() and p.name.endswith('.tar.gz') and pattern in p.name],
                key=lambda p: p.stat().st_mtime,
                reverse=True
            )
            if len(backups) > keep:
                for f in backups[keep:]:
                    try:
                        print(f"Removing old backup: {f}")
                        f.unlink()
                    except Exception as e:
                        print(f"Warning: could not remove {f}: {e}", file=sys.stderr)
        except ValueError:
            print("Warning: invalid keep value; skipping rotation", file=sys.stderr)

    return final_path


def backup_file(src_file, bupdir):
    src = Path(src_file).resolve()
    if not src.exists() or not src.is_file():
        die(f"BackupFile expects an existing file: {src}")
    bup = Path(bupdir).expanduser().resolve()
    bup.mkdir(parents=True, exist_ok=True)
    timestamp = make_timestamp()
    dest = bup.joinpath(timestamp + src.name)
    try:
        shutil.copy2(src, dest)
        dest.chmod(0o644)
    except Exception as e:
        die(f"Failed to copy file to backup dir: {e}")
    print(f"Copied {src} -> {dest}")
    return dest


def main(argv=None):
    parser = argparse.ArgumentParser(prog="fc_linux_backup.py", description="Linux backup utilities (tar-based).")
    sub = parser.add_subparsers(dest='cmd', required=True)

    p_comp = sub.add_parser('Compress', help='Compress one or more paths into a tar.gz')
    p_comp.add_argument('paths', nargs='+', help='Files or directories to compress')
    p_comp.add_argument('--out', help='Optional output archive path')

    p_un = sub.add_parser('Uncompress', help='Extract a tar/tar.gz archive')
    p_un.add_argument('archive', help='Archive to extract')
    p_un.add_argument('--dest', help='Extraction destination')

    p_bdir = sub.add_parser('BackupDir', help='Backup a directory into DEFAULT_BACKUP_DIR (or override)')
    p_bdir.add_argument('dir', help='Directory to back up')
    p_bdir.add_argument('--bupdir', default=DEFAULT_BACKUP_DIR, help=f'Backup directory (default: {DEFAULT_BACKUP_DIR})')
    p_bdir.add_argument('--keep', type=int, help='Keep only N most recent backups')

    p_bfile = sub.add_parser('BackupFile', help='Backup a file into DEFAULT_BACKUP_DIR (or override)')
    p_bfile.add_argument('file', help='File to back up')
    p_bfile.add_argument('--bupdir', default=DEFAULT_BACKUP_DIR, help=f'Backup directory (default: {DEFAULT_BACKUP_DIR})')

    args = parser.parse_args(argv)

    if args.cmd == 'Compress':
        compress(args.paths, outpath=args.out)

    elif args.cmd == 'Uncompress':
        uncompress(args.archive, dest=args.dest)

    elif args.cmd == 'BackupDir':
        backup_dir(args.dir, args.bupdir, keep=args.keep)

    elif args.cmd == 'BackupFile':
        backup_file(args.file, args.bupdir)


if __name__ == '__main__':
    main()
