# Jimaku

Jimaku（字幕）是離線的即時中文字幕，用 [Spinel](https://github.com/matz/spinel) 把 Ruby 編譯成原生執行檔。全程不連網，音訊與模型都留在本機。

```
+------------------+
| Microphone (a)   |
+------------------+
         | audio
         v
+------------------+
| Silero VAD (b)   |
+------------------+
         | sentence
         v
+------------------+
| Breeze ASR (c)   |
+------------------+
         | text
         v
+------------------+
| Subtitle Bar (d) |
+------------------+
```

- (a) 透過 macOS AudioQueue 收音，保留最近 60 秒。
- (b) 靜音達 250 毫秒時，切出一句話。
- (c) 經由 whisper.cpp 把一句話轉成中文。
- (d) 螢幕底部的 AppKit 視窗，終端機也會印出同一行。

## 系統需求

這個示範直接呼叫 macOS 的框架，只能在 Apple Silicon 的 Mac 上執行。

| 工具 | 用途 |
|------|------|
| Spinel 的 `spin` | 編譯並執行 Ruby |
| Ruby 與 `rake` | 執行安裝任務 |
| `git`、`cmake` | 建置 whisper.cpp |
| Hugging Face 的 `hf` | 下載模型 |

## 安裝步驟

安裝只需執行一次，之後重複執行會跳過已完成的部分。

1. 執行 `rake`，把 whisper.cpp v1.9.4 建置到 `vendor/whisper`。
2. 等待同一個任務把兩個模型下載到 Hugging Face 快取。
3. 確認終端機已取得麥克風權限。

| 模型 | 檔案 |
|------|------|
| [Breeze ASR 25](https://huggingface.co/tsuzuri-app/Breeze-ASR-25-ggml) | `ggml-breeze-asr-25-q5_0.bin` |
| [Silero VAD](https://huggingface.co/ggml-org/whisper-vad) | `ggml-silero-v6.2.0.bin` |

## 執行方式

`spin run` 會先編譯 `bin/jimaku.rb`，再啟動程式。

```bash
spin run
```

開始說話後，字幕列與終端機會同時顯示辨識結果。按 Ctrl+C 結束程式。

## 程式結構

每個檔案負責流程中的一個環節，`bin/jimaku.rb` 把它們串起來。

| 檔案 | 負責 |
|------|------|
| `microphone.rb` | 收音並保留最近 60 秒 |
| `sentence_detector.rb` | 找出一句話的起訖 |
| `transcriber.rb` | 把一句話轉成文字 |
| `subtitle_bar.rb` | 顯示字幕列 |
| `hugging_face_cache.rb` | 找到已下載的模型 |
| `speech.c` | 傳遞 whisper.cpp 的參數結構 |

## 原生呼叫

所有原生功能都透過 Spinel 的 FFI 呼叫，不依賴任何 gem。

| 對象 | 呼叫方式 |
|------|----------|
| AudioQueue | 回呼直接執行 Ruby 方法 |
| AppKit | 經由 `objc_msgSend` 傳送訊息 |
| whisper.cpp | 靜態連結 `libwhisper.a` |

whisper.cpp 有些函式以傳值方式接收結構，FFI 無法傳遞，因此由 `speech.c` 包裝成只收指標與數值的函式。
