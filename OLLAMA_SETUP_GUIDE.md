# Ollama Setup Guide - Open-Source LLM Integration

## 🦙 **What is Ollama?**

Ollama is a tool that allows you to run large language models locally on your machine. This means you can use powerful AI models without needing API keys or internet connectivity for the AI responses.

## 🚀 **Benefits of Using Ollama**

- ✅ **Free**: No API costs or usage limits
- ✅ **Private**: Your data stays on your machine
- ✅ **Offline**: Works without internet (except for web search)
- ✅ **Fast**: No network latency
- ✅ **Customizable**: Choose from many open-source models

## 📋 **Supported Models**

Your Smart Trip Planner supports these popular Ollama models:

### **Recommended Models:**
- **llama2** (Default) - Meta's Llama 2, good balance of quality and speed
- **llama2:13b** - Larger version with better quality
- **codellama** - Specialized for code generation
- **mistral** - Fast and efficient model
- **neural-chat** - Optimized for conversations

### **Specialized Models:**
- **llama2-uncensored** - Uncensored version
- **wizard-vicuna-uncensored** - Creative writing focused
- **orca-mini** - Lightweight model for faster responses

## 🛠️ **Installation Steps**

### **Step 1: Install Ollama**

#### **Windows:**
1. Download from [ollama.ai](https://ollama.ai/download)
2. Run the installer
3. Ollama will start automatically

#### **macOS:**
```bash
# Install via Homebrew
brew install ollama

# Or download from website
# Visit https://ollama.ai/download
```

#### **Linux:**
```bash
# Install via curl
curl -fsSL https://ollama.ai/install.sh | sh

# Or via package manager
sudo apt install ollama  # Ubuntu/Debian
sudo dnf install ollama  # Fedora
```

### **Step 2: Pull a Model**

```bash
# Pull the default model (llama2)
ollama pull llama2

# Or try other models
ollama pull mistral
ollama pull neural-chat
ollama pull codellama
```

### **Step 3: Verify Installation**

```bash
# Check if Ollama is running
ollama list

# Test with a simple prompt
ollama run llama2 "Hello, how are you?"
```

## 🔧 **Configuration in Smart Trip Planner**

### **Automatic Detection**
Your app will automatically detect if Ollama is running and use it as a fallback when no API keys are configured.

### **Manual Configuration**
You can customize the Ollama settings by modifying the provider:

```dart
// In lib/core/providers/agent_service_provider.dart
final ollamaServiceProvider = Provider<OllamaService?>((ref) {
  return OllamaServiceFactory.createService(
    baseUrl: 'http://localhost:11434', // Default Ollama URL
    model: 'llama2', // Change to your preferred model
    enableWebSearch: true,
  );
});
```

### **Custom Models**
To use a different model:

1. **Pull the model:**
   ```bash
   ollama pull mistral
   ```

2. **Update the provider:**
   ```dart
   model: 'mistral', // Use your preferred model
   ```

## 🎯 **Usage Examples**

### **Basic Usage**
```bash
# Start Ollama (if not already running)
ollama serve

# Run your Flutter app
flutter run -d chrome
```

The app will automatically use Ollama when:
- No OpenAI API key is configured
- No Gemini API key is configured
- Ollama server is available

### **Model Management**
```bash
# List available models
ollama list

# Pull a new model
ollama pull llama2:13b

# Remove a model
ollama rm llama2

# Update a model
ollama pull llama2
```

## 🚨 **Troubleshooting**

### **Common Issues**

#### **1. "Ollama server not found"**
- Ensure Ollama is running: `ollama serve`
- Check if the default port (11434) is available
- Verify the URL in your configuration

#### **2. "Model not found"**
- Pull the model: `ollama pull llama2`
- Check available models: `ollama list`
- Verify the model name in your configuration

#### **3. Slow responses**
- Try a smaller model: `ollama pull mistral`
- Ensure you have enough RAM (8GB+ recommended)
- Close other resource-intensive applications

#### **4. Out of memory errors**
- Use a smaller model
- Increase system RAM
- Close other applications

### **Performance Tips**

#### **For Better Speed:**
- Use smaller models (mistral, orca-mini)
- Ensure sufficient RAM (8GB+)
- Use SSD storage
- Close unnecessary applications

#### **For Better Quality:**
- Use larger models (llama2:13b, neural-chat)
- Ensure sufficient RAM (16GB+)
- Use GPU acceleration if available

## 🔄 **Model Comparison**

| Model | Size | Speed | Quality | Use Case |
|-------|------|-------|---------|----------|
| **mistral** | 4GB | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Fast responses |
| **llama2** | 4GB | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Balanced |
| **llama2:13b** | 7GB | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | High quality |
| **neural-chat** | 4GB | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Conversations |
| **codellama** | 4GB | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Code generation |

## 🎉 **You're Ready!**

Your Smart Trip Planner now supports:
- ✅ **OpenAI GPT-4** (with API key)
- ✅ **Google Gemini Pro** (with API key)
- ✅ **Ollama Local Models** (free, no API key needed)
- ✅ **Demo Mode** (fallback when nothing is available)

### **Priority Order:**
1. **OpenAI** (if API key configured)
2. **Gemini** (if API key configured)
3. **Ollama** (if server available)
4. **Demo Mode** (fallback)

Start Ollama and run your app to experience local AI-powered trip planning!

