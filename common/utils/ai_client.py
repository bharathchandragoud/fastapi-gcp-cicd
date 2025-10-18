import httpx

async def generate_ai_image(prompt: str):
    async with httpx.AsyncClient() as client:
        response = await client.post('https://api-inference.huggingface.co/models/Qwen', json={'inputs': prompt})
        return response.json()
