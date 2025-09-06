# Real LLM Integration Guide

## 🚀 Your Smart Trip Planner is Ready for Real LLM Integration!

Your project already has a sophisticated AI agent system that supports both **OpenAI GPT-4** and **Google Gemini Pro**. Here's how to integrate real LLM models:

## 📋 Current Setup Status

✅ **Agent Service**: Fully implemented with dual API support  
✅ **Function Calling**: OpenAI function calling for structured responses  
✅ **JSON Validation**: Robust response validation and parsing  
✅ **Web Search Integration**: Real-time information retrieval  
✅ **Error Handling**: Comprehensive error management  
✅ **Streaming Support**: Real-time chat responses  
✅ **Mock Service**: Demo mode for testing without API keys  

## 🔑 API Key Configuration

### Method 1: Environment Variables (Recommended)

#### For OpenAI:
```bash
# Windows PowerShell
$env:OPENAI_API_KEY="your-openai-api-key-here"

# Windows Command Prompt
set OPENAI_API_KEY=your-openai-api-key-here

# Linux/Mac
export OPENAI_API_KEY="your-openai-api-key-here"
```

#### For Google Gemini:
```bash
# Windows PowerShell
$env:GEMINI_API_KEY="your-gemini-api-key-here"

# Windows Command Prompt
set GEMINI_API_KEY=your-gemini-api-key-here

# Linux/Mac
export GEMINI_API_KEY="your-gemini-api-key-here"
```

### Method 2: Dart Define (Alternative)

#### Run with OpenAI:
```bash
flutter run -d chrome --dart-define=OPENAI_API_KEY=your-openai-api-key-here
```

#### Run with Gemini:
```bash
flutter run -d chrome --dart-define=GEMINI_API_KEY=your-gemini-api-key-here
```

#### Run with Both APIs:
```bash
flutter run -d chrome --dart-define=OPENAI_API_KEY=your-openai-key --dart-define=GEMINI_API_KEY=your-gemini-key
```

## 🎯 Supported LLM Models

### OpenAI Models
- **GPT-4** (Default) - Best for complex itinerary planning
- **GPT-3.5-turbo** - Faster, cost-effective option
- **GPT-4-turbo** - Latest model with improved performance

### Google Gemini Models
- **Gemini Pro** (Default) - Google's flagship model
- **Gemini Pro Vision** - For image-based planning (future enhancement)

## 🔧 How to Get API Keys

### OpenAI API Key
1. Visit [OpenAI Platform](https://platform.openai.com/)
2. Sign up or log in
3. Go to API Keys section
4. Create a new secret key
5. Copy the key (starts with `sk-`)

### Google Gemini API Key
1. Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with Google account
3. Create a new API key
4. Copy the key

## 🧪 Testing Your Integration

### 1. Check API Configuration
```bash
flutter run -d chrome
```
Look for these status messages:
- ✅ "AI Agent Service Available" - Real LLM integration working
- ❌ "AI Agent Service Not Configured" - Using demo mode

### 2. Test Chat Interface
1. Open the app in Chrome
2. Navigate to Chat page
3. Send a message like: "Plan a 3-day trip to Tokyo"
4. You should see real AI responses (not mock data)

### 3. Test Itinerary Generation
1. Go to Itinerary Generator page
2. Enter: "Create a detailed 5-day itinerary for Paris"
3. Check if you get structured, detailed responses

## 🎛️ Advanced Configuration

### Custom Model Selection
To use different models, modify `agent_service.dart`:

```dart
// For GPT-3.5-turbo instead of GPT-4
'model': 'gpt-3.5-turbo',

// For different Gemini model
'generationConfig': {
  'temperature': 0.7,
  'maxOutputTokens': 2000,
  'model': 'gemini-pro', // or 'gemini-pro-vision'
},
```

### Web Search Integration
Your app includes real-time web search for enhanced itineraries:
- Automatic location detection
- Restaurant and hotel recommendations
- Current events and attractions
- Transportation information

## 🚨 Troubleshooting

### Common Issues

#### 1. "AI Agent Service Not Configured"
- Check if API keys are properly set
- Verify environment variables are loaded
- Restart your terminal/IDE after setting variables

#### 2. "Invalid API key" Error
- Verify your API key is correct
- Check if you have sufficient credits/quota
- Ensure the key has proper permissions

#### 3. Rate Limit Errors
- You've exceeded API rate limits
- Wait a few minutes and try again
- Consider upgrading your API plan

#### 4. Network Timeout
- Check your internet connection
- API servers might be temporarily unavailable
- Try again in a few minutes

### Debug Mode
Enable debug logging by adding this to your run command:
```bash
flutter run -d chrome --dart-define=DEBUG_MODE=true
```

## 💡 Best Practices

### 1. API Key Security
- Never commit API keys to version control
- Use environment variables or secure key management
- Rotate keys regularly

### 2. Cost Management
- Monitor your API usage
- Set up billing alerts
- Use demo mode for development

### 3. Performance Optimization
- Cache responses when possible
- Use appropriate model for the task
- Implement request batching

## 🎉 You're All Set!

Your Smart Trip Planner now supports real LLM integration with:
- **OpenAI GPT-4** for premium itinerary planning
- **Google Gemini Pro** for alternative AI responses
- **Web Search Integration** for real-time data
- **Robust Error Handling** for production use
- **Demo Mode** for development and testing

Start by setting up your API keys and run the app to experience real AI-powered trip planning!

