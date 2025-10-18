-- columns as part of asset table --
1. Seed
Think of it like the random number seed used to initialize generation.
If you use the same prompt + negative_prompt + model + seed, you’ll get the same output again.
If you use a different seed, you’ll get a variation.

👉 Why store it?
Ensures reproducibility (same image/video can be regenerated later).
Useful for A/B testing (generate multiple versions of the same prompt with different seeds).

2. Steps
Refers to the number of diffusion steps / iterations the model runs to refine the image/video.
More steps → higher quality but slower.
Fewer steps → faster but lower quality.

👉 Why store it?
Lets you trace back how an image/video was generated.
Helps tune performance vs. quality tradeoffs.

3. Sampler
The sampling algorithm used to denoise the image during diffusion (examples: Euler, DDIM, LMS, DPM++).
Different samplers can produce different styles even with the same prompt & seed.

👉 Why store it?
Some users prefer specific samplers (e.g., smoother vs. sharper results).
Needed to regenerate identical outputs.
Helps analyze which sampler works best for certain content

4.guidance_scale (sometimes called classifier-free guidance (CFG) scale).
What is guidance_scale?
It controls how strongly the model should follow your prompt versus allowing creative freedom.

A low guidance_scale (e.g., 2–4) → Model has more freedom, can generate diverse/creative outputs, but may not match your text prompt very accurately.
A high guidance_scale (e.g., 10–15) → Model sticks closely to the prompt, but can become rigid or produce artifacts.
A very high value (e.g., >20) → Often harms image quality, making it look overfitted or unnatural.

Practical ranges
4–7 → More artistic/loose results.
7–12 → Balanced, realistic images (commonly used).
12–15 → Strong adherence to prompt (good for strict requirements).
>15 → Usually not recommended (images may break).


5. Negative Prompt
A negative prompt tells the AI what you don’t want in the output.
Positive prompt → guides the model toward desired features.
Negative prompt → prevents unwanted features.

🔹 Example (Image Generation)
Prompt:
"A high-quality photo of a golden retriever playing in the park"

Negative Prompt:
"blurry, low-resolution, distorted, extra limbs, watermark"
👉 Result: The model avoids generating blurry or distorted dogs, or images with watermarks.
🔹 Example (Video Generation)

Prompt:
"A cinematic shot of a futuristic city skyline at sunset"

Negative Prompt:
"low detail, flickering, artifacts, text overlays"
👉 Result: Helps reduce flickering frames and unwanted artifacts.


-- columns as part of image_asset table

1. metadata JSONB

Purpose: Stores additional structured info about the image that isn’t fixed in the table columns.
Advantages of JSONB: Flexible, can store key-value pairs or nested objects, searchable using PostgreSQL JSON operators.
Possible contents:

{
  "color_mode": "RGB",
  "size_bytes": 204800,
  "tags": ["fashion", "summer", "model"],
  "ai_model": "stable-diffusion-v1",
  "generation_params": {
    "prompt_strength": 0.8,
    "negative_prompt": "blurry, low-res",
    "seed": 12345
  },
  "thumbnail_url": "https://cdn.example.com/thumb/123.png"
}

{
  "ai_model": "stable-diffusion-v1",
  "generation_params": {"prompt":"summer fashion", "seed":12345},
  "tags":["fashion", "summer"],
  "storage_url":"s3://bucket/image123.png"
}


2. format

Purpose: Stores the file format of the image.
Examples of values:

"jpg" or "jpeg" → common photographic images
"png" → supports transparency
"webp" → optimized for web
"gif" → animations
"tiff", "bmp" → less common, high-quality formats
Usage: Helps your application know how to render or export the image and what MIME type to use.


-- columns as part of video_asset table
2. metadata JSONB
{
  "ai_model": "stable-diffusion-video-v1",
  "generation_params": {
    "prompt": "fashion runway, summer collection, 4k",
    "negative_prompt": "blurry, shaky",
    "seed": 98765,
    "steps": 50
  },
  "tags": ["fashion", "runway", "summer"],
  "bitrate_kbps": 4500,
  "codec": "H.264",
  "thumbnail_url": "https://cdn.example.com/thumbs/video_123.png",
  "preview_gif": "https://cdn.example.com/previews/video_123.gif"
}

{
  "ai_model":"stable-diffusion-video-v1",
  "generation_params":{"prompt":"runway show","steps":50},
  "tags":["fashion","runway"],
  "codec":"H.264",
  "thumbnail_url":"https://cdn.example.com/thumb.png"
}


-- columns as part of audio_asset table
3. metadata JSONB

{
  "ai_model":"text-to-speech-v1",
  "generation_params":{"text":"Welcome to our store","voice":"female"},
  "tags":["announcement"],
  "storage_url":"s3://bucket/audio123.mp3"
}


-- Bulk assets generation --
Flow in Practice

1. Merchant selects assets (e.g., 20 product images).
2. Chooses a template/style → a batch_job record is created.
3. System inserts mapping rows into batch_job_asset.
4. Worker/queue processes each row, generating new versions of images.
5. Each result links back to asset_generation via result_asset_generation_id.
6. Merchant can see per-asset results and overall batch status



-------- Worker Job flow -------------
asset_generation created → status = pending.
Worker picks up job → asset_generation_attempts entry created (attempt 1).
If it fails → error logged, retry_count incremented, new row in asset_generation_attempts.
If it finally succeeds → last attempt marked completed, parent row updated.
If it fails after max retries → record goes into dead_letter_log, parent marked failed.