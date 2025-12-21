
import 'package:google_generative_ai/google_generative_ai.dart';

class ChatService {
  // IMPORTANT: Replace with your actual Gemini API Key.
  // For a real app, load this from a secure location (e.g., using flutter_dotenv).
  // For the hackathon, we'll place it here for speed.
  final String _apiKey = 'YOUR_GEMINI_API_KEY';

  late final GenerativeModel _model;
  late final ChatSession _chat;

  ChatService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash', // Or another model you prefer
      apiKey: _apiKey,
      // System instructions to guide the chatbot's behavior.
      // This is where you define the persona and knowledge base for "The Brain".
      systemInstruction: Content.text(
        '''You are "The Brain", a helpful AI assistant for students at the Central Institute of Technology, Kokrajhar (CITK).
        - Your goal is to answer questions about the college based on the information provided.
        - Be friendly, concise, and helpful.
        - If you don't know the answer, say "I'm sorry, I don't have information on that topic. You might want to ask a senior or a faculty member."
        - Here are some key facts about CITK:
          - The academic passing criteria is a minimum of 40% in each subject.
          - The library is open from 9 AM to 8 PM on weekdays.
          - Wi-Fi is available in all academic buildings and hostels.
        '''
      ),
    );
    _chat = _model.startChat();
  }

  /// Sends a message to the Gemini API and returns the chatbot's response.
  Future<String> sendMessage(String userMessage) async {
    try {
      final response = await _chat.sendMessage(Content.text(userMessage));
      final text = response.text;

      if (text == null) {
        return 'I am unable to process this request at the moment.';
      }
      return text;
    } catch (e) {
      // Basic error handling. In a real app, you'd want to log this.
      print('Error sending message to Gemini: $e');
      return 'There was an error communicating with the AI. Please try again.';
    }
  }
}
