# Smart Trip Planner

A comprehensive Flutter application designed for modern trip planning and travel management. Built with clean architecture principles and optimized for web deployment.

## Overview

Smart Trip Planner is a full-featured travel application that helps users plan, organize, and manage their trips efficiently. The application features a modern user interface, secure authentication system, and intelligent trip management capabilities.

## Key Features

- **User Authentication System**: Secure login and registration with password hashing
- **Modern User Interface**: Clean, responsive design following Material Design principles
- **AI-Powered Trip Planning**: Intelligent agent for generating and refining travel itineraries
- **Interactive Chat Assistant**: Real-time AI conversation for trip planning assistance
- **Smart Itinerary Generation**: Automated creation of detailed travel plans with activities
- **Trip Management**: Create, edit, and organize travel itineraries
- **Web-Optimized**: Built specifically for web platform with localStorage integration
- **Responsive Design**: Works seamlessly across different screen sizes
- **Custom Theming**: Consistent design system with professional color palette

## Technical Architecture

### Framework & Dependencies
- **Flutter**: 3.35.3
- **Dart**: Latest stable version
- **State Management**: Riverpod for reactive state management
- **HTTP Client**: Dio for API communications
- **Crypto**: SHA-256 for secure password hashing
- **Local Storage**: Web-compatible data persistence

### Project Structure
```
lib/
├── core/
│   ├── models/          # Data models and entities
│   ├── providers/        # Riverpod state providers
│   ├── repositories/     # Data access layer
│   ├── services/        # AI agent and core services
│   │   ├── agent_service.dart           # Main AI agent
│   │   ├── agent_streaming_service.dart # Streaming wrapper
│   │   └── web_search_service.dart      # Web search integration
│   ├── utils/           # Utility classes
│   │   ├── json_validator.dart         # AI response validation
│   │   └── itinerary_diff_engine.dart  # Change tracking
│   ├── theme/           # Application theming
│   └── constants/        # App constants
├── data/
│   ├── models/          # Data transfer objects
│   ├── repositories/     # Repository implementations
│   └── services/        # External service integrations
├── domain/
│   ├── entities/        # Business entities
│   ├── repositories/     # Repository interfaces
│   └── usecases/        # Business logic use cases
├── presentation/
│   ├── pages/           # Application screens
│   │   ├── auth/        # Authentication pages
│   │   ├── chat_page.dart              # AI chat interface
│   │   └── itinerary_generator_page.dart # AI generator
│   ├── widgets/         # Reusable UI components
│   │   ├── chat_message_widget.dart    # Chat message display
│   │   └── itinerary_diff_widget.dart  # Change visualization
│   └── providers/       # UI-specific providers
└── main.dart           # Application entry point
```

## AI Agent System

The Smart Trip Planner features a sophisticated AI agent system that powers intelligent trip planning and assistance:

### Core AI Components

#### **AgentService**
- **Primary AI Engine**: Handles itinerary generation and refinement
- **Multi-API Support**: Compatible with OpenAI GPT and Google Gemini APIs
- **Function Calling**: Structured JSON responses for consistent data format
- **Error Handling**: Robust error management with fallback mechanisms
- **Demo Mode**: Mock service for testing without API keys

#### **Streaming Chat Interface**
- **Real-time Responses**: Character-by-character streaming for natural conversation
- **Interactive Planning**: Dynamic itinerary creation through chat
- **Context Awareness**: Maintains conversation history and trip context
- **Visual Feedback**: Loading states and progress indicators

#### **Intelligent Itinerary Generation**
- **Smart Parsing**: Converts natural language to structured travel plans
- **Activity Scheduling**: Automatic time allocation and day planning
- **Location Intelligence**: Context-aware suggestions based on destinations
- **Refinement Capabilities**: Modify existing itineraries through conversation

### AI Features

#### **Chat Assistant**
- **Natural Language Processing**: Understands complex trip planning requests
- **Contextual Responses**: Maintains conversation flow and trip context
- **Streaming Interface**: Real-time response display for better UX
- **Error Recovery**: Graceful handling of API failures and edge cases

#### **Itinerary Generator**
- **Automated Planning**: Generates complete travel itineraries from descriptions
- **Activity Suggestions**: Provides relevant activities and attractions
- **Time Management**: Optimizes schedules and travel logistics
- **Customization**: Allows detailed refinement and personalization

#### **Web Search Integration**
- **Real-time Data**: Fetches current information about destinations
- **Restaurant Recommendations**: Finds local dining options
- **Attraction Discovery**: Identifies popular tourist spots
- **Weather Integration**: Considers seasonal factors in planning

