from pathlib import Path
import os

src = Path(r"C:\Code\dotfiles\nvim")
dest = Path(r"C:\Users\NMiller\AppData\Local\nvim")

print("Source exists?", src.exists())
print("Destination exists?", dest.exists())

if src.exists():
    os.symlink(src, dest, target_is_directory=True)
    print("Symlink created:", dest.exists())
