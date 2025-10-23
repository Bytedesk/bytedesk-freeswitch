# FreeSWITCH 声音包与音乐资源下载与安装说明

本说明文档整理了 FreeSWITCH 官方声音提示包（sounds）与默认音乐（music）的下载地址、推荐采样率、安装步骤、验证方法，以及拨号计划中的使用示例。适用于当前部署在 14.103.165.199 的 FreeSWITCH（Ubuntu 22.04，默认声音目录位于 `/usr/local/freeswitch/sounds`）。

## 官方下载目录

- 声音提示（英语 en-us-callie）
  - 8000Hz: https://files.freeswitch.org/releases/sounds/freeswitch-sounds-en-us-callie-8000-1.0.52.tar.gz
  - 16000Hz: https://files.freeswitch.org/releases/sounds/freeswitch-sounds-en-us-callie-16000-1.0.52.tar.gz
  - 32000Hz: https://files.freeswitch.org/releases/sounds/freeswitch-sounds-en-us-callie-32000-1.0.52.tar.gz
  - 48000Hz: https://files.freeswitch.org/releases/sounds/freeswitch-sounds-en-us-callie-48000-1.0.52.tar.gz

- 默认音乐（MOH）
  - 48000Hz: https://files.freeswitch.org/releases/music/freeswitch-sounds-music-48000-1.0.7.tar.gz
  - 32000Hz: https://files.freeswitch.org/releases/music/freeswitch-sounds-music-32000-1.0.7.tar.gz
  - 16000Hz: https://files.freeswitch.org/releases/music/freeswitch-sounds-music-16000-1.0.7.tar.gz
  - 8000Hz:  https://files.freeswitch.org/releases/music/freeswitch-sounds-music-8000-1.0.7.tar.gz

- 目录索引（如需查看可用文件）：
  - 默认音乐目录索引：https://files.freeswitch.org/releases/music/

提示：部分旧版本（如 1.0.2/1.0.3/1.0.5/1.0.6/1.0.7）仍可用，如果遇到 404，可以访问目录索引确认具体文件名后再下载。

## 采样率如何选择
- WebRTC（浏览器）场景：推荐 48000Hz（与浏览器音频栈一致，减少重采样）。
- 传统窄带（如 G.711）场景：可选 8000Hz。
- 宽带语音：16k/32k 也可选，具体视业务链路/终端能力而定。
- 可并存多种采样率目录，FreeSWITCH 会按配置/通道能力选择或重采样；为提升质量，尽量选与终端一致的采样率。

- 声音提示（中文普通话 zh-cn-sinmei，主要包含数字/时间类短语）
  - 8000Hz: https://files.freeswitch.org/releases/sounds/freeswitch-sounds-zh-cn-sinmei-8000-1.0.51.tar.gz
  - 16000Hz: https://files.freeswitch.org/releases/sounds/freeswitch-sounds-zh-cn-sinmei-16000-1.0.51.tar.gz
  - 32000Hz: https://files.freeswitch.org/releases/sounds/freeswitch-sounds-zh-cn-sinmei-32000-1.0.51.tar.gz
  - 48000Hz: https://files.freeswitch.org/releases/sounds/freeswitch-sounds-zh-cn-sinmei-48000-1.0.51.tar.gz

- 声音提示（中文粤语 zh-hk-sinmei，主要包含数字/时间类短语）
  - 8000Hz: https://files.freeswitch.org/releases/sounds/freeswitch-sounds-zh-hk-sinmei-8000-1.0.51.tar.gz
  - 16000Hz: https://files.freeswitch.org/releases/sounds/freeswitch-sounds-zh-hk-sinmei-16000-1.0.51.tar.gz
  - 32000Hz: https://files.freeswitch.org/releases/sounds/freeswitch-sounds-zh-hk-sinmei-32000-1.0.51.tar.gz
  - 48000Hz: https://files.freeswitch.org/releases/sounds/freeswitch-sounds-zh-hk-sinmei-48000-1.0.51.tar.gz
## 安装步骤（直接下载与解压）

以下步骤默认将资源放到 `/usr/local/freeswitch/sounds`，该路径通常对应 `$${sounds_dir}`。
1) 创建目录（如不存在）
```bash
sudo mkdir -p /usr/local/freeswitch/sounds
```

2) 进入目录并下载压缩包（按需选择采样率）
是否能用上面“英文 sounds”的链接直接下载“中文 sounds”？简短回答：可以从同一官方仓库下载中文包，但链接不同。files.freeswitch.org 提供了 zh-cn/zh-hk 的 sinmei 声音包（主要为数字与时间类短语），可直接下载并解压使用；注意这类包并不包含完整的 IVR 业务提示。

