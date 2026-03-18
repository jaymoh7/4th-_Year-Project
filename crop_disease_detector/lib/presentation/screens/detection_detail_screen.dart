import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/detection_viewmodel.dart';
import '../../data/models/detection_model.dart';
import 'package:go_router/go_router.dart';

class DetectionDetailScreen extends StatelessWidget {
  const DetectionDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DetectionViewModel>(context);
    final detection = viewModel.selectedDetection;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detection Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: detection != null
                ? () => _shareDetection(context, detection)
                : null,
          ),
          if (detection != null && detection.userId == viewModel.currentUserId)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteDetection(context, viewModel, detection),
            ),
        ],
      ),
      body: detection == null
          ? _buildLoadingView()
          : _buildDetailView(context, detection, viewModel),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading detection details...'),
        ],
      ),
    );
  }

  Widget _buildDetailView(BuildContext context, Detection detection, DetectionViewModel viewModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  detection.imageURL,
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 300,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.image_not_supported, size: 50),
                      ),
                    );
                  },
                ),
              ),
              // Public/Private indicator
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: detection.isPublic ? Colors.blue : Colors.grey,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        detection.isPublic ? Icons.public : Icons.lock,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        detection.isPublic ? 'Public' : 'Private',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // User Info Row
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: detection.userPhotoURL != null
                    ? NetworkImage(detection.userPhotoURL!)
                    : null,
                child: detection.userPhotoURL == null
                    ? Text(detection.username[0].toUpperCase())
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detection.username,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      detection.formattedDate,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Disease Name
          Text(
            detection.diseaseName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          // Confidence Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getConfidenceColor(detection.confidence).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Confidence: ${(detection.confidence * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                color: _getConfidenceColor(detection.confidence),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Disease Details from diseaseDetails map
          if (detection.diseaseDetails != null) ...[
            _buildDetailSection(
              context,
              'Description',
              detection.diseaseDetails!['description']?.toString() ?? 'No description available',
            ),
            const SizedBox(height: 16),
            _buildDetailSection(
              context,
              'Symptoms',
              detection.diseaseDetails!['symptoms']?.toString() ?? 'No symptoms information',
            ),
            const SizedBox(height: 16),
            _buildDetailSection(
              context,
              'Treatment',
              detection.diseaseDetails!['treatment']?.toString() ?? 'No treatment information',
            ),
            const SizedBox(height: 16),
            _buildDetailSection(
              context,
              'Prevention',
              detection.diseaseDetails!['prevention']?.toString() ?? 'No prevention information',
            ),
          ],

          // User Notes
          if (detection.notes != null && detection.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildDetailSection(
              context,
              'Your Notes',
              detection.notes!,
            ),
          ],

          const SizedBox(height: 16),

          // Tags
          if (detection.tags.isNotEmpty) ...[
            Text(
              'Tags',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: detection.tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(color: Colors.blue),
                ),
              )).toList(),
            ),
          ],

          const SizedBox(height: 24),

          // Metadata
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Additional Information',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Detection ID', detection.id),
                _buildInfoRow('Date', _formatDate(detection.timestamp)),

                // Location Info
                if (detection.location != null) ...[
                  const Divider(height: 24),
                  Text(
                    'Location',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (detection.location!.address != null)
                    _buildInfoRow('Address', detection.location!.address!),
                  if (detection.location!.city != null)
                    _buildInfoRow('City', detection.location!.city!),
                  if (detection.location!.country != null)
                    _buildInfoRow('Country', detection.location!.country!),
                  _buildInfoRow(
                    'Coordinates',
                    '${detection.location!.latitude.toStringAsFixed(4)}, '
                        '${detection.location!.longitude.toStringAsFixed(4)}',
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Like and Comment buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => viewModel.toggleLike(detection.id),
                  icon: Icon(
                    detection.likedBy.contains(viewModel.currentUserId)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: detection.likedBy.contains(viewModel.currentUserId)
                        ? Colors.red
                        : null,
                  ),
                  label: Text('${detection.likes} ${detection.likes == 1 ? 'Like' : 'Likes'}'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _navigateToComments(context, detection.id),
                  icon: const Icon(Icons.comment),
                  label: Text('${detection.comments} Comments'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(BuildContext context, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: const TextStyle(height: 1.5),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.5) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime timestamp) {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} '
        '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}';
  }

  void _shareDetection(BuildContext context, Detection detection) {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon')),
    );
  }

  void _deleteDetection(BuildContext context, DetectionViewModel viewModel, Detection detection) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Detection'),
        content: const Text('Are you sure you want to delete this detection?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await viewModel.deleteDetection(detection.id, detection.imageURL);
      if (success && context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Detection deleted successfully')),
        );
      }
    }
  }

  void _navigateToComments(BuildContext context, String detectionId) {
    context.pushNamed('comments', pathParameters: {'detectionId': detectionId});
  }
}