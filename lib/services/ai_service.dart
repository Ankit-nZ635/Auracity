import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AiService {
  static const String _groqApiKey = 'YOUR_GROQ_API_KEY_HERE';
  static const String _groqEndpoint = 'https://api.groq.com/openai/v1/chat/completions';

  static Future<Map<String, String>> analyzeIssue(String description, XFile? imageFile) async {
    final prompt = '''
You are a civic issue classifier for a smart city app.
Analyze this civic issue report (and its photo if provided).
Output ONLY a valid JSON object, no extra text:
{
  "detailedType": "Category -> Subtype",
  "estimatedTime": "X Hours/Days",
  "priority": "Urgent" | "General" | "Normal",
  "department": "Roads" | "Waste" | "Water" | "Power" | "Police" | "Parks",
  "suggestedEmoji": "emoji",
  "summary": "A concise 1-2 sentence description of the issue."
}
Description: $description
''';

    final List<String> modelIds = [
      'meta-llama/llama-4-scout-17b-16e-instruct',
    ];

    String lastError = "Unknown Error";

    for (var modelId in modelIds) {
      try {
        debugPrint("AI Service [Groq]: Probing $modelId...");

        final List<Map<String, dynamic>> contentParts = [
          {"type": "text", "text": prompt},
        ];

        if (imageFile != null) {
          final bytes = await imageFile.readAsBytes();
          final base64Image = base64Encode(bytes);
          contentParts.add({
            "type": "image_url",
            "image_url": {
              "url": "data:image/jpeg;base64,$base64Image",
            }
          });
        }

        final body = jsonEncode({
          "model": modelId,
          "messages": [
            {
              "role": "user",
              "content": contentParts,
            }
          ],
          "temperature": 0.3,
          "max_tokens": 300,
        });

        final response = await http.post(
          Uri.parse(_groqEndpoint),
          headers: {
            'Authorization': 'Bearer $_groqApiKey',
            'Content-Type': 'application/json',
          },
          body: body,
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          final text = responseData['choices'][0]['message']['content'] ?? '{}';
          
          final jsonRegex = RegExp(r"\{[\s\S]*\}");
          final match = jsonRegex.firstMatch(text);
          if (match != null) {
            final Map<String, dynamic> data = jsonDecode(match.group(0)!);
            return {
              'priority': data['priority'] ?? 'General',
              'detailedType': data['detailedType'] ?? 'General Issue',
              'estimatedTime': data['estimatedTime'] ?? 'TBD',
              'department': data['department'] ?? 'General',
              'suggestedEmoji': data['suggestedEmoji'] ?? '📍',
              'summary': data['summary'] ?? 'No summary provided.',
              'isLocal': 'false',
            };
          }
        }
      } catch (e) {
        lastError = e.toString();
      }
    }

    final fallback = _localSmartSimulation(description);
    fallback['analysisError'] = lastError;
    return fallback;
  }

  static Future<Map<String, dynamic>> verifyResolution(
      String originalTitle, String originalDesc, String originalImageUrl, Uint8List proofBytes) async {
    final prompt = '''
You are a civic quality auditor. 
COMPARE the "Original Issue" (described below) with the "Proof of Resolution" photo.
Determine if the work is PHYSICALLY COMPLETED based on the photos and description.

Original Issue: $originalTitle - $originalDesc

Output ONLY a valid JSON object:
{
  "isResolved": true | false,
  "feedback": "A concise explanation for the citizen and resolver.",
  "confidence": 0.0 to 1.0,
  "payoutReward": number (estimated fair work pay in INR between 100 and 5000),
  "workRating": integer (1-5 rating based on quality and accuracy)
}
''';

    final List<String> modelIds = ['meta-llama/llama-4-scout-17b-16e-instruct'];

    for (var modelId in modelIds) {
      try {
        final List<Map<String, dynamic>> contentParts = [
          {"type": "text", "text": prompt},
        ];

        if (originalImageUrl.isNotEmpty) {
          contentParts.add({
            "type": "image_url",
            "image_url": {"url": originalImageUrl}
          });
        }

        final base64Proof = base64Encode(proofBytes);
        contentParts.add({
          "type": "image_url",
          "image_url": {
            "url": "data:image/jpeg;base64,$base64Proof",
          }
        });

        final body = jsonEncode({
          "model": modelId,
          "messages": [
            {"role": "user", "content": contentParts}
          ],
          "temperature": 0.1,
          "max_tokens": 300,
        });

        final response = await http.post(
          Uri.parse(_groqEndpoint),
          headers: {
            'Authorization': 'Bearer $_groqApiKey',
            'Content-Type': 'application/json',
          },
          body: body,
        ).timeout(const Duration(seconds: 45));

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          final text = responseData['choices'][0]['message']['content'] ?? '{}';
          final jsonRegex = RegExp(r"\{[\s\S]*\}");
          final match = jsonRegex.firstMatch(text);
          if (match != null) {
            final Map<String, dynamic> data = jsonDecode(match.group(0)!);
            return {
              'isResolved': data['isResolved'] ?? false,
              'feedback': data['feedback'] ?? 'Verification inconclusive.',
              'confidence': data['confidence'] ?? 0.5,
              'payoutReward': (data['payoutReward'] ?? 0.0).toDouble(),
              'workRating': data['workRating'] ?? 3,
              'apiUsed': true,
            };
          }
        }
      } catch (e) {
        debugPrint("AI Verification Error: $e");
      }
    }

    return {
      'isResolved': true,
      'feedback': 'Offline Manual Trust fallback applied.',
      'confidence': 1.0,
      'apiUsed': false,
    };
  }

  static Future<String> getChatSupportResponse(List<Map<String, String>> history) async {
    const String systemPrompt = '''
You are AuraBot, the helpful AI concierge for Auracity, a professional civic governance platform.
Your goal is to guide users on how the app works with a helpful, modern, and efficient tone.

KEY APP FACTS:
1. Auracity is NOT a game; it's a professional platform for city management.
2. CITY TREASURY: The admin manages a ₹5,00,000 city budget to pay for repairs.
3. REPORTING: Users report issues by taking photos on the map.
4. RESOLVERS: Department workers (Resolvers) fix reported issues.
5. AI PAYOUTS: After a fix, our AI audits the work and automatically pays the Resolver between ₹100 and ₹5000 based on quality.
6. CREDIBILITY: Resolvers have a 1-5 star "Credibility Score" assigned strictly by the AI system based on fix accuracy.
7. TRANSPARENCY: All expenses are logged in a public (for admin) audit trail.

RULES:
- Be concise. Use emojis like 🤖, 🏙️, ⚡.
- If you don't know an app specific detail, say you are still learning that part of the city grid.
- NEVER mention Groq, LLMs, or being an AI model. You are AuraBot.
''';

    final List<Map<String, dynamic>> messages = [
      {"role": "system", "content": systemPrompt},
      ...history,
    ];

    try {
      final body = jsonEncode({
        "model": "meta-llama/llama-4-scout-17b-16e-instruct",
        "messages": messages,
        "temperature": 0.7,
        "max_tokens": 500,
      });

      final response = await http.post(
        Uri.parse(_groqEndpoint),
        headers: {
          'Authorization': 'Bearer $_groqApiKey',
          'Content-Type': 'application/json',
        },
        body: body,
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ?? "I'm having trouble connecting to the city grid right now. 🏙️";
      }
    } catch (e) {
      debugPrint("AuraBot Error: $e");
    }
    
    return "The city grid is currently undergoing maintenance. Please try again in a moment. 🤖";
  }

  static Map<String, String> _localSmartSimulation(String desc) {
    final text = desc.toLowerCase();
    final Map<List<String>, Map<String, String>> kb = {
      ['water', 'leak', 'pipe', 'burst', 'drain', 'flood', 'sewage']: {
        'priority': 'General',
        'detailedType': 'Water -> Infrastructure Fault',
        'estimatedTime': '8-12 Hours',
        'department': 'Water',
        'suggestedEmoji': '🚰',
        'summary': 'Potential water infrastructure or leakage issue identified.',
        'isLocal': 'true',
      },
      ['road', 'pothole', 'crack', 'pavement']: {
        'priority': 'General',
        'detailedType': 'Road -> Pothole Damage',
        'estimatedTime': '2-3 Days',
        'department': 'Roads',
        'suggestedEmoji': '🚧',
        'summary': 'Road or infrastructure damage reported in the vicinity.',
        'isLocal': 'true',
      },
    };

    for (var entry in kb.entries) {
      if (entry.key.any((keyword) => text.contains(keyword))) {
        return entry.value;
      }
    }

    return {
      'priority': 'Normal',
      'detailedType': 'City Mgmt -> General Monitoring',
      'estimatedTime': '48 Hours',
      'department': 'General',
      'suggestedEmoji': '📍',
      'summary': 'General civic issue requiring attention.',
      'isLocal': 'true',
    };
  }
}
