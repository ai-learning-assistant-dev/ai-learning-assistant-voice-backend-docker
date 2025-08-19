import json
import os
from dataclasses import asdict
from typing import BinaryIO, TextIO

import ffmpeg
import numpy as np

from app.config import CONFIG


def format_timestamp(seconds: float, always_include_hours: bool = False, decimal_marker: str = "."):
    """
    格式化时间戳为标准时间格式
    """
    if seconds < 0:
        raise ValueError("时间戳不能为负数")
    
    hours = int(seconds // 3600)
    minutes = int((seconds % 3600) // 60)
    seconds = seconds % 60
    
    if always_include_hours or hours > 0:
        return f"{hours:02d}:{minutes:02d}:{seconds:06.3f}".replace(".", decimal_marker)
    else:
        return f"{minutes:02d}:{seconds:06.3f}".replace(".", decimal_marker)


class ResultWriter:
    extension: str

    def __init__(self, output_dir: str):
        self.output_dir = output_dir

    def __call__(self, result: dict, audio_path: str):
        audio_basename = os.path.basename(audio_path)
        output_path = os.path.join(self.output_dir, audio_basename + "." + self.extension)

        with open(output_path, "w", encoding="utf-8") as f:
            self.write_result(result, file=f)

    def write_result(self, result: dict, file: TextIO, options: dict = None):
        raise NotImplementedError


class WriteTXT(ResultWriter):
    extension: str = "txt"

    def write_result(self, result: dict, file: TextIO, options: dict = None):
        for segment in result["segments"]:
            print(segment["text"].strip(), file=file, flush=True)


class WriteVTT(ResultWriter):
    extension: str = "vtt"

    def write_result(self, result: dict, file: TextIO, options: dict = None):
        print("WEBVTT\n", file=file)
        for segment in result["segments"]:
            print(
                f"{format_timestamp(segment['start'])} --> {format_timestamp(segment['end'])}\n"
                f"{segment['text'].strip().replace('-->', '->')}\n",
                file=file,
                flush=True,
            )


class WriteSRT(ResultWriter):
    extension: str = "srt"

    def write_result(self, result: dict, file: TextIO, options: dict = None):
        for i, segment in enumerate(result["segments"], start=1):
            # write srt lines
            print(
                f"{i}\n"
                f"{format_timestamp(segment['start'], always_include_hours=True, decimal_marker=',')} --> "
                f"{format_timestamp(segment['end'], always_include_hours=True, decimal_marker=',')}\n"
                f"{segment['text'].strip().replace('-->', '->')}\n",
                file=file,
                flush=True,
            )


class WriteTSV(ResultWriter):
    """
    Write a transcript to a file in TSV (tab-separated values) format containing lines like:
    <start time in integer milliseconds>\t<end time in integer milliseconds>\t<transcript text>

    Using integer milliseconds as start and end times means there's no chance of interference from
    an environment setting a language encoding that causes the decimal in a floating point number
    to appear as a comma; also is faster and more efficient to parse & store, e.g., in C++.
    """

    extension: str = "tsv"

    def write_result(self, result: dict, file: TextIO, options: dict = None):
        print("start", "end", "text", sep="\t", file=file)
        for segment in result["segments"]:
            print(round(1000 * segment['start']), file=file, end="\t")
            print(round(1000 * segment['end']), file=file, end="\t")
            print(segment['text'].strip().replace("\t", " "), file=file, flush=True)


class WriteJSON(ResultWriter):
    extension: str = "json"

    def write_result(self, result: dict, file: TextIO, options: dict = None):
        # 确保segments是字典格式，而不是对象
        if "segments" in result and result["segments"]:
            # 如果segments中的元素是对象，转换为字典
            if hasattr(result["segments"][0], '__dict__'):
                result["segments"] = [asdict(segment) for segment in result["segments"]]
        json.dump(result, file, indent=2, ensure_ascii=False)


def load_audio(file: BinaryIO, encode=True, sr: int = CONFIG.SAMPLE_RATE):
    """
    打开音频文件对象并读取为单声道波形，必要时重新采样。
    
    Parameters
    ----------
    file: BinaryIO
        音频文件对象
    encode: Boolean
        如果为True，通过FFmpeg编码音频流为WAV格式
    sr: int
        重新采样的目标采样率
    Returns
    -------
    包含音频波形的NumPy数组，float32类型。
    """
    if encode:
        try:
            # This launches a subprocess to decode audio while down-mixing and resampling as necessary.
            # 使用配置的FFmpeg路径（本地优先）
            ffmpeg_cmd = CONFIG.FFMPEG_PATH
            out, _ = (
                ffmpeg.input("pipe:", threads=0)
                .output("-", format="s16le", acodec="pcm_s16le", ac=1, ar=sr)
                .run(cmd=ffmpeg_cmd, capture_stdout=True, capture_stderr=True, input=file.read())
            )
        except ffmpeg.Error as e:
            raise RuntimeError(f"Failed to load audio: {e.stderr.decode()}") from e
    else:
        out = file.read()

    return np.frombuffer(out, np.int16).flatten().astype(np.float32) / 32768.0
