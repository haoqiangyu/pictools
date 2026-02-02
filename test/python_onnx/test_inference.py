import onnxruntime as ort
import numpy as np
from PIL import Image
import sys
import os
import argparse

def preprocess(image_path):
    # 1. Load image
    img = Image.open(image_path).convert('RGB')
    
    # 2. Resize to 1024x1024 (using Lanczos)
    img = img.resize((1024, 1024), Image.Resampling.LANCZOS)
    
    # 3. Normalize
    # ImageNet mean and std
    mean = np.array([0.485, 0.456, 0.406], dtype=np.float32)
    std = np.array([0.229, 0.224, 0.225], dtype=np.float32)
    
    img_data = np.array(img).astype(np.float32) / 255.0
    img_data = (img_data - mean) / std
    
    # 4. Transpose to NCHW: [1, 3, 1024, 1024]
    img_data = img_data.transpose(2, 0, 1)
    img_data = np.expand_dims(img_data, axis=0)
    
    return img_data, img

def postprocess(output, original_img):
    # Output shape is [1, 1, 1024, 1024]
    mask = output[0][0]
    
    # Convert mask to image
    mask_img = Image.fromarray((mask * 255).astype(np.uint8), mode='L')
    
    return mask_img

def main():
    parser = argparse.ArgumentParser(description='Test ONNX model for background removal')
    parser.add_argument('--model', required=True, help='Path to ONNX model')
    parser.add_argument('--input', required=True, help='Path to input image')
    parser.add_argument('--output', default='output.png', help='Path to save output mask')
    parser.add_argument('--use-coreml', action='store_true', help='Enable CoreML provider')
    
    args = parser.parse_args()
    
    if not os.path.exists(args.model):
        print(f"Error: Model not found at {args.model}")
        return
    
    if not os.path.exists(args.input):
        print(f"Error: Input image not found at {args.input}")
        return
        
    # Configure session options
    providers = ['CPUExecutionProvider']
    if args.use_coreml:
        # Put CoreML first
        providers.insert(0, 'CoreMLExecutionProvider')
        
    print(f"Creating session with providers: {providers}")
    
    sess_options = ort.SessionOptions()
    # Disable graph optimizations to avoid "Attempting to get index by a name which does not exist" error
    sess_options.graph_optimization_level = ort.GraphOptimizationLevel.ORT_DISABLE_ALL

    try:
        session = ort.InferenceSession(args.model, sess_options=sess_options, providers=providers)
    except Exception as e:
        print(f"Failed to create session with requested providers: {e}")
        # Fallback to CPU if failed (though ONNX Runtime usually does this automatically)
        print("Falling back to CPUExecutionProvider")
        session = ort.InferenceSession(args.model, sess_options=sess_options, providers=['CPUExecutionProvider'])

    print(f"Active providers: {session.get_providers()}")
    
    # Preprocess
    input_data, _ = preprocess(args.input)
    input_name = session.get_inputs()[0].name
    
    # Inference
    print("Running inference...")
    result = session.run(None, {input_name: input_data})
    
    # Postprocess
    mask_img = postprocess(result[0], None)
    mask_img.save(args.output)
    print(f"Result saved to {args.output}")

if __name__ == '__main__':
    main()