中文包官方下载链接（节选）：

- zh-cn（普通话，sinmei，v1.0.51）
  - 8000Hz: https://files.freeswitch.org/releases/sounds/freeswitch-sounds-zh-cn-sinmei-8000-1.0.51.tar.gz
  - 16000Hz: https://files.freeswitch.org/releases/sounds/freeswitch-sounds-zh-cn-sinmei-16000-1.0.51.tar.gz
  - 32000Hz: https://files.freeswitch.org/releases/sounds/freeswitch-sounds-zh-cn-sinmei-32000-1.0.51.tar.gz
  - 48000Hz: https://files.freeswitch.org/releases/sounds/freeswitch-sounds-zh-cn-sinmei-48000-1.0.51.tar.gz

- zh-hk（粤语，sinmei，v1.0.51，可选）
  - 8000Hz: https://files.freeswitch.org/releases/sounds/freeswitch-sounds-zh-hk-sinmei-8000-1.0.51.tar.gz
  - 16000Hz: https://files.freeswitch.org/releases/sounds/freeswitch-sounds-zh-hk-sinmei-16000-1.0.51.tar.gz
  - 32000Hz: https://files.freeswitch.org/releases/sounds/freeswitch-sounds-zh-hk-sinmei-32000-1.0.51.tar.gz
  - 48000Hz: https://files.freeswitch.org/releases/sounds/freeswitch-sounds-zh-hk-sinmei-48000-1.0.51.tar.gz

安装步骤（示例，48000Hz）：

```bash
cd /usr/local/freeswitch/sounds
curl -fL -O https://files.freeswitch.org/releases/sounds/freeswitch-sounds-zh-cn-sinmei-48000-1.0.51.tar.gz
sudo tar -xzf freeswitch-sounds-zh-cn-sinmei-48000-1.0.51.tar.gz
```

解压后目录结构（示例）：

- 数字：`/usr/local/freeswitch/sounds/zh/cn/sinmei/digits/48000/*.wav`
- 时间：`/usr/local/freeswitch/sounds/zh/cn/sinmei/time/48000/*.wav`

- 声音提示（示例 48000Hz）：

