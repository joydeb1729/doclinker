# API Setup Instructions

## HuggingFace API Key (for Embeddings)

1. Go to [HuggingFace](https://huggingface.co/settings/tokens)
2. Sign up for a free account if you don't have one
3. Create a new token with "Read" permissions
4. Copy your API key (starts with `hf_`)

## Groq API Key (for Chat)

1. Go to [Groq Console](https://console.groq.com/keys)
2. Sign up for a free account
3. Create a new API key
4. Copy your API key (starts with `gsk_`)

## Configuration

1. Open `lib/config/app_config.dart`
2. Replace the placeholder API keys with your actual keys:
   ```dart
   static const String huggingFaceApiKey = 'hf_your_actual_api_key_here';
   static const String groqApiKey = 'gsk_your_actual_groq_key_here';
   ```

## Model Information

### HuggingFace (Embeddings)
The app uses `sentence-transformers/all-MiniLM-L6-v2` which:
- Is free to use
- Generates 384-dimensional embeddings
- Is optimized for semantic similarity
- Works well for medical text matching

### Groq (Chat)
The app uses Groq's fast LLMs:
- `llama-3.1-70b-versatile` for general chat (high quality)
- `llama-3.1-8b-instant` for medical queries (fast responses)
- Free tier: 14,400 requests/day
- Extremely fast inference (~100 tokens/second)

## Testing Embeddings

1. Configure your API key as above
2. Navigate to the "Embedding Generator" page in the admin section
3. Use the "Generate Embeddings for All Doctors" button to populate embeddings
4. Use "Test Embedding Similarity" to verify functionality

## Fallback Behavior

If the API key is not configured or the API fails:
- The system will generate deterministic fallback embeddings
- These are based on text content hashing
- They provide consistent but less accurate matching
- Production systems should use proper HuggingFace embeddings

## Rate Limits

### HuggingFace (Free Tier)
- 30,000 characters/month for inference API
- Rate limits of ~1000 requests/hour
- Model loading delays for first requests
- For production, consider HuggingFace Pro subscription

### Groq (Free Tier)
- 14,400 requests per day
- 30 requests per minute for Llama models
- No monthly character limits
- Extremely fast inference
- For higher limits, upgrade to Groq Pro

## Troubleshooting

**Error: "Model is loading"**
- Wait 10-20 seconds and retry
- First request to a model takes longer

**Error: "API key not configured"**
- Check your API key in `app_config.dart`
- Ensure key starts with `hf_`

**Error: "Rate limit exceeded"**
- Wait or upgrade to HuggingFace Pro
- Use fallback embeddings for development