### Technical Implementation

#### **Architecture Pattern**
```
User Input → Chat Interface → AgentService → AI API → JSON Parser → Itinerary Model
```

#### **Key Classes**
- `AgentService`: Core AI logic and API integration
- `AgentStreamingService`: Real-time response streaming
- `JsonValidator`: Ensures AI responses meet schema requirements
- `ItineraryDiffEngine`: Tracks changes between itinerary versions
- `WebSearchService`: Fetches real-time destination data

#### **Data Flow**
1. User sends message through chat interface
2. AgentService processes request with context
3. AI API generates structured response
4. JsonValidator ensures data integrity
5. Itinerary model created and displayed
6. Changes tracked for future refinements

### Demo Mode

For development and testing, the app includes a comprehensive demo mode:
- **Mock AgentService**: Simulates AI responses without API costs
- **Sample Data**: Generates realistic itineraries for any destination
- **Full Functionality**: All features work without API keys
- **Realistic Delays**: Simulates real API response times

## Getting Started

### Prerequisites
- Flutter SDK (3.35.3 or higher)
- Dart SDK
- Chrome browser (for web development)
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/AkshitShah96/smart_trip_planner.git
   cd smart_trip_planner
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run -d chrome
   ```

### AI Agent Configuration

#### **Demo Mode (Default)**
The app runs in demo mode by default, providing sample itineraries without requiring API keys:
```bash
flutter run -d chrome
```

#### **Real AI Integration**
To use real AI services, configure API keys:

**OpenAI Integration:**
```bash
flutter run -d chrome --dart-define=OPENAI_API_KEY=your_openai_key_here
```

**Google Gemini Integration:**
```bash
flutter run -d chrome --dart-define=GEMINI_API_KEY=your_gemini_key_here
```

**Both APIs:**
```bash
flutter run -d chrome --dart-define=OPENAI_API_KEY=your_key --dart-define=GEMINI_API_KEY=your_key
```

### Development Setup

For development purposes, ensure you have:
- Flutter development environment configured
- Web development tools installed
- Git configured with your credentials

## Authentication System

The application implements a secure authentication flow:

1. **User Registration**: New users can create accounts with email validation
2. **Secure Login**: Password verification using SHA-256 hashing
3. **Session Management**: Persistent login state using localStorage
4. **Data Security**: All sensitive data is properly encrypted and stored

## Database Architecture

- **Storage Method**: localStorage for web compatibility
- **Data Models**: Structured JSON-based data storage
- **User Data**: Secure storage of user profiles and preferences
- **Trip Data**: Persistent storage of travel itineraries

## User Interface Design

The application features a modern, professional interface with:
- Clean typography and spacing
- Consistent color scheme
- Intuitive navigation patterns
- Responsive layout design
- Accessibility considerations

## Development Guidelines

### Code Standards
- Follow Flutter/Dart best practices
- Implement proper error handling
- Use meaningful variable and function names
- Maintain clean architecture principles

### Testing
- Unit tests for business logic
- Widget tests for UI components
- Integration tests for user flows

## Browser Compatibility

- Chrome (recommended)
- Firefox
- Safari
- Edge

## Performance Optimization

- Lazy loading for large datasets
- Efficient state management
- Optimized image handling
- Minimal bundle size

## Security Features

- Password hashing with SHA-256
- Input validation and sanitization
- Secure data storage
- XSS protection

## Future Enhancements

### AI & Intelligence
- **Advanced AI Models**: Integration with GPT-4, Claude, and other cutting-edge models
- **Personalized Recommendations**: Machine learning-based trip suggestions
- **Voice Interface**: Speech-to-text and text-to-speech capabilities
- **Image Recognition**: AI-powered photo analysis for trip planning
- **Predictive Analytics**: Smart suggestions based on user preferences and behavior

### Platform & Features
- Mobile app versions (iOS/Android)
- Offline functionality with AI model caching
- Advanced trip analytics and insights
- Social sharing features with AI-generated content
- Integration with travel APIs (Google Places, Yelp, etc.)
- Real-time weather and traffic integration
- Multi-language support with AI translation

### Technical Improvements
- **Edge AI**: On-device AI processing for faster responses
- **Custom AI Training**: Domain-specific model fine-tuning
- **Advanced Streaming**: Real-time collaboration and sharing
- **AI-Powered Search**: Semantic search across trip data
- **Smart Notifications**: Context-aware reminders and suggestions


## License

This project is licensed under the MIT License. See the LICENSE file for details.

