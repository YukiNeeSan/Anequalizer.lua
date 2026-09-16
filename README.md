# Anequalizer FFmpeg IIR Filter

# MPV 60-Band Anequalizer (VLC Presets)
Adapts popular sound presets from VLC Player and upgrades them to a **60-band** resolution

## ⚙️ Optional Requirement
**FFprobe** (part of FFmpeg). 
   * *Easiest method:* Download `ffprobe.exe` and place it in the same folder as this script, OR make sure FFmpeg is installed on your system's PATH.
   * [Installation Guide](https://github.com/nghiencuuthuoc/FFmpeg-Full-Installation-Guide-for-Windows-11)

## 🚀 Installation
Place the `anequalizer.lua` file into your MPV `scripts` folder:
* **Windows:** `%APPDATA%\mpv\scripts\`
* **Linux / macOS:** `~/.config/mpv/scripts/`

## ⌨️ Usage (Keyboard Shortcuts)

Use the following keys while playing media in MPV:

* **`F1`** : Turn Equalizer OFF (Bypass)
* **`F2` - `F12`** : Select Main Presets *(Classical, Club, Dance, Full Bass, Full Bass & Treble, Full Treble, Headphones, Live, Party, Pop, Rock)*
* **`Ctrl` + `F1` - `F5`** : Select Extra Presets *(Reggae, Ska, Soft, Soft Rock, Techno)*
* **`Ctrl` + `F6` & `F7`** : Activate **Custom 1 & 2** *(Edit the decibel values directly inside the `anequalizer.lua` file using Notepad or any text editor)*