cd /usr/local/freeswitch/sounds
curl -fL -O https://files.freeswitch.org/releases/sounds/freeswitch-sounds-en-us-callie-48000-1.0.52.tar.gz
```

- 默认音乐（示例 48000Hz）：

```bash
cd /usr/local/freeswitch/sounds
curl -fL -O https://files.freeswitch.org/releases/music/freeswitch-sounds-music-48000-1.0.7.tar.gz
```

3) 解压

```bash
cd /usr/local/freeswitch/sounds
sudo tar -xzf freeswitch-sounds-music-48000-1.0.7.tar.gz
```

4) 目录结构（示例）

- 默认音乐：`/usr/local/freeswitch/sounds/music/48000/*`

5) 权限（如需要）

```bash
sudo chown -R freeswitch:freeswitch /usr/local/freeswitch/sounds
sudo chmod -R 755 /usr/local/freeswitch/sounds
```

## 验证安装

- 在 FreeSWITCH CLI 查看 sounds 目录值

```bash
fs_cli -x 'eval $${sounds_dir}'
```

- 检查目标文件是否存在

```bash
ls -lah /usr/local/freeswitch/sounds/en/us/callie/ivr/48000 | head
  - 拨号计划 `playback` 示例见下一节
补充说明：

- zh-cn/zh-hk sinmei 声音包主要覆盖“数字、时间”等基础短语，便于 `mod_say_zh` 等在报号与报时场景中使用；如需完整 IVR 话术，仍建议配合预录音或 TTS（例如待修复的 `mod_unimrcp` 接入百度等）。

  - 也可在拨测分机接通后 `playback` 某个 ivr 文件


- 使用文件播放（声音包安装完成后）

```xml
<action application="playback" data="en/us/callie/ivr/48000/ivr-echo_your_audio_back.wav"/>
```

- 使用内置音调（无需文件）

```xml
<action application="playback" data="tone_stream://%(1000,0,640)"/>
```

- hold music（本机 `autoload_configs/local_stream.conf.xml` 已定义）
  - 目录映射：`$${sounds_dir}/music/8000|16000|32000|48000`
  - 在通话中可使用：`local_stream://moh/48000`（或 `moh/8000` 等）
  - 变量 `hold_music` 可设为：`local_stream://moh`

## 常见问题

- 下载 404：
  - 访问目录索引（sounds/music）确认存在的文件名与版本再下载。
- 播放失败：
  - 路径拼写错误或权限问题；用 `fs_cli -x 'eval $${sounds_dir}'` 确认根路径，再拼接相对路径测试。
- 有信令无媒体：
  - 与声音包无关，多因 RTP 端口未放行或 NAT/ICE/TURN 配置导致；放行 UDP 16384–32768，并在浏览器/客户端确认麦克风权限与 ICE 服务器设置。

## APT 仓库方式（说明）

- 在部分发行版/仓库中存在声音包的二进制包（如 `freeswitch-sounds-en-us-callie`、`freeswitch-music-default` 等），但 Ubuntu 22.04 上的常见第三方源可能不稳定或不可用。
- 如遇 APT 包不可用，建议采用上述“直接下载与解压”的方式，简单可靠。

## 变更记录

- 2025-10-11：新增文档，收录 48k 声音与音乐下载链接与安装步骤，并补充拨号计划使用方法。

---

## 中文声音（zh-cn）获取与接入

是否能用上面“英文 sounds”的链接直接下载“中文 sounds”？简短回答：不能。files.freeswitch.org 官方仓库目前只提供 en-us-callie 与默认音乐（moh），并没有官方打包的 zh-cn 声音包，无法通过英文链接直接“替换语言”来获得中文包。

可行方案（选其一或组合）：

- 方案A：第三方/自制中文声音包（推荐最稳）
  - 获取来源：
    - 自行录制/外包录制中文提示，或从第三方供应商处获取（注意授权许可）。
  - 目录放置：
    - 建议与英文保持一致的层级，便于切换与维护：
      - 声音文件：`/usr/local/freeswitch/sounds/zh/cn/callie/ivr/48000/*.wav`
    - 也可以按 8000/16000/32000 采样率并存，按需挑选。
  - 拨号计划使用：
    - `playback` 直接引用相对 `$${sounds_dir}` 的路径，例如：
      - `<action application="playback" data="zh/cn/callie/ivr/48000/ivr-welcome.wav"/>`
  - Phrase 宏（短语模板）：
    - 复制英文 demo 的宏文件并翻译/改指向：
      - 从 `conf/lang/en/demo/new-demo-ivr.xml` 复制到 `conf/lang/zh/cn/new-demo-ivr.xml`
      - 将宏中的 `en/us/callie/...` 改为 `zh/cn/callie/...`
    - 重载配置：`fs_cli -x 'reloadxml'`

- 方案B：使用 TTS 合成中文提示（需 TTS 引擎）
  - 通过 `mod_unimrcp` 对接厂商（如百度/iFlytek 等）的 TTS 服务，让 IVR 动态合成中文语音。
  - 在 Phrase 宏里将 `tts-engine` 指向 TTS 引擎（如已配置好），或在拨号计划使用 `speak` 应用播放合成语音。
  - 适用场景：提示内容经常变化或无需预先录制。
  - 注意：当前环境的 `mod_unimrcp` 仍在修复加载，待模块加载正常后再切换此方案。

- 方案C：混合方案（预录提示 + 数字/日期用 say 引擎）
  - 普通固定提示使用预录中文音频文件；
  - 数字、金额、日期等可用 `mod_say_zh` 动态播报（无需预录）。
  - 这样既保证自然度，又减少录制成本。

接线与切换建议：

1) 目录与变量
   - `vars.xml` 中已设置：
     - `default_language=zh`
     - `default_dialect=cn`
     - `sound_prefix=$${sounds_dir}/zh/cn/callie`
   - 在中文包安装完成前，为避免播放失败，你可以在测试分机里临时覆盖为英文路径（已在 `conf/dialplan/default/5000-ivr.xml` 为 IVR 入口做了覆盖）。中文包就绪后，移除覆盖即可切换到中文。

2) 采样率选择
   - WebRTC 首选 48000Hz；纯 PSTN/G.711 也可使用 8000Hz。
   - 若准备多套采样率，目录结构建议与英文一致：`.../ivr/8000|16000|32000|48000/`。

3) 授权与合规
   - 使用第三方中文音频前，请确认商用授权，避免版权风险。

如你有现成的中文声音包下载链接（tar.gz/zip），我可以帮你：
- 下载并解压到规范目录；
- 生成/调整 `conf/lang/zh/cn/*.xml` 的 phrase 宏；
- 执行 reloadxml 并做一次拨测验证（例如拨 5000 进入 IVR）。
