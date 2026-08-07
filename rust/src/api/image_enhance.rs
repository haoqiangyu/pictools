use image::{DynamicImage, ImageDecoder, ImageReader, RgbaImage};
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
    let reader = ImageReader::new(Cursor::new(&image_data))
        .with_guessed_format()
        .map_err(|e| format!("Failed to guess image format: {}", e))?;
    let mut decoder = reader
        .into_decoder()
        .map_err(|e| format!("Failed to create image decoder: {}", e))?;
    let orientation = decoder
        .orientation()
        .map_err(|e| format!("Failed to read image orientation: {}", e))?;
    let mut image = DynamicImage::from_decoder(decoder)
        .map_err(|e| format!("Failed to decode image: {}", e))?;

    // PNG cannot retain EXIF orientation, so bake it into the pixels first.
    image.apply_orientation(orientation);
    let image = image.to_rgba8();

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

    fn jpeg_with_orientation(image: &RgbaImage, orientation: u8) -> Vec<u8> {
        let mut jpeg = Cursor::new(Vec::new());
        DynamicImage::ImageRgba8(image.clone())
            .write_to(&mut jpeg, image::ImageFormat::Jpeg)
            .expect("encode JPEG fixture");
        let jpeg = jpeg.into_inner();

        let mut tiff = vec![
            b'I',
            b'I',
            42,
            0, // Little-endian TIFF header.
            8,
            0,
            0,
            0, // First IFD offset.
            1,
            0, // One directory entry.
            0x12,
            0x01, // Orientation tag.
            3,
            0, // SHORT.
            1,
            0,
            0,
            0, // One value.
            orientation,
            0,
            0,
            0,
            0,
            0,
            0,
            0, // No next IFD.
        ];
        let mut exif = b"Exif\0\0".to_vec();
        exif.append(&mut tiff);
        let segment_length = u16::try_from(exif.len() + 2).expect("EXIF segment length");

        let mut output = Vec::with_capacity(jpeg.len() + exif.len() + 4);
        output.extend_from_slice(&jpeg[..2]);
        output.extend_from_slice(&[0xff, 0xe1]);
        output.extend_from_slice(&segment_length.to_be_bytes());
        output.extend_from_slice(&exif);
        output.extend_from_slice(&jpeg[2..]);
        output
    }

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

    #[test]
    fn enhance_bakes_exif_orientation_into_output_pixels() {
        let source = RgbaImage::from_pixel(2, 3, image::Rgba([40, 50, 60, 255]));
        let input = jpeg_with_orientation(&source, 6);

        let output = enhance_image(input).expect("enhance oriented JPEG");
        let decoded = image::load_from_memory(&output).expect("decode enhanced output");

        assert_eq!((decoded.width(), decoded.height()), (3, 2));
    }
}
