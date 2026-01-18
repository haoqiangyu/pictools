use image::{DynamicImage, ImageFormat as ImgFormat, ImageReader};
use std::io::Cursor;
use webp::{Encoder, WebPMemory};

/// 图片输出格式
pub enum ImageFormat {
    Png,
    Jpg { quality: u8 },
    WebP { quality: u8, lossless: bool },
}

/// 将图片编码为指定格式
/// 
/// # Arguments
/// * `image_data` - 原始图片数据（支持 PNG/JPG/WebP/GIF/BMP 等）
/// * `format` - 目标输出格式
/// 
/// # Returns
/// 编码后的图片字节数据
pub fn encode_image(image_data: Vec<u8>, format: ImageFormat) -> Result<Vec<u8>, String> {
    // 解码输入图片
    let img = ImageReader::new(Cursor::new(&image_data))
        .with_guessed_format()
        .map_err(|e| format!("Failed to guess image format: {}", e))?
        .decode()
        .map_err(|e| format!("Failed to decode image: {}", e))?;

    match format {
        ImageFormat::Png => encode_png(&img),
        ImageFormat::Jpg { quality } => encode_jpg(&img, quality),
        ImageFormat::WebP { quality, lossless } => encode_webp(&img, quality, lossless),
    }
}

fn encode_png(img: &DynamicImage) -> Result<Vec<u8>, String> {
    let mut buffer = Cursor::new(Vec::new());
    img.write_to(&mut buffer, ImgFormat::Png)
        .map_err(|e| format!("Failed to encode PNG: {}", e))?;
    Ok(buffer.into_inner())
}

fn encode_jpg(img: &DynamicImage, quality: u8) -> Result<Vec<u8>, String> {
    let rgb_img = img.to_rgb8();
    let mut buffer = Cursor::new(Vec::new());
    
    let mut encoder = image::codecs::jpeg::JpegEncoder::new_with_quality(&mut buffer, quality);
    encoder
        .encode(
            rgb_img.as_raw(),
            rgb_img.width(),
            rgb_img.height(),
            image::ExtendedColorType::Rgb8,
        )
        .map_err(|e| format!("Failed to encode JPG: {}", e))?;
    
    Ok(buffer.into_inner())
}

fn encode_webp(img: &DynamicImage, quality: u8, lossless: bool) -> Result<Vec<u8>, String> {
    let rgba_img = img.to_rgba8();
    let (width, height) = rgba_img.dimensions();
    
    let encoder = Encoder::from_rgba(rgba_img.as_raw(), width, height);
    
    let webp_data: WebPMemory = if lossless {
        encoder.encode_lossless()
    } else {
        encoder.encode(quality as f32)
    };
    
    Ok(webp_data.to_vec())
}

/// 调整图片尺寸
pub fn resize_image(image_data: Vec<u8>, width: u32, height: u32) -> Result<Vec<u8>, String> {
    let img = ImageReader::new(Cursor::new(&image_data))
        .with_guessed_format()
        .map_err(|e| format!("Failed to guess image format: {}", e))?
        .decode()
        .map_err(|e| format!("Failed to decode image: {}", e))?;

    let resized = img.resize_exact(width, height, image::imageops::FilterType::Lanczos3);
    
    // 返回 PNG 格式的中间结果
    encode_png(&resized)
}

/// 裁剪图片
pub fn crop_image(image_data: Vec<u8>, x: u32, y: u32, width: u32, height: u32) -> Result<Vec<u8>, String> {
    let mut img = ImageReader::new(Cursor::new(&image_data))
        .with_guessed_format()
        .map_err(|e| format!("Failed to guess image format: {}", e))?
        .decode()
        .map_err(|e| format!("Failed to decode image: {}", e))?;

    let cropped = img.crop(x, y, width, height);
    
    // 返回 PNG 格式的中间结果
    encode_png(&cropped)
}
