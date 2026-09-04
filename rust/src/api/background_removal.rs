use image::{DynamicImage, ImageReader, RgbaImage};
#[cfg(not(any(target_os = "android", target_os = "ios")))]
use ort::session::{builder::GraphOptimizationLevel, Session};
#[cfg(not(any(target_os = "android", target_os = "ios")))]
use ort::value::Value;
use std::io::Cursor;
#[cfg(not(any(target_os = "android", target_os = "ios")))]
use std::sync::Once;

// 确保 tracing subscriber 只初始化一次
#[cfg(not(any(target_os = "android", target_os = "ios")))]
static INIT_TRACING: Once = Once::new();

#[cfg(not(any(target_os = "android", target_os = "ios")))]
fn init_tracing() {
    INIT_TRACING.call_once(|| {
        // 初始化 tracing subscriber，捕获 ort 的日志
        tracing_subscriber::fmt()
            .with_env_filter("ort=debug")
            .with_target(true)
            .init();
    });
}

/// 使用RMBG-2.0 ONNX模型进行背景移除
///
/// # Arguments
/// * `image_data` - 原始图片数据
/// * `model_path` - ONNX模型文件路径
///
/// # Returns
/// 返回带有透明背景的RGBA图片数据（PNG格式）
#[cfg(not(any(target_os = "android", target_os = "ios")))]
pub fn remove_background(image_data: Vec<u8>, model_path: String) -> Result<Vec<u8>, String> {
    // 初始化 tracing 以输出 ort 的执行提供程序日志
    init_tracing();

    // 输出 ONNX Runtime 版本信息
    println!("ONNX Runtime info: {}", ort::info());

    // 1. 解码输入图片
    let img = ImageReader::new(Cursor::new(&image_data))
        .with_guessed_format()
        .map_err(|e| format!("Failed to guess image format: {}", e))?
        .decode()
        .map_err(|e| format!("Failed to decode image: {}", e))?;

    let original_width = img.width();
    let original_height = img.height();

    // 2. 预处理：缩放到1024x1024
    let input_img = img.resize_exact(1024, 1024, image::imageops::FilterType::Lanczos3);
    let rgb_img = input_img.to_rgb8();

    // 3. 归一化并转换为NCHW格式
    // ImageNet归一化参数: mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]
    let mean = [0.485_f32, 0.456, 0.406];
    let std = [0.229_f32, 0.224, 0.225];

    // 使用Vec而不是ndarray,因为ort的OwnedTensorArrayData trait支持 (shape, Vec<T>)
    let mut input_data: Vec<f32> = vec![0.0; 1 * 3 * 1024 * 1024];

    for c in 0..3_usize {
        for y in 0..1024_usize {
            for x in 0..1024_usize {
                let pixel = rgb_img.get_pixel(x as u32, y as u32);
                let normalized = (pixel[c] as f32 / 255.0 - mean[c]) / std[c];
                // NCHW layout: [batch, channel, height, width]
                let idx = c * 1024 * 1024 + y * 1024 + x;
                input_data[idx] = normalized;
            }
        }
    }

    // 4. 加载ONNX模型并运行推理
    // 注意：CoreML 对 RMBG-2.0 模型只支持 12/7315 个节点，且会导致某些设备输出空白
    // 因此只使用 CPU 以确保跨设备一致性
    println!("Configuring execution providers: [CPU]");
    let mut session = Session::builder()
        .map_err(|e| format!("Failed to create session builder: {}", e))?
        .with_optimization_level(GraphOptimizationLevel::Disable)
        .map_err(|e| format!("Failed to set optimization level: {}", e))?
        .with_intra_threads(1)
        .map_err(|e| format!("Failed to set intra threads: {}", e))?
        .with_inter_threads(1)
        .map_err(|e| format!("Failed to set inter threads: {}", e))?
        .with_memory_pattern(false)
        .map_err(|e| format!("Failed to disable memory pattern: {}", e))?
        // .with_enable_cpu_mem_arena(false) // Not supported in this version, but default seems to be 0
        .with_parallel_execution(false) // Sequential mode
        .map_err(|e| format!("Failed to set sequential execution: {}", e))?
        .commit_from_file(&model_path)
        .map_err(|e| format!("Failed to load model from {}: {}", model_path, e))?;

    // 使用 (shape, Vec<T>) 创建tensor，这是ort明确支持的
    let shape = (vec![1_i64, 3, 1024, 1024], input_data);
    let input_value =
        Value::from_array(shape).map_err(|e| format!("Failed to create input value: {}", e))?;

    let outputs = session
        .run(ort::inputs![input_value])
        .map_err(|e| format!("Failed to run inference: {}", e))?;

    // 5. 处理输出：获取alpha matte
    // RMBG-2.0输出是一个sigmoid后的alpha matte，形状为[1, 1, 1024, 1024]
    let output_tensor = outputs[0]
        .try_extract_tensor::<f32>()
        .map_err(|e| format!("Failed to extract output tensor: {}", e))?;

    // output_tensor is (&Shape, &[f32])
    let (_shape, output_data) = output_tensor;

    // 6. 将alpha matte缩放回原始尺寸
    let mut alpha_1024 = image::GrayImage::new(1024, 1024);
    for y in 0..1024_usize {
        for x in 0..1024_usize {
            // 数据布局是 [batch, channel, height, width]
            // batch=0, channel=0, 所以直接用 y*width+x
            let idx = y * 1024 + x;
            let alpha_value = output_data[idx];
            // sigmoid已经应用，范围是[0, 1]
            alpha_1024.put_pixel(
                x as u32,
                y as u32,
                image::Luma([(alpha_value.clamp(0.0, 1.0) * 255.0) as u8]),
            );
        }
    }

    let alpha_img = DynamicImage::ImageLuma8(alpha_1024)
        .resize_exact(
            original_width,
            original_height,
            image::imageops::FilterType::Lanczos3,
        )
        .to_luma8();

    // 7. 应用alpha通道到原始图片
    let mut result_img = RgbaImage::new(original_width, original_height);
    let original_rgba = img.to_rgba8();

    for y in 0..original_height {
        for x in 0..original_width {
            let mut pixel = *original_rgba.get_pixel(x, y);
            let alpha = alpha_img.get_pixel(x, y)[0];
            pixel[3] = alpha; // 设置alpha通道
            result_img.put_pixel(x, y, pixel);
        }
    }

    // 8. 编码为PNG（保留透明度）
    let mut buffer = Cursor::new(Vec::new());
    result_img
        .write_to(&mut buffer, image::ImageFormat::Png)
        .map_err(|e| format!("Failed to encode PNG: {}", e))?;

    Ok(buffer.into_inner())
}

