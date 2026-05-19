/// Preset AI vision models available for receipt OCR.
///
/// Each entry: (modelId, displayName, isFree)
final List<(String, String, bool)> presetAiModels = [
  ('nvidia/nemotron-nano-12b-v2-vl:free', 'NVIDIA Nemotron Nano 12B VL', true),
  ('google/gemma-4-31b-it:free', 'Google Gemma 4 31B', true),
  ('nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free', 'NVIDIA Nemotron 3 Nano Omni', true),
  ('qwen/qwen2.5-vl-72b-instruct:free', 'Qwen 2.5 VL 72B', true),
  ('---', '─── Model Berbayar ───', false),
  ('openai/gpt-5-nano', 'GPT-5 Nano (termurah)', false),
  ('google/gemma-4-26b-a4b-it', 'Google Gemma 4 26B A4B (murah)', false),
  ('baidu/ernie-4.5-vl-28b-a3b', 'Baidu ERNIE 4.5 VL 28B (murah)', false),
  ('openai/gpt-5-mini', 'GPT-5 Mini (ekonomis)', false),
];
