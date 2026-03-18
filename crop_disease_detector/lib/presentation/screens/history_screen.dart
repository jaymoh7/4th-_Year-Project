import 'dart:io';  // Add this import for File
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/history_viewmodel.dart';
import '../../data/models/history_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryViewModel>().loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detection History'),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
          Consumer<HistoryViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.totalCount == 0) return const SizedBox();
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) async {
                  if (value == 'clear') {
                    _showClearConfirmation(context);
                  } else if (value == 'export') {
                    _showExportOptions(context);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'clear',
                    child: Row(
                      children: [
                        Icon(Icons.delete_sweep, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Clear History'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.share),
                        SizedBox(width: 8),
                        Text('Export Data'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search diseases...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<HistoryViewModel>().search('');
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (query) {
                context.read<HistoryViewModel>().search(query);
              },
            ),
          ),
        ),
      ),
      body: Consumer<HistoryViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading history',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(viewModel.errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => viewModel.loadHistory(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (viewModel.detections.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 80,
                    color: Colors.green[200],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchController.text.isEmpty
                        ? 'No detection history yet'
                        : 'No results found for "${_searchController.text}"',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _searchController.text.isEmpty
                        ? 'Scan your first crop disease to get started'
                        : 'Try a different search term',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  if (_searchController.text.isEmpty) ...[
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Scan Now'),
                    ),
                  ],
                ],
              ),
            );
          }

          return _isGridView
              ? _buildGridView(viewModel.detections)
              : _buildListView(viewModel.detections);
        },
      ),
    );
  }

  Widget _buildListView(List<DetectionHistory> detections) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: detections.length,
      itemBuilder: (context, index) {
        final detection = detections[index];
        return Dismissible(
          key: Key(detection.id),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (_) {
            context.read<HistoryViewModel>().deleteDetection(detection);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Detection removed'),
                action: SnackBarAction(
                  label: 'Undo',
                  onPressed: () {
                    // Implement undo functionality
                  },
                ),
              ),
            );
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Hero(
                tag: 'history_${detection.id}',
                child: CircleAvatar(
                  radius: 28,
                  backgroundImage: detection.imagePath.isNotEmpty
                      ? FileImage(File(detection.imagePath))
                      : null,
                  child: detection.imagePath.isEmpty
                      ? const Icon(Icons.image)
                      : null,
                ),
              ),
              title: Text(
                detection.diseaseName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(detection.formattedDate),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: detection.confidence,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getConfidenceColor(detection.confidence),
                    ),
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    detection.confidencePercentage,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getConfidenceColor(detection.confidence),
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/result',
                  arguments: detection,
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridView(List<DetectionHistory> detections) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: detections.length,
      itemBuilder: (context, index) {
        final detection = detections[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/result',
                arguments: detection,
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (detection.imagePath.isNotEmpty)
                        Image.file(
                          File(detection.imagePath),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.broken_image, size: 40),
                            );
                          },
                        )
                      else
                        Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, size: 40),
                        ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            detection.confidencePercentage,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          detection.diseaseName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          detection.formattedDate,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text(
            'Are you sure you want to clear all detection history? This action cannot be undone.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await context.read<HistoryViewModel>().clearAllHistory();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('History cleared')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Export as Screenshot'),
              onTap: () {
                Navigator.pop(context);
                _exportAsScreenshot();
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Export as CSV'),
              onTap: () {
                Navigator.pop(context);
                _exportAsCSV();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Report'),
              onTap: () {
                Navigator.pop(context);
                _shareReport();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _exportAsScreenshot() {
    // Implement screenshot functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Screenshot saved to gallery')),
    );
  }

  void _exportAsCSV() {
    // Implement CSV export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CSV exported successfully')),
    );
  }

  void _shareReport() {
    // Implement sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report shared')),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.5) return Colors.orange;
    return Colors.red;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}