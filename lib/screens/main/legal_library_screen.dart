// lib/screens/legal/legal_library_screen.dart

import 'package:flutter/material.dart';
import 'package:legal_ai/core/constants.dart';
import 'package:legal_ai/core/models/legal_resource.dart';
import 'package:legal_ai/core/services/legal_library_service.dart';
import 'package:legal_ai/core/services/chat_service.dart';
import 'package:legal_ai/screens/legal/template_editor_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class LegalLibraryScreen extends StatefulWidget {
  const LegalLibraryScreen({Key? key}) : super(key: key);

  @override
  State<LegalLibraryScreen> createState() => _LegalLibraryScreenState();
}

class _LegalLibraryScreenState extends State<LegalLibraryScreen> {
  final LegalLibraryService _service = LegalLibraryService();
  final ChatService _chatService = ChatService();

  List<LegalResource> _allResources = [];
  List<LegalResource> _filteredResources = [];
  String _searchQuery = '';
  String _selectedType = 'All';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadResources() async {
    setState(() => _isLoading = true);

    try {
      _allResources = _service.getResources();
      _filteredResources = _allResources;
    } catch (e) {
      print('Error loading resources: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading resources: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterResources() {
    setState(() {
      _filteredResources = _allResources.where((resource) {
        final matchesSearch =
            resource.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                resource.description.toLowerCase().contains(_searchQuery.toLowerCase());

        final matchesType =
            _selectedType == 'All' || resource.type == _selectedType;

        return matchesSearch && matchesType;
      }).toList();
    });
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'Template':
        return Icons.file_copy;
      case 'Definition':
        return Icons.info_outline;
      case 'Guide':
        return Icons.menu_book;
      default:
        return Icons.help_outline;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'Template':
        return Colors.blue;
      case 'Definition':
        return Colors.orange;
      case 'Guide':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _launchURL(String? url) async {
    if (url == null) return;

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch URL';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open resource: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openResource(LegalResource resource) async {
    if (resource.isDynamicTemplate && resource.templateKey != null) {
      // Open template editor for AI-assisted document generation
      await _openTemplateEditor(resource);
    } else if (resource.type == 'Definition') {
      // Show definition in dialog
      _showDefinitionDialog(resource);
    } else if (resource.content != null) {
      // Open static content viewer
      await _openContentViewer(resource);
    } else {
      // Open external URL
      _launchURL(resource.url);
    }
  }

  Future<void> _openTemplateEditor(LegalResource resource) async {
    if (resource.templateKey == null) return;

    // Get the template content
    final templateContent = _service.getTemplateByKey(resource.templateKey!);

    if (templateContent == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Template not found'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Navigate to template editor
    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TemplateEditorScreen(
            templateKey: resource.templateKey!,
            title: resource.title,
            description: resource.description,
            templateContent: templateContent,
            chatService: _chatService,
          ),
        ),
      );
    }
  }

  void _showDefinitionDialog(LegalResource resource) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: _getColorForType(resource.type),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                resource.title,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            resource.description,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _openContentViewer(LegalResource resource) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(resource.title),
        content: SingleChildScrollView(
          child: Text(resource.content ?? 'No content available'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: InputDecoration(
              labelText: 'Search Library',
              hintText: 'Search templates, guides, definitions...',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: kDarkCardColor,
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
              _filterResources();
            },
          ),
        ),

        // Filter dropdown
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Filter by Type',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: kDarkCardColor,
              prefixIcon: const Icon(Icons.filter_list),
            ),
            value: _selectedType,
            items: <String>['All', 'Template', 'Definition', 'Guide']
                .map((value) => DropdownMenuItem(
              value: value,
              child: Text(value),
            ))
                .toList(),
            onChanged: (String? newValue) {
              setState(() => _selectedType = newValue!);
              _filterResources();
            },
          ),
        ),

        const SizedBox(height: 8),

        // Results count
        if (_searchQuery.isNotEmpty || _selectedType != 'All')
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${_filteredResources.length} result${_filteredResources.length != 1 ? 's' : ''} found',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                if (_searchQuery.isNotEmpty || _selectedType != 'All')
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _selectedType = 'All';
                      });
                      _filterResources();
                    },
                    child: const Text('Clear filters'),
                  ),
              ],
            ),
          ),

        // Resources list
        Expanded(
          child: _filteredResources.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 16),
                Text(
                  'No resources found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try adjusting your search or filters',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          )
              : RefreshIndicator(
            onRefresh: _loadResources,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _filteredResources.length,
              padding: const EdgeInsets.only(bottom: 16),
              itemBuilder: (context, index) {
                final resource = _filteredResources[index];

                return Card(
                  color: kDarkCardColor,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getColorForType(resource.type).withOpacity(0.2),
                      child: Icon(
                        _getIconForType(resource.type),
                        color: _getColorForType(resource.type),
                      ),
                    ),
                    title: Text(
                      resource.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          resource.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getColorForType(resource.type).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            resource.type,
                            style: TextStyle(
                              fontSize: 12,
                              color: _getColorForType(resource.type),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: _buildTrailingIcon(resource),
                    onTap: () => _openResource(resource),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrailingIcon(LegalResource resource) {
    if (resource.type == "Template") {
      return Icon(
        Icons.arrow_forward_ios,
        color: kPrimaryColor,
        size: 20,
      );
    } else if (resource.url != null && !resource.isDynamicTemplate) {
      return IconButton(
        icon: const Icon(Icons.open_in_new),
        color: kPrimaryColor,
        onPressed: () => _launchURL(resource.url),
        tooltip: 'Open in browser',
      );
    }
    return const SizedBox.shrink();
  }
}