#[cfg(any(target_os = "android", target_os = "ios"))]
pub fn remove_background(_image_data: Vec<u8>, _model_path: String) -> Result<Vec<u8>, String> {
    Err("Background removal is not available on mobile".to_string())
}

/// 为透明图片添加纯色背景
///
/// # Arguments
/// * `rgba_data` - RGBA图片数据（PNG格式）
/// * `bg_red` - 背景红色分量 (0-255)
/// * `bg_green` - 背景绿色分量 (0-255)
/// * `bg_blue` - 背景蓝色分量 (0-255)
///
/// # Returns
/// 返回添加了纯色背景的RGB图片数据（PNG格式）
pub fn add_solid_background(
    rgba_data: Vec<u8>,
    bg_red: u8,
    bg_green: u8,
    bg_blue: u8,
) -> Result<Vec<u8>, String> {
    // 解码RGBA图片
    let img = ImageReader::new(Cursor::new(&rgba_data))
        .with_guessed_format()
        .map_err(|e| format!("Failed to guess image format: {}", e))?
        .decode()
        .map_err(|e| format!("Failed to decode image: {}", e))?
        .to_rgba8();

    let (width, height) = img.dimensions();
    let mut result_img = RgbaImage::new(width, height);

    // Alpha合成：result = foreground * alpha + background * (1 - alpha)
    for y in 0..height {
        for x in 0..width {
            let pixel = img.get_pixel(x, y);
            let alpha = pixel[3] as f32 / 255.0;

            let r = (pixel[0] as f32 * alpha + bg_red as f32 * (1.0 - alpha)) as u8;
            let g = (pixel[1] as f32 * alpha + bg_green as f32 * (1.0 - alpha)) as u8;
            let b = (pixel[2] as f32 * alpha + bg_blue as f32 * (1.0 - alpha)) as u8;

            result_img.put_pixel(x, y, image::Rgba([r, g, b, 255]));
        }
    }

    // 编码为PNG
    let mut buffer = Cursor::new(Vec::new());
    result_img
        .write_to(&mut buffer, image::ImageFormat::Png)
        .map_err(|e| format!("Failed to encode PNG: {}", e))?;

    Ok(buffer.into_inner())
}
