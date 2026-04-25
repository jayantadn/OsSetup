# Home Configuration
# ZIP = "T:\\ProgramFiles\\7-ZipPortable\\App\\7-Zip64\\7zG.exe"
# BUPDIR = "X:\\Backup"
# OUTLOOK = "C:\\Program Files (x86)\\Microsoft Office\\root\\Office16\\OUTLOOK.EXE"

# Office Configuration
import clipboard
import shutil
import time
import subprocess
import sys
import os
import platform

if platform.system() == "Windows":
    import win32wnet
    import msvcrt


ZIP = "C:\\Program Files\\7-Zip\\7zG.exe"
BUPDIR = "C:\\Users\\jyd1kor\\OneDrive - Bosch Group\\Main\\Backup"
OUTLOOK = "C:\\Program Files\\Microsoft Office\\root\\Office16\\OUTLOOK.EXE"
PLANTUML = "C:\\Users\\jyd1kor\\OneDrive - Bosch Group\\Main\\Software_Win\\PlantUML\\plantuml-1.2025.7.jar"

# A custom assert implementation


def myassert(expr, msg):
    if not expr:
        print("ERROR: " + msg)
        input("Press enter to exit...")
        exit(1)


# All imports


# Compress a list of files provided
def Compress(filelist):
    # compute the output file name
    if len(filelist) == 1:
        if platform.system() == "Windows":
            outfile = filelist[0].rstrip("\\") + ".zip"
        else:
            outfile = filelist[0].rstrip("/") + ".tar.gz"
    elif len(filelist) > 1:
        dirname = os.path.dirname(filelist[0])
        if not dirname:
            dirname = os.getcwd()
        outfile = os.path.join(dirname, os.path.basename(dirname) + ".zip")
    else:
        myassert(False, "Invalid number of parameters")

    # Execute 7z command to compress given files
    if platform.system() == "Windows":
        command = [ZIP, "a", "-tzip", "-mx9",  outfile]
    else:
        command = ["tar", "-zcvf",  outfile]
    for file in filelist:
        myassert(os.path.exists(file), "File does not exist: " + file)
        if platform.system() == "Windows":
            command.append(file.rstrip("\\"))
        else:
            command.append(file.rstrip("/"))
    try:
        ret = subprocess.call(command)
        myassert(ret == 0, "Failed to execute Compress command")
        return outfile
    except:
        myassert(False, "Failed to execute Compress command")

# Uncompress a zip file


def Uncompress(zipfile):
    outdir = os.path.dirname(zipfile)
    if hasMultiFiles(zipfile):
        outdir = os.path.join(outdir, os.path.basename(zipfile).split(".")[0])

    try:
        flg_delete = False
        if zipfile.find(".tar.") != -1:
            ret = subprocess.call([ZIP, "x", zipfile, "-o" + outdir, "-y"])
            myassert(ret == 0, "Could not extract archive")
            zipfile, _ = os.path.splitext(zipfile)
            flg_delete = True
        ret = subprocess.call([ZIP, "x", zipfile, "-o" + outdir, "-y"])
        myassert(ret == 0, "Could not extract archive")
        if flg_delete:
            os.unlink(zipfile)
    except:
        myassert(False, "Could not extract archive")


# checks if the zip file has multiple files/folders at root level
def hasMultiFiles(zipfile):
    # for listing files of an archive, we need pure command line
    ZIPL = os.path.join(os.path.dirname(ZIP), "7z.exe")
    try:
        out = subprocess.check_output([ZIPL, "l", zipfile]).decode("utf-8")
    except:
        myassert(False, "Could not list contents of archive")

    lines = out.splitlines()
    # safe to skip the first file, as its always going to be a root level file/folder
    linenum = lines.index(
        "------------------- ----- ------------ ------------  ------------------------") + 2
    lines.reverse()
    endlinenum = len(lines) - lines.index(
        "------------------- ----- ------------ ------------  ------------------------") - 1
    lines.reverse()
    while linenum < endlinenum:
        if "\\" not in lines[linenum]:
            return True
        linenum += 1
    return False


# Copy file path in different formats
def CopyPath(filelist):
    # populate unorganized list.
    # This is the main logic where you add different path types.
    # rest of the function dont change
    unorglist = []
    for file in filelist:
        unorglist.append(file)
        unorglist.append(file.replace("\\", "\\\\"))
        file_posix = file.replace("\\", "/")
        unorglist.append(file_posix)
        unorglist.append(file_posix.replace("C:", "/mnt/c"))  # WSL
        try:
            unorglist.append(win32wnet.WNetGetUniversalName(file, 1))
        except:
            pass

    # create set of organized lists
    orglist = []
    numpath = int(len(unorglist) / len(filelist))
    for i in range(numpath):
        orglist.append([])
    i = 0
    for path in unorglist:
        if i >= numpath:
            i = 0
        orglist[i].append(path)
        i += 1

    # display menu
    i = 1
    for item in orglist:
        print(i, item[0], end="")
        if len(item) > 1:
            print(", ", item[1], " ...")
        else:
            print("")
        i += 1
    print("Enter your choice: ")
    idx = int(msvcrt.getch()) - 1

    # copy to clipboard
    txt = ""
    if len(orglist[idx]) == 1:
        txt = orglist[idx][0]
    else:
        for item in orglist[idx]:
            txt = txt + item + "\n"
    clipboard.copy(txt)


