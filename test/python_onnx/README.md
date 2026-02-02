# Python ONNX Inference Test

This directory contains a Python script to test the ONNX model inference for background removal. This is useful for comparing results with the Rust implementation and verifying CoreML support.

## Setup

1.  Create a virtual environment:
    ```bash
    python3 -m venv venv
    ```

2.  Activate the virtual environment:
    ```bash
    source venv/bin/activate
    ```

3.  Install dependencies:
    ```bash
    pip install -r requirements.txt
    ```

## Usage

Run the inference script:

```bash
python test_inference.py --model <path_to_model.onnx> --input <path_to_image.png> --output <path_to_save_result.png>
```

### Options

*   `--model`: Path to the `.onnx` model file.
*   `--input`: Path to the input image file.
*   `--output`: (Optional) Path to save the result mask (default: `output.png`).
*   `--use-coreml`: (Optional) Enable CoreML execution provider (macOS only).

### Example

```bash
python test_inference.py --model ../../assets/models/RMBG-2.0.onnx --input ../../assets/images/test.jpg --use-coreml
```
