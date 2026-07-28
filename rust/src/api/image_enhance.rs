use image::{ImageReader, RgbaImage};
use std::io::Cursor;

const PG_LUMINANCE: [f64; 3] = [0.2126, 0.7152, 0.0722];

fn dot(rgb1: [f64; 3], rgb2: [f64; 3]) -> f64 {
    rgb1.iter().zip(rgb2.iter()).map(|(&a, &b)| a * b).sum()
}

fn pg_srgb_to_linear(color_rgb: [f64; 3]) -> [f64; 3] {
    let mut linear_rgb: [f64; 3] = [0.0; 3];
    for (i, x) in color_rgb.iter().enumerate() {
        let a = x / 12.92;
        let b = ((x + 0.055) / 1.055).powf(2.4);
        let c = if *x >= 0.04045 { 1.0 } else { 0.0 };
        linear_rgb[i] = (1.0 - c) * a + c * b;
    }
    linear_rgb
}

fn pg_linear_to_srgb(color_rgb: [f64; 3]) -> [f64; 3] {
    let mut srgb_rgb: [f64; 3] = [0.0; 3];
    for (i, x) in color_rgb.iter().enumerate() {
        let a = 12.92 * x;
        let b = 1.055 * x.powf(1.0 / 2.4) - 0.055;
        let c = if *x >= 0.0031308 { 1.0 } else { 0.0 };
        srgb_rgb[i] = (1.0 - c) * a + c * b;
    }
    srgb_rgb
}

fn pg_srgb_to_linear_alpha(color: [f64; 4]) -> [f64; 4] {
    let linear_rgb = pg_srgb_to_linear([color[0], color[1], color[2]]);
    [linear_rgb[0], linear_rgb[1], linear_rgb[2], color[3]]
}

fn pg_linear_to_srgb_alpha(color: [f64; 4]) -> [f64; 4] {
    let srgb_rgb = pg_linear_to_srgb([color[0], color[1], color[2]]);
    [srgb_rgb[0], srgb_rgb[1], srgb_rgb[2], color[3]]
}

fn pg_exposure_kernel(color: [f64; 4], exposure: f64) -> [f64; 4] {
    let mut result_rgba: [f64; 4] = [0.0; 4];
    for (i, x) in color.iter().enumerate() {
        result_rgba[i] = if i >= color.len() - 1 {
            *x
        } else {
            (x * (2_f64.powf(exposure))).clamp(0.0, 1.0)
        }
    }
    result_rgba
}

fn pg_highlights_shadows_multiplier(l: f64, highlights: f64, shadows: f64) -> f64 {
    const SHADOWS_L: f64 = 0.0;
    const SHADOWS_RADIUS: f64 = 0.15;
    const SHADOWS_AMPL: f64 = 1.0;
    const HIGHLIGHTS_L: f64 = 1.0;
    const HIGHLIGHTS_RADIUS: f64 = 0.4;
    const HIGHLIGHTS_AMPL: f64 = 0.55;

    let shadows_multiplier =
        SHADOWS_AMPL * (-0.5 * ((l - SHADOWS_L) / SHADOWS_RADIUS).powf(2.0)).exp();
    let highlights_multiplier =
        HIGHLIGHTS_AMPL * (-0.5 * ((l - HIGHLIGHTS_L) / HIGHLIGHTS_RADIUS).powf(2.0)).exp();
    1.0 + highlights * highlights_multiplier + shadows * shadows_multiplier
}

fn pg_highlights_shadows_kernel(color: [f64; 4], highlights: f64, shadows: f64) -> [f64; 4] {
    let luminance = dot([color[0], color[1], color[2]], PG_LUMINANCE);
    let factor = pg_highlights_shadows_multiplier(luminance, highlights, shadows);
    let mut result_rgba: [f64; 4] = [0.0; 4];
    for (i, x) in color.iter().enumerate() {
        result_rgba[i] = if i >= color.len() - 1 {
            *x
        } else {
            (x * factor).clamp(0.0, 1.0)
        }
    }
    result_rgba
}

fn pg_saturation_kernel(color: [f64; 4], saturation: f64) -> [f64; 4] {
    let luminance = dot([color[0], color[1], color[2]], PG_LUMINANCE);
    let mut result_rgba: [f64; 4] = [0.0; 4];
    for (i, x) in color.iter().enumerate() {
        result_rgba[i] = if i >= color.len() - 1 {
            *x
        } else {
            ((1.0 - saturation) * luminance + saturation * x).clamp(0.0, 1.0)
        }
    }
    result_rgba
}

fn light_on_kernel(color: [f64; 4]) -> [f64; 4] {
    let color = pg_srgb_to_linear_alpha(color);
    let color = pg_exposure_kernel(color, 0.375);
    let color = pg_highlights_shadows_kernel(color, 0.1, 0.1);
    let color = pg_saturation_kernel(color, 1.1);
    pg_linear_to_srgb_alpha(color)
}

/// 对图片进行亮度增强处理
///
/// # Arguments
/// * `image_data` - 原始图片数据（支持 PNG/JPG/WebP/GIF/BMP 等）
///
/// # Returns
/// 处理后的 PNG 格式图片字节数据
pub fn enhance_image(image_data: Vec<u8>) -> Result<Vec<u8>, String> {
    // 解码输入图片
    let image = ImageReader::new(Cursor::new(&image_data))
        .with_guessed_format()
        .map_err(|e| format!("Failed to guess image format: {}", e))?
        .decode()
        .map_err(|e| format!("Failed to decode image: {}", e))?
        .to_rgba8();

    let mut result_image = RgbaImage::new(image.width(), image.height());

    for y in 0..image.height() {
        for x in 0..image.width() {
            let pixel = image.get_pixel(x, y);
            let color = [
                pixel[0] as f64 / 255.0,
                pixel[1] as f64 / 255.0,
                pixel[2] as f64 / 255.0,
                pixel[3] as f64 / 255.0,
            ];
            let new_color = light_on_kernel(color);
            result_image.put_pixel(
                x,
                y,
                image::Rgba([
                    (new_color[0] * 255.0) as u8,
                    (new_color[1] * 255.0) as u8,
                    (new_color[2] * 255.0) as u8,
                    (new_color[3] * 255.0) as u8,
                ]),
            );
        }
    }

    // 编码为 PNG
    let mut buffer = Cursor::new(Vec::new());
    result_image
        .write_to(&mut buffer, image::ImageFormat::Png)
        .map_err(|e| format!("Failed to encode PNG: {}", e))?;

    Ok(buffer.into_inner())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn enhance_preserves_dimensions_and_alpha_while_brightening() {
        let source = RgbaImage::from_pixel(2, 3, image::Rgba([64, 80, 96, 123]));
        let mut input = Cursor::new(Vec::new());
        source
            .write_to(&mut input, image::ImageFormat::Png)
            .expect("encode test input");

        let output = enhance_image(input.into_inner()).expect("enhance image");
        let decoded = image::load_from_memory(&output)
            .expect("decode enhanced output")
            .to_rgba8();
        let pixel = decoded.get_pixel(0, 0);

        assert_eq!(decoded.dimensions(), (2, 3));
        assert_eq!(pixel[3], 123);
        assert!(pixel[0] > 64);
        assert!(pixel[1] > 80);
        assert!(pixel[2] > 96);
    }

    #[test]
    fn enhance_rejects_invalid_image_data() {
        assert!(enhance_image(vec![1, 2, 3]).is_err());
    }
}
