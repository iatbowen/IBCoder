//
//  IBGroup3Controller12.m
//  MBCoder
//
//  Created by 叶修 on 2025/2/28.
//  Copyright © 2025 inke. All rights reserved.
//

#import "IBGroup3Controller12.h"

@interface IBGroup3Controller12 ()

@end

@implementation IBGroup3Controller12

- (void)viewDidLoad {
    [super viewDidLoad];
}

@end

/*

 ============================================================
 音视频处理链路与 iOS 实现 面试题总结
 ============================================================

 一、音视频完整处理链路
 ──────────────────────────────────────────

 采集（Capture）
   设备输入（摄像头/麦克风）→ 原始数据
   视频：YUV（CVPixelBuffer on iOS）
   音频：PCM（AudioBuffer / CMSampleBuffer on iOS）

 预处理（Pre-processing）
   视频：去噪、色彩空间转换、缩放、旋转、美颜/滤镜
   音频：降噪（ANS）、回声消除（AEC）、自动增益控制（AGC）

 编码（Encode）
   视频：H.264 / H.265 / VP9 / AV1
   音频：AAC / Opus / MP3

 封装（Mux）
   将编码后的音视频 Packet 按容器格式组织
   常见容器：MP4 / FLV / TS / MKV

 传输（Transport）
   推流：RTMP（直播）/ WebRTC（实时互动）/ HTTP-FLV
   分发：HLS / DASH / CDN

 接收 & 解封装（Demux）
   从网络读取数据流，按容器格式分离音视频 Packet（含 PTS/DTS）

 解码（Decode）
   视频：软解（FFmpeg libavcodec）/ 硬解（VideoToolbox / MediaCodec）
   音频：软解 → PCM 原始采样

 音视频同步（A/V Sync）
   以音频时钟为基准，控制视频帧渲染时机（详见 IBGroup3Controller11）

 渲染（Render）
   视频：Metal / OpenGL ES / AVSampleBufferDisplayLayer
   音频：AudioUnit / AVAudioEngine → 扬声器

 后处理（Post-processing）
   视频：实时滤镜、特效、画质增强（超分/HDR Tone Mapping）
   音频：混音、均衡器（EQ）、空间音效（Spatial Audio）


 ============================================================
 二、iOS 采集层（AVFoundation）
 ============================================================

 【核心类】
 AVCaptureSession          ：采集会话，协调输入与输出
 AVCaptureDevice           ：物理设备（前/后摄像头、麦克风）
 AVCaptureDeviceInput      ：将设备接入会话
 AVCaptureVideoDataOutput  ：视频帧输出，回调 CMSampleBuffer（含 CVPixelBuffer）
 AVCaptureAudioDataOutput  ：音频帧输出，回调 CMSampleBuffer（含 AudioBuffer）

 【视频采集基本流程】
 1. 创建 AVCaptureSession，设置 sessionPreset（分辨率/帧率预设）
 2. 获取 AVCaptureDevice，创建 AVCaptureDeviceInput 并加入 session
 3. 创建 AVCaptureVideoDataOutput，设置 videoSettings（kCVPixelFormatType_420YpCbCr8BiPlanarFullRange）
 4. 实现 captureOutput:didOutputSampleBuffer:fromConnection: 回调，获取帧数据
 5. session.startRunning() 开始采集

 【CVPixelBuffer】
 iOS 视频帧的底层存储格式，包含 YUV 原始数据（NV12 = YUV 4:2:0 双平面格式）。
 - 平面 0（Y 分量）：亮度数据
 - 平面 1（CbCr 分量）：色度数据（交织存储）
 可直接传入 VideoToolbox 编码器或 Metal 纹理上传，零拷贝高效。

 【CMSampleBuffer】
 封装了一帧音视频数据及其时间信息（CMTime PTS/DTS），是 AVFoundation 内部流通的核心类型。

 【摄像头控制】
 对焦（Focus）     ：setFocusMode: / setFocusPointOfInterest:
 曝光（Exposure）  ：setExposureMode: / setExposureTargetBias:
 白平衡（WB）      ：setWhiteBalanceMode:
 帧率控制         ：setActiveVideoMinFrameDuration: / setActiveVideoMaxFrameDuration:
 ⚠️ 修改设备属性前必须调用 lockForConfiguration，完成后 unlockForConfiguration


 ============================================================
 三、iOS 硬件编解码（VideoToolbox）
 ============================================================

 【VideoToolbox 简介】
 Apple 提供的硬件编解码框架，直接调用 SoC 的专用编解码单元，
 功耗远低于 FFmpeg 软解，延迟低，支持 H.264 / H.265 / ProRes 等。

 【硬件编码（VTCompressionSession）】
 1. VTCompressionSessionCreate：创建编码 Session，配置编码参数
    关键参数：
    - kVTCompressionPropertyKey_ProfileLevel   ：Profile（H264_Main_4_1 等）
    - kVTCompressionPropertyKey_AverageBitRate ：平均码率
    - kVTCompressionPropertyKey_MaxKeyFrameInterval：GOP 大小（关键帧间隔）
    - kVTCompressionPropertyKey_RealTime       ：是否实时编码
 2. VTCompressionSessionEncodeFrame：送入 CVPixelBuffer，异步回调输出 CMSampleBuffer
 3. 回调中提取 CMBlockBuffer，判断是否为关键帧（kCMSampleAttachmentKey_NotSync == NO）
 4. 封装 NALU：提取 SPS/PPS（首个关键帧前），组装 Annex B 格式（添加 0x00000001 起始码）

 【硬件解码（VTDecompressionSession）】
 1. 从 SPS/PPS 创建 CMVideoFormatDescription
 2. VTDecompressionSessionCreate：创建解码 Session
 3. VTDecompressionSessionDecodeFrame：送入编码数据，回调输出 CVPixelBuffer
 4. CVPixelBuffer 可直接上传 Metal 纹理渲染，或传入 AVSampleBufferDisplayLayer

 【AVAssetWriter / AVAssetReader】
 AVAssetWriter  ：高层录制/转码 API，封装了 VideoToolbox，支持写入 MP4/MOV
 AVAssetReader  ：高层读取 API，从文件中读取音视频帧（含解码）


 ============================================================
 四、FFmpeg 核心模块
 ============================================================

 libavformat    ：解协议 + 解封装/封装（Demux/Mux）
   - 支持 200+ 容器格式（MP4/FLV/TS/MKV/HLS 等）
   - 核心 API：avformat_open_input → avformat_find_stream_info → av_read_frame
   - 推流：avformat_write_header → av_write_frame → av_write_trailer

 libavcodec     ：软件编解码
   - 支持 100+ 编解码器（H.264/H.265/AAC/Opus 等）
   - 核心 API：avcodec_find_decoder → avcodec_open2 → avcodec_send_packet → avcodec_receive_frame

 libavfilter    ：音视频滤镜处理
   - 支持滤镜链（FilterGraph）：scale / overlay / drawtext / fps / vflip 等
   - 核心 API：avfilter_graph_create_filter → avfilter_graph_config → av_buffersrc_add_frame

 libswscale     ：图像格式/尺寸转换
   - YUV ↔ RGB 转换、图像缩放（支持多种插值算法：BILINEAR/BICUBIC）
   - 核心 API：sws_getContext → sws_scale

 libswresample  ：音频重采样
   - 采样率、采样格式、声道布局转换
   - 核心 API：swr_alloc_set_opts → swr_init → swr_convert

 libavutil      ：工具库（数学运算、内存管理、日志、时间工具、AVFrame/AVPacket 管理）

 【FFmpeg 在 iOS 上的典型使用方案】
 - 解封装用 libavformat（支持格式广），解码用 VideoToolbox 硬解（低功耗）
 - AVFrame/AVPacket 作为数据容器，CVPixelBuffer 与 AVFrame 通过 av_buffer_create 桥接
 - 编码用 VideoToolbox，封装/推流用 libavformat（如 RTMP 推流：ffmpeg + librtmp）


 ============================================================
 五、图片、纹理、材质、着色器
 ============================================================

 【图片（Image）】
 CPU 侧的像素数据，存储在内存/文件中（JPEG/PNG/WebP 等）。
 iOS 中：UIImage / CGImage / CGBitmapContext 管理图片数据。

 【纹理（Texture）】
 上传到 GPU 显存的像素数据，用于 GPU 采样（在着色器中通过纹理坐标读取颜色）。
 iOS Metal 中：MTLTexture，通过 MTLTextureDescriptor 创建，用 replaceRegion:mipmapLevel:withBytes: 上传数据。
 纹理类型：
 - 漫反射纹理（Diffuse）：基本颜色
 - 法线贴图（Normal Map）：模拟细节几何凹凸
 - 高光贴图（Specular Map）：控制反光强度分布
 - 深度纹理（Depth Texture）：阴影映射等用途

 【材质（Material）】
 定义模型表面外观的属性集合：纹理 + 光照参数（光泽度、透明度、反射率、折射率等）。
 材质不是 GPU 的底层概念，而是引擎/框架层的抽象（如 SceneKit 的 SCNMaterial）。
 材质将多张纹理和参数组合，传给着色器统一计算。

 【着色器（Shader）】
 运行在 GPU 上的程序，决定每个像素/顶点的最终颜色：
 - 顶点着色器（Vertex Shader） ：处理每个顶点的坐标变换（模型→世界→裁剪空间）
 - 片段着色器（Fragment Shader）：处理每个片段（像素）的颜色计算（纹理采样、光照、混合）
 Metal 着色器用 Metal Shading Language（MSL，基于 C++14）编写，编译为 .metallib 二进制。

 【关系链】
 图片（CPU）→ 上传 → 纹理（GPU 显存）
 纹理 + 光照参数 → 组合为 → 材质
 材质数据 + 网格数据 → 传入 → 着色器 → 输出最终像素颜色

 【视频帧在 Metal 中的渲染流程】
 CVPixelBuffer（YUV NV12）
   → CVMetalTextureCache 创建 MTLTexture（Y 平面 + CbCr 平面，零拷贝）
   → 片段着色器中采样两张纹理，执行 YUV → RGB 矩阵转换
   → 输出到 MTLRenderPassDescriptor 的 colorAttachment → 上屏


 ============================================================
 六、音视频同步
 ============================================================

 【时间基（Time Base）】
 tbr（Time Base of Rate）  ：帧率相关时间基，如 30fps → 1/30
 tbn（Time Base of Stream）：流的时间戳单位，如 1/90000（视频流常用），1/48000（音频流）
 tbc（Time Base of Codec） ：编解码器内部时间基

 所有 PTS/DTS 均为整数，乘以时间基才得到实际时间（秒）。
 实际时间（s）= PTS × time_base = PTS × (num/den)

 【PTS 计算】
 视频下一帧 PTS = 当前帧 PTS + (time_base_den / fps)
   示例：time_base = 1/90000，fps = 30
   帧间隔 = 90000 / 30 = 3000（时间基单位）

 音频下一帧 PTS = 当前帧 PTS + 每帧采样数
   示例：time_base = 1/48000，采样率 = 48000，每帧采样数 = 1024
   帧间隔 = 1024（时间基单位，即 1024/48000 ≈ 21.3ms）

 【同步策略对比】
 以音频时钟为基准（最常用）
   视频超前 → 等待；视频落后 → 丢帧
   优点：音频连续无卡顿，体验最好
   缺点：视频可能出现跳帧
   适用：直播、实时通信、点播

 以视频时钟为基准
   调整音频播放速率（变速不变调）
   优点：视频画面流畅无跳帧
   缺点：音频变速影响质感
   适用：离线编辑、游戏录制

 以外部时钟为基准（系统时钟）
   音视频均向外部时钟对齐
   优点：多流/多设备同步稳定
   缺点：实现复杂，依赖时钟精度
   适用：专业制作、多轨道系统

*/
