# TODO gpt generated, not sure how this will interact with docker, but this is more or less just a placeholder until the model is trained

import torch
from brevitas.export import export_finn_onnx
from finn.core.modelwrapper import ModelWrapper
from finn.builder.build_dataflow import build_dataflow_cfg, build_dataflow
from finn.builder import build_dataflow_cfg
from finn.transformation.fpgadataflow import *

import os

def export_brevitas_model_to_onnx(model, input_shape, export_path):
    dummy_input = torch.randn(*input_shape)
    export_finn_onnx(model, dummy_input, export_path)
    print(f"Exported Brevitas model to ONNX at: {export_path}")

def convert_onnx_to_finn(onnx_path, output_dir):
    # Create FINN model wrapper
    finn_model = ModelWrapper(onnx_path)

    # Apply a basic transformation sequence (more can be added)
    finn_model = finn_model.transform(InferShapes())
    finn_model = finn_model.transform(GiveUniqueNodeNames())
    finn_model = finn_model.transform(GiveReadableTensorNames())
    finn_model = finn_model.transform(InferDataLayouts())
    
    finn_model.save(os.path.join(output_dir, "model_finn.onnx"))
    print(f"Transformed ONNX model saved for FINN at: {output_dir}/model_finn.onnx")

# TODO configure this shit for u55c
def build_finn_hw_model(onnx_model_path, output_dir, target_clk_ns=10.0):
    cfg = build_dataflow_cfg(
        output_dir=output_dir,
        target_clk_ns=target_clk_ns,
        synth_clk_period_ns=target_clk_ns,
        board="Pynq-Z2",  # adjust to your target board
        shell_flow_type="vivado_zynq",  # or "vitis" etc.
        generate_outputs=["estimate_only"],  # or ["rtlsim", "bitfile"] etc.
    )
    build_dataflow(onnx_model_path, cfg)

# TODO fill in the correct params here
if __name__ == "__main__":
    # === Edit these paths / shapes for your setup ===
    model_path = "trained_model.pt"
    export_onnx_path = "model.onnx"
    finn_output_dir = "finn_output"
    input_shape = (1, 1, 28, 28) 

    # Load your trained Brevitas model
    model = torch.load(model_path)
    model.eval()

    # Export to ONNX
    export_brevitas_model_to_onnx(model, input_shape, export_onnx_path)

    # Convert ONNX to FINN format
    convert_onnx_to_finn(export_onnx_path, finn_output_dir)

    # Build (optional)
    build_finn_hw_model(os.path.join(finn_output_dir, "model_finn.onnx"), finn_output_dir)