import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart'; // Add this import
import '../viewmodels/detection_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../data/models/detection_model.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Detection> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DetectionViewModel>().listenToPublicFeed();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context);
    final detectionVM = Provider.of<DetectionViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search diseases...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: (query) async {
            if (query.length > 2) {
              final results = await detectionVM.searchDetections(query);
              setState(() {
                _searchResults = results;
              });
            } else {
              setState(() {
                _searchResults = [];
              });
            }
          },
        )
            : const Text('Crop Disease Detector'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchResults = [];
                }
              });
            },
          ),
          if (authVM.isAuthenticated)
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {
                // FIXED: Use GoRouter navigation
                context.push('/profile');
              },
            ),
        ],
      ),
      body: _isSearching
          ? _buildSearchResults()
          : _buildFeed(detectionVM),

      floatingActionButton: authVM.isAuthenticated
          ? FloatingActionButton.extended(
        onPressed: () {
          // FIXED: Use GoRouter navigation
          context.push('/camera');
        },
        icon: const Icon(Icons.camera_alt),
        label: const Text('Scan'),
      )
          : null,
    );
  }

  Widget _buildFeed(DetectionViewModel detectionVM) {
    if (detectionVM.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (detectionVM.publicFeed.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.agriculture,
              size: 80,
              color: Colors.green[200],
            ),
            const SizedBox(height: 16),
            const Text(
              'No detections yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to scan and share!',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // FIXED: Use GoRouter navigation
                context.push('/camera');
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Scan Now'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: detectionVM.publicFeed.length,
      itemBuilder: (context, index) {
        final detection = detectionVM.publicFeed[index];
        return _buildDetectionCard(detection, detectionVM);
      },
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty && _searchController.text.length > 2) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No results found for "${_searchController.text}"',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final detection = _searchResults[index];
        return _buildDetectionCard(detection,
            Provider.of<DetectionViewModel>(context, listen: false));
      },
    );
  }

  Widget _buildDetectionCard(Detection detection, DetectionViewModel viewModel) {
    final authVM = Provider.of<AuthViewModel>(context, listen: false);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info header
          ListTile(
            leading: CircleAvatar(
              backgroundImage: detection.userPhotoURL != null
                  ? CachedNetworkImageProvider(detection.userPhotoURL!)
                  : null,
              child: detection.userPhotoURL == null
                  ? Text(detection.username[0].toUpperCase())
                  : null,
            ),
            title: Text(
              detection.username,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(detection.formattedDate),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                _showOptions(context, detection);
              },
            ),
          ),

          // Detection image
          GestureDetector(
            onTap: () {
              viewModel.selectDetection(detection);
              // FIXED: Use GoRouter navigation
              context.push('/detection-detail');
            },
            child: CachedNetworkImage(
              imageUrl: detection.imageURL,
              height: 300,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 300,
                color: Colors.grey[300],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                height: 300,
                color: Colors.grey[300],
                child: const Center(child: Icon(Icons.error)),
              ),
            ),
          ),

          // Detection info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getConfidenceColor(detection.confidence).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getConfidenceColor(detection.confidence),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.health_and_safety,
                            size: 16,
                            color: _getConfidenceColor(detection.confidence),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${(detection.confidence * 100).toStringAsFixed(1)}% Match',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _getConfidenceColor(detection.confidence),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (detection.tags.isNotEmpty)
                      ...detection.tags.take(2).map((tag) => Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      )),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  detection.diseaseName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (detection.notes != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    detection.notes!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Like button
                    IconButton(
                      icon: Icon(
                        detection.likedBy.contains(authVM.currentUser?.uid)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: detection.likedBy.contains(authVM.currentUser?.uid)
                            ? Colors.red
                            : null,
                      ),
                      onPressed: () {
                        viewModel.toggleLike(detection.id);
                      },
                    ),
                    Text('${detection.likes}'),

                    const SizedBox(width: 16),

                    // Comment button
                    IconButton(
                      icon: const Icon(Icons.comment_outlined),
                      onPressed: () {
                        viewModel.selectDetection(detection);
                        // FIXED: Use GoRouter navigation with parameter
                        context.push('/comments/${detection.id}');
                      },
                    ),
                    Text('${detection.comments}'),

                    const Spacer(),

                    // Share button
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () {
                        _shareDetection(detection);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context, Detection detection) {
    final authVM = Provider.of<AuthViewModel>(context, listen: false);

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                Provider.of<DetectionViewModel>(context, listen: false)
                    .selectDetection(detection);
                // FIXED: Use GoRouter navigation
                context.push('/detection-detail');
              },
            ),
            if (authVM.currentUser?.uid == detection.userId) ...[
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to edit (if you have an edit screen)
                  // context.push('/edit-detection/${detection.id}');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit feature coming soon')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context, detection);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.report, color: Colors.orange),
              title: const Text('Report'),
              onTap: () {
                Navigator.pop(context);
                _reportDetection(context, detection);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Detection detection) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Detection'),
        content: const Text('Are you sure you want to delete this detection?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final viewModel = Provider.of<DetectionViewModel>(context, listen: false);
      final success = await viewModel.deleteDetection(detection.id, detection.imageURL);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Detection deleted')),
        );
      }
    }
  }

  void _reportDetection(BuildContext context, Detection detection) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Detection'),
        content: const Text('Thank you for your report. Our team will review this content.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _shareDetection(Detection detection) {
    // Implement sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing feature coming soon')),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.5) return Colors.orange;
    return Colors.red;
  }
}