# program entry point
if __name__ == "__main__":
    # doing some common sanity checks
    if platform.system() == "Windows":
        myassert(os.path.exists(ZIP), "7z path invalid")
        myassert(os.path.isdir(BUPDIR), "Backup folder is invalid")
    myassert(len(sys.argv) > 2, "Insufficient parameters")

    # converting each file name into full path
    filelist = [sys.argv[2].rstrip("\\")]
    dirname = os.path.dirname(sys.argv[2])
    i = 3
    while i < len(sys.argv):
        filelist.append(os.path.join(dirname, sys.argv[i].rstrip("\\")))
        i += 1

    if sys.argv[1] == "Compress":
        Compress(filelist)

    elif sys.argv[1] == "Uncompress":
        myassert(len(sys.argv) == 3, "Invalid number of parameters")
        myassert(os.path.exists(sys.argv[2]), "Zip file does not exist")
        Uncompress(sys.argv[2])

    elif sys.argv[1] == "BackupDir":
        zipfile = Compress(filelist)
        timestamp = time.strftime("%Y%m%d_%H%M%S_", time.localtime())
        if platform.system() == "Linux":
            BUPDIR = BUPDIR.replace("\\", "/")
            BUPDIR = BUPDIR.replace("C:", "/mnt/c")
        shutil.move(zipfile, os.path.join(
            BUPDIR, timestamp + os.path.basename(zipfile)))

    elif sys.argv[1] == "BackupFile":
        myassert(len(sys.argv) == 3,
                 "This operation can take only a single file")
        myassert(os.path.isfile(sys.argv[2]), "Invalid file")
        timestamp = time.strftime("%Y%m%d_%H%M%S_", time.localtime())
        shutil.copy(sys.argv[2], os.path.join(
            BUPDIR, timestamp + os.path.basename(sys.argv[2])))

    elif sys.argv[1] == "CopyPath":
        CopyPath(filelist)

    elif sys.argv[1] == "Email":
        print(filelist)
        if len(filelist) > 1 or filelist[0].endswith(".bat") or (len(filelist) == 1 and os.path.isdir(filelist[0])):
            filename = Compress(filelist)
        else:
            filename = filelist[0]
        try:
            # ret = subprocess.call( OUTLOOK + " /c ipm.note /m ?subject=" + os.path.basename(filename) + " /a " + filename )
            filename_new = os.path.join(
                os.environ['temp'], os.path.basename(filename).replace(' ', '_'))
            shutil.copyfile(filename, filename_new)
            ret = subprocess.call(OUTLOOK + " /c ipm.note /m ?subject=" +
                                  os.path.basename(filename_new) + " /a " + filename_new)
            if filename.endswith(".zip"):
                time.sleep(1)
                os.remove(filename)
            myassert(ret == 0, "Could not launch Outlook")
        except:
            myassert(False, "Could not launch Outlook")

    elif sys.argv[1] == "RenameImages":
        myassert(False, "Function not implemented")

    elif sys.argv[1] == "RenameSubtitles":
        myassert(len(sys.argv) == 3, "Invalid number of parameters")
        folder = sys.argv[2].rstrip("\\")
        if not os.path.isdir(folder):
            folder = os.path.dirname(folder)
        filelist = os.listdir(folder)
        for file in filelist:
            if file.endswith("-eng.srt"):
                os.rename(file, file.replace("-eng.srt", ".srt"))

    elif sys.argv[1] == "PlantUML":
        # Check Java version before executing
        try:
            java_version_output = subprocess.check_output(['java', '-version'], stderr=subprocess.STDOUT, text=True)
            # Extract version number from output like "java version "21.0.1"" or "openjdk version "19.0.2""
            import re
            version_match = re.search(r'version "(\d+)\.?(\d*)', java_version_output)
            if version_match:
                major_version = int(version_match.group(1))
                if major_version <= 18:
                    myassert(False, f"Java version {major_version} is too old. Minimum required version is 19. Please update Java.")
            else:
                myassert(False, "Could not determine Java version")
        except subprocess.CalledProcessError:
            myassert(False, "Java is not installed or not in PATH")
        except FileNotFoundError:
            myassert(False, "Java is not installed or not in PATH")
        
        # Get the directory of the input file
        outdir = os.path.dirname(filelist[0])
        cmd = f'java -jar "{PLANTUML}" "{filelist[0]}" -o "{outdir}"'
        subprocess.call(cmd)
        pngfile = os.path.splitext(os.path.basename(filelist[0]))[0]
        pngfile = os.path.join(outdir, f"{pngfile}.png")
        os.system(f'start "" "{pngfile}"')

    else:
        myassert(False, "Invalid command")
