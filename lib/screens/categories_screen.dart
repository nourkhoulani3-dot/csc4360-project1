import 'package:flutter/material.dart';

import '../database/database_helper.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<Map<String, Object?>> _categories = [];
  bool _loading = true;
  String? _error;

  static const _colors = [
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.orange,
    Colors.red,
    Colors.teal,
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await DatabaseHelper.instance.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = rows;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load categories.';
      });
    }
  }

  Future<void> _edit([Map<String, Object?>? category]) async {
    var name = category?['name']?.toString() ?? '';
    var color = category?['color'] as int? ?? Colors.green.toARGB32();
    String? error;
    var saving = false;

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, updateDialog) {
            return PopScope(
              canPop: !saving,
              child: AlertDialog(
                title: Text(
                  category == null ? 'Add category' : 'Edit category',
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        initialValue: name,
                        enabled: !saving,
                        autofocus: true,
                        maxLength: 40,
                        decoration: const InputDecoration(
                          labelText: 'Category name',
                          hintText: 'For example: Exercise',
                        ),
                        onChanged: (value) => name = value,
                      ),
                      const SizedBox(height: 16),
                      const Text('Choose a color'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _colors.map((option) {
                          final selected = color == option.toARGB32();

                          return Semantics(
                            label: 'Color ${_colors.indexOf(option) + 1}',
                            selected: selected,
                            child: IconButton(
                              tooltip: 'Choose color',
                              style: IconButton.styleFrom(
                                backgroundColor: option,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: saving
                                  ? null
                                  : () => updateDialog(() {
                                      color = option.toARGB32();
                                    }),
                              icon: Icon(
                                selected ? Icons.check : Icons.circle_outlined,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: saving
                        ? null
                        : () => Navigator.pop(dialogContext, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: saving
                        ? null
                        : () async {
                            final cleaned = name.trim();

                            if (cleaned.isEmpty) {
                              updateDialog(() {
                                error = 'Enter a category name.';
                              });
                              return;
                            }

                            final duplicate = _categories.any((row) {
                              return row['id'] != category?['id'] &&
                                  row['name'].toString().toLowerCase() ==
                                      cleaned.toLowerCase();
                            });

                            if (duplicate ||
                                cleaned.toLowerCase() == 'uncategorized') {
                              updateDialog(() {
                                error = 'Please choose a different name.';
                              });
                              return;
                            }

                            updateDialog(() {
                              saving = true;
                              error = null;
                            });

                            try {
                              final db = DatabaseHelper.instance;
                              if (category == null) {
                                await db.addCategory(cleaned, color);
                              } else {
                                final count = await db.updateCategory(
                                  category['id'] as int,
                                  cleaned,
                                  color,
                                );
                                if (count == 0) {
                                  throw StateError('Category not found');
                                }
                              }

                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext, true);
                              }
                            } catch (_) {
                              if (!dialogContext.mounted) return;
                              updateDialog(() {
                                saving = false;
                                error = 'Could not save. Please try again.';
                              });
                            }
                          },
                    child: Text(saving ? 'Saving...' : 'Save'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (saved == true && mounted) {
      await _load();
    }
  }

  Future<void> _delete(Map<String, Object?> category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text(
          'Delete "${category['name']}"? Its activities will stay '
          'in history under Uncategorized.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await DatabaseHelper.instance.deleteCategory(category['id'] as int);
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add),
        label: const Text('Add category'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: TextButton(
                onPressed: _load,
                child: Text('$_error Tap to retry.'),
              ),
            )
          : _categories.isEmpty
          ? const Center(child: Text('No categories yet. Tap Add category.'))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(category['color'] as int),
                    child: const Icon(Icons.label_outline, color: Colors.white),
                  ),
                  title: Text(category['name'].toString()),
                  onTap: () => _edit(category),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Edit category',
                        onPressed: () => _edit(category),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Delete category',
                        onPressed: () => _delete(category),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
