import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ==========================================
// 1. DATA MODELS
// (Move these to your shared models folder if you have one)
// ==========================================
class ClothingItem {
  final String id;
  final String name;
  final String category;
  final String imageUrl;

  ClothingItem({required this.id, required this.name, required this.category, required this.imageUrl});

  factory ClothingItem.fromJson(Map<String, dynamic> json) {
    return ClothingItem(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown Item',
      category: json['category'] ?? 'Top',
      imageUrl: json['image_url'] ?? '',
    );
  }
}

class OutfitSuggestion {
  final String outfitId;
  final int matchScore;
  final String stylistNote;
  final List<ClothingItem> items;

  OutfitSuggestion({required this.outfitId, required this.matchScore, required this.stylistNote, required this.items});

  factory OutfitSuggestion.fromJson(Map<String, dynamic> json) {
    return OutfitSuggestion(
      outfitId: json['outfit_id'] ?? '',
      matchScore: json['match_score'] ?? 0,
      stylistNote: json['stylist_note'] ?? '',
      items: (json['items'] as List?)
              ?.map((i) => ClothingItem.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
String _lastAiMessage = '';


// ==========================================
// 2. THE SCREEN
// ==========================================
class StylistDeskScreen extends StatefulWidget {
  const StylistDeskScreen({super.key});

  @override
  State<StylistDeskScreen> createState() => _StylistDeskScreenState();
}

class _StylistDeskScreenState extends State<StylistDeskScreen> {
  // Use your app's centralized theme colors in production
  final Color primaryPurple = const Color(0xFF6C5CE7);
  final Color bgColor = const Color(0xFFF8F9FA);
  final Color textDark = const Color(0xFF2D3436);

  final TextEditingController _chatController = TextEditingController();

  OutfitSuggestion? _currentOutfit;
  bool _isLoading = true;
  String? _errorMessage;

  // 🔌 CONNECT YOUR NODE.JS BACKEND HERE
  // Replace with your actual IP or domain (e.g., http://10.0.2.2:3001 for Android Emulator)
  static const String backendUrl = 'http://localhost:3001';

  @override
  void initState() {
    super.initState();
    _fetchOutfitFromAI();
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

    Future<void> _fetchOutfitFromAI() async {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Hit the generate-outfit endpoint for the initial load
        final response = await http.post(
          Uri.parse('$backendUrl/ai/generate-outfit'), 
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'occasion': 'casual'}), // Default occasion
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          
          // Handle the response structure for generate-outfit
          final outfitData = data['outfits'] != null && data['outfits'].isNotEmpty 
              ? data['outfits'][0] 
              : data['outfit'];

          setState(() {
            if (outfitData != null) {
              _currentOutfit = OutfitSuggestion(
                outfitId: outfitData['id'] ?? '',
                matchScore: outfitData['match'] ?? outfitData['matchScore'] ?? 0,
                stylistNote: outfitData['explanation'] ?? outfitData['stylistNote'] ?? '',
                items: (outfitData['items'] as List?)?.map((i) => ClothingItem(
                  id: i['id'] ?? '',
                  name: i['name'] ?? 'Item',
                  category: i['category'] ?? 'Top',
                  imageUrl: i['image'] ?? i['imageUrl'] ?? '',
                )).toList() ?? [],
              );
              _lastAiMessage = "Here is a fresh outfit based on your wardrobe and today's weather!";
            }
            _isLoading = false;
          });
        } else {
          throw Exception('Failed to load initial outfit');
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Could not connect to the Stylist. Please try again.";
        });
      }
    }

  // Helper to position items dynamically based on category
  Alignment _getAlignmentForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'tops':
      case 'top':
        return const Alignment(-0.6, -0.7); 
      case 'bottoms':
      case 'bottom':
        return const Alignment(0.6, 0.1);  
      case 'shoes':
        return const Alignment(0.0, 0.8);  
      case 'dress':
        return const Alignment(0.0, 0.0);  
      case 'outerwear':
        return const Alignment(-0.8, 0.0); 
      case 'accessories':
      case 'accessory':
        return const Alignment(0.8, -0.6);
      default:
        return const Alignment(0.0, 0.0);
    }
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Your Stylist Desk", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: primaryPurple), 
            onPressed: _isLoading ? null : _fetchOutfitFromAI
          )
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryPurple),
            const SizedBox(height: 16),
            const Text("Analyzing your wardrobe...", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryPurple),
              onPressed: _fetchOutfitFromAI,
              child: const Text("Retry", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      );
    }

    // Main UI
    return SafeArea(
      child: Column(
        children: [
          // CANVAS
          Expanded(
            flex: 5,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15)],
              ),
              child: Stack(
                children: [
                  // Match Score Badge
                  if (_currentOutfit != null)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(20)),
                        child: Text("${_currentOutfit!.matchScore}% Match", style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  
                  // Render Items
                  if (_currentOutfit != null)
                    ..._currentOutfit!.items.map((item) {
                      return Align(
                        alignment: _getAlignmentForCategory(item.category),
                        child: _CanvasClothingItem(
                          item: item,
                          onTap: () => _showSwapBottomSheet(item),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),

          // CHAT & COMMANDS
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(backgroundColor: primaryPurple.withValues(alpha: 0.1), child: Icon(Icons.auto_awesome, color: primaryPurple, size: 20)),
                      const SizedBox(width: 12),
                      const Text("SmartWardrobe AI", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. The Chat Response (Conversational)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              // Fallback to stylist note if chat message is empty
                              _lastAiMessage.isNotEmpty ? _lastAiMessage : (_currentOutfit?.stylistNote ?? "No explanation provided."), 
                              style: TextStyle(color: textDark, height: 1.4, fontSize: 14)
                            ),
                          ),
                          
                          // 2. The Stylist Note (The "Why this outfit" logic)
                          if (_currentOutfit != null && _lastAiMessage.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Row(
                                children: [
                                  Icon(Icons.auto_awesome, size: 14, color: primaryPurple),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _currentOutfit!.stylistNote,
                                      style: TextStyle(
                                        color: Colors.grey.shade600, 
                                        fontSize: 12, 
                                        fontStyle: FontStyle.italic
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Action Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _ActionChip(label: "Make it Formal", onTap: () => _sendMessage("Make it more formal")),
                        _ActionChip(label: "Swap Shoes", onTap: () => _sendMessage("Swap the shoes")),
                        _ActionChip(label: "Warmer", onTap: () => _sendMessage("Make it warmer")),
                      ],
                    ),
                  ),
                  
                  // Input Field
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _chatController,
                            onSubmitted: _sendMessage,
                            decoration: InputDecoration(
                              hintText: 'Ask AI to swap items...',
                              filled: true,
                              fillColor: bgColor,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        CircleAvatar(
                          backgroundColor: primaryPurple,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_upward, color: Colors.white),
                            onPressed: () => _sendMessage(_chatController.text),
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _chatController.clear();
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true; 
    });

    try {
      final response = await http.post(
        // The correct endpoint from your backend code
        Uri.parse('$backendUrl/ai/chat'), 
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': text,
          'history': [], // You can pass previous chat messages here later
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Debug print so you can see exactly what the backend returned in your console
        print("BACKEND RESPONSE: $data");

        setState(() {
          _lastAiMessage = data['reply'] ?? 'No response text provided.';
          
          if (data['outfit'] != null) {
            _currentOutfit = OutfitSuggestion(
              outfitId: data['outfit']['id'] ?? '',
              matchScore: data['outfit']['match'] ?? 0, // Map 'match' to matchScore
              stylistNote: data['outfit']['explanation'] ?? '', // Map 'explanation' to stylistNote
              items: (data['outfit']['items'] as List?)?.map((i) => ClothingItem(
                id: i['id'] ?? '',
                name: i['name'] ?? 'Item',
                category: i['category'] ?? 'Top',
                imageUrl: i['image'] ?? '', // Map 'image' to imageUrl
              )).toList() ?? [],
            );
          }
          _isLoading = false; 
        });
      } else {
        throw Exception('Failed to get reply (Status: ${response.statusCode})');
      }
    } catch (e) {
      print("CHAT ERROR: $e"); // Log the error to see what went wrong
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not reach the stylist. Please try again.')),
      );
    }
  }

  void _showSwapBottomSheet(ClothingItem item) {
    // TODO: Fetch alternative items from the same category from backend here
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: 250,
        child: Column(
          children: [
            Text("Swap ${item.name}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Text("Fetching alternative ${item.category} items from your wardrobe...", textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 3. WIDGETS
// (Move these to your shared widgets folder)
// ==========================================
class _CanvasClothingItem extends StatelessWidget {
  final ClothingItem item;
  final VoidCallback onTap;

  const _CanvasClothingItem({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Determine if the image is a network URL or a local asset
    final bool isNetwork = item.imageUrl.startsWith('http');
    final bool hasImage = item.imageUrl.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 110,
            height: 130,
            decoration: BoxDecoration(
              color: Colors.grey.shade100, // Fallback background color
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: !hasImage
                  // 1. Fallback if the image URL is completely empty
                  ? const Center(
                      child: Icon(Icons.checkroom, size: 50, color: Colors.black26),
                    )
                  // 2. Network Image (e.g., http://...)
                  : isNetwork
                      ? Image.network(
                          item.imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6C5CE7)),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.broken_image, color: Colors.redAccent, size: 40),
                            );
                          },
                        )
                      // 3. Local Asset Image (e.g., assets/images/...)
                      : Image.asset(
                          item.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback if the asset path is wrong or file is missing
                            return const Center(
                              child: Icon(Icons.broken_image, color: Colors.redAccent, size: 40),
                            );
                          },
                        ),
            ),
          ),
          const SizedBox(height: 8),
          
          // The Label Container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                )
              ],
            ),
            child: Text(
              item.name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis, // Prevents long names from breaking the UI
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  
  const _ActionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        label: Text(label),
        onPressed: onTap,
        backgroundColor: const Color(0xFFF8F9FA),
        side: BorderSide(color: Colors.grey.shade300),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}