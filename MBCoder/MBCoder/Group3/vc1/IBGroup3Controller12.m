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

/**
 一、音视频处理流程
 1、采集：
 使用设备（如摄像头、麦克风）捕获原始音视频数据
 常见格式：YUV（视频）、PCM（音频）
 
 2、预处理：
 视频：去噪、色彩空间转换、缩放、旋转等
 音频：降噪、回声消除、增益控制等
 
 3、编码：
 使用编码器压缩数据
 常见视频编码：H.264, H.265, VP9
 常见音频编码：AAC, MP3, Opus
 
 4、封装：
 将编码后的音视频数据打包成容器格式
 常见格式：MP4, MKV, FLV, TS
 
 5、传输：
 通过网络传输音视频数据
 常用协议：RTMP, HLS, WebRTC
 
 6、解码：
 接收端解码压缩的音视频数据
 
 7、渲染：
 视频：显示在屏幕上
 音频：通过扬声器播放
 
 8、后处理：
 视频：滤镜、特效、画质增强
 音频：混音、均衡、空间音效
 
 二、FFmpeg 核心模块
 1、libavcodec：编解码器库
 - 包含各种音视频编解码器的实现
 - 支持硬件加速
 - 提供统一的编解码接口
 
 2、libavformat：封装格式库
 - 处理多媒体容器格式
 - 支持解复用和复用
 - 提供协议处理功能
 
 3、libavutil：工具库
 - 提供通用工具函数
 - 包括数学运算、内存管理、日志等
 - 包含常用数据结构
 
 4、libavfilter：滤镜库
 - 实现音视频滤镜处理
 - 支持滤镜链
 - 提供丰富的内置滤镜
 
 5、libswscale：图像缩放库
 - 处理图像格式转换和缩放
 - 支持色彩空间转换
 - 提供高效的图像处理算法
 
 6、libswresample：音频重采样库
 - 处理音频格式转换
 - 支持采样率转换
 - 提供音频混合功能
 
 三、图片，纹理，材质，着色器
 图片（Image）：
 是由像素组成的二维图像数据，可以是照片、绘画或任何其他形式的视觉表示。
 图片通常存储在文件中，如 JPEG、PNG、BMP 等格式
 
 纹理（Texture）：
 是应用于三维模型表面的图像，用于增加细节和真实感。纹理通常是图片文件，通过纹理映射技术将其“包裹”在三维模型上。
 纹理可以包含颜色信息（如漫反射纹理）、法线信息（如法线贴图）或其他属性（如高光贴图、环境光遮蔽贴图等）。

 材质（Material）：
 材质是定义三维模型表面外观的属性集合。材质不仅包括纹理，还包括其他属性，如光泽度、透明度、反射率、折射率等。
 材质决定了模型在不同光照条件下的表现。材质通常由一个或多个纹理和一组参数组成，这些参数控制模型表面的物理特性和光照反应。
 
 着色器（Shader）：
 着色器是运行在 GPU 上的小程序，用于计算每个像素的颜色和其他属性。着色器可以使用材质和纹理信息来生成最终的图像效果。常见的着色器类型包括顶点着色器和片段着色器。

 关系
 图片到纹理：图片文件被加载到内存中，并转换为纹理，以便在三维模型上使用。
 纹理到材质：纹理是材质的一部分，材质定义了模型表面的外观属性，包括颜色、光泽度、透明度等。
 材质到着色器：材质属性和纹理被传递给着色器，着色器使用这些信息来计算每个像素的最终颜色和效果。

 四、音视频同步
 1、时间戳类型
 - DTS（Decoding Time Stamp）：解码时间戳，标记数据何时被解码。
 - PTS（Presentation Time Stamp）：显示时间戳，标记数据何时应被渲染。
 H.264 中由于 B 帧的存在，DTS 和 PTS 可能不同（B 帧依赖后续帧，需调整解码顺序）
 
 2、时间基
 - tbr（Time Base of Rate）：通常指帧率的时间基。可能和视频流的帧率相关，比如帧率是30fps，时间基可能是1/30
 - tbn（Time Base of Stream）：流的时间基，用于时间戳的计算。每个流（如视频流、音频流）都有自己的tbn，用于将时间戳转换为实际时间
 - tbc（Time Base of Codec）：编解码器层的时间基，可能用于解码过程中的时间计算。不同的编解码器可能有不同的时间基
 
 3、计算下一帧的PTS
 
 - 视频流 PTS 计算：
 下一帧PTS = 当前帧PTS + 帧间隔（按时间基单位）
 帧间隔 = 时间基分母 / 帧率
 
 例如：
 时间基 = 1/90000（即每单位为 1/90000 秒） 帧率 = 30fps
 帧间隔 = 90000 / 30 = 3000（时间基单位）

 - 音频流 PTS 计算：
 下一帧PTS = 当前帧PTS + 每帧样本数 / 采样率 × 时间基分母

 例如：
 时间基 = 1/48000
 采样率 = 48000Hz
 每帧样本数 = 1024

 帧间隔时间（秒）= 1024 / 48000 ≈ 0.021333 秒
 时间基单位间隔 = 0.021333 × 48000 = 1024（每帧PTS增量）

 4、音视频同步方式
 
 同步方式         优点                                    缺点                                        适用场景
 音频主导         听觉优先，自然流畅          视频跳帧可能明显                  直播、实时通信
 视频主导         画面流畅，无跳帧              音频变速影响质量                 离线编辑、游戏录制
 外部时钟         多流同步，稳定性高          实现复杂，依赖时钟精度      专业制作、多轨道系统
 

 
 */
