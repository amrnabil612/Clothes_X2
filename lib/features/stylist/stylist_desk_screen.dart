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
  static const String backendUrl = 'http://YOUR_IP_ADDRESS:3001/api/stylist/suggest';

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
      // TODO: Uncomment and use this when your backend is running
      /*
      final response = await http.get(Uri.parse(backendUrl));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _currentOutfit = OutfitSuggestion.fromJson(data);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load outfit (Status: ${response.statusCode})');
      }
      */

      // MOCK DELAY FOR NOW (Remove this when uncommenting the real API call above)
      await Future.delayed(const Duration(seconds: 2));
      
      setState(() {
        _currentOutfit = OutfitSuggestion(
          outfitId: "outfit_789",
          matchScore: 94,
          stylistNote: "Here is a smart-casual look for today's 24°C weather. The loafers elevate the jeans for your university presentation.",
          items: [
            ClothingItem(id: "1", name: "White Oxford", category: "Top", imageUrl: ""),
            ClothingItem(id: "2", name: "Blue Jeans", category: "Bottom", imageUrl: ""),
            ClothingItem(id: "3", name: "Brown Loafers", category: "Shoes", imageUrl: ""),
          ],
        );
        _isLoading = false;
      });

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
      case 'top':
        return const Alignment(-0.4, -0.5); 
      case 'bottom':
        return const Alignment(0.4, 0.1);  
      case 'shoes':
        return const Alignment(0.0, 0.7);  
      case 'dress':
        return const Alignment(0.0, 0.0);  
      case 'outerwear':
        return const Alignment(-0.7, 0.1); 
      case 'accessory':
        return const Alignment(0.7, -0.6);
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
            flex: 6,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15)],
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
                    }).toList(),
                ],
              ),
            ),
          ),

          // CHAT & COMMANDS
          Expanded(
            flex: 4,
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
                      CircleAvatar(backgroundColor: primaryPurple.withOpacity(0.1), child: Icon(Icons.auto_awesome, color: primaryPurple, size: 20)),
                      const SizedBox(width: 12),
                      const Text("SmartWardrobe AI", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // AI Explanation (Scrollable to prevent overflow)
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _currentOutfit?.stylistNote ?? "No explanation provided.", 
                          style: TextStyle(color: textDark, height: 1.4, fontSize: 14)
                        ),
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
                  
                  const Spacer(),
                  
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

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    _chatController.clear();
    FocusScope.of(context).unfocus();
    
    // TODO: Send POST request to your backend here.
    // await http.post(Uri.parse('.../api/stylist/chat'), body: jsonEncode({'message': text}));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sending to AI: "$text"'),
        behavior: SnackBarBehavior.floating,
      )
    );
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
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 110,
            height: 130,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
              image: item.imageUrl.isNotEmpty 
                  ? DecorationImage(image: NetworkImage(item.imageUrl), fit: BoxFit.cover) 
                  : null,
            ),
            child: item.imageUrl.isEmpty 
                ? const Center(child: Icon(Icons.checkroom, size: 50, color: Colors.white54)) 
                : null,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(10), 
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]
            ),
            child: Text(item.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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