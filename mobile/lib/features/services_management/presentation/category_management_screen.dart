import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/clearable_text_field.dart';
import '../data/service_mgmt_repository.dart';
import '../providers/service_mgmt_provider.dart';

class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  ConsumerState<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState
    extends ConsumerState<CategoryManagementScreen> {
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(serviceMgmtRepositoryProvider);
      final cats = await repo.listCategories();
      if (mounted) setState(() { _categories = cats; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showAddSheet() {
    final controller = TextEditingController();
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(top: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.neutral300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.accentSoft,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Icon(Icons.category_rounded,
                            color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Nova categoria', style: AppTypography.title),
                    ],
                  ),
                ),
                const Divider(color: AppColors.neutral200, height: 1),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: ClearableTextField(
                    controller: controller,
                    labelText: 'Nome da categoria',
                    autofocus: true,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        final name = controller.text.trim();
                        if (name.isEmpty) return;
                        HapticFeedback.mediumImpact();
                        Navigator.pop(ctx);
                        await _createCategory(name);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        textStyle: AppTypography.bodySemibold,
                      ),
                      child: const Text('Criar categoria'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) => controller.dispose());
  }

  Future<void> _createCategory(String name) async {
    try {
      final repo = ref.read(serviceMgmtRepositoryProvider);
      await repo.createCategory(name);
      ref.read(serviceMgmtProvider.notifier).refresh();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Categoria criada'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  void _showEditSheet(Map<String, dynamic> category) {
    final controller = TextEditingController(text: category['name'] as String);
    final id = category['id'] as String;
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(top: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.neutral300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.accentSoft,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Icon(Icons.edit_rounded,
                            color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Editar categoria', style: AppTypography.title),
                    ],
                  ),
                ),
                const Divider(color: AppColors.neutral200, height: 1),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: ClearableTextField(
                    controller: controller,
                    labelText: 'Nome da categoria',
                    autofocus: true,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _deleteCategory(id, category['name'] as String);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                              ),
                            ),
                            child: const Text('Excluir'),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () async {
                              final name = controller.text.trim();
                              if (name.isEmpty) return;
                              HapticFeedback.mediumImpact();
                              Navigator.pop(ctx);
                              await _updateCategory(id, name);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                              ),
                              textStyle: AppTypography.bodySemibold,
                            ),
                            child: const Text('Salvar'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) => controller.dispose());
  }

  Future<void> _updateCategory(String id, String name) async {
    try {
      final repo = ref.read(serviceMgmtRepositoryProvider);
      await repo.updateCategory(id, {'name': name});
      ref.read(serviceMgmtProvider.notifier).refresh();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  Future<void> _deleteCategory(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Text('Excluir categoria?', style: AppTypography.title),
        content: Text(
          'Excluir "$name"? Categorias com serviços vinculados não podem ser excluídas.',
          style: AppTypography.body.copyWith(color: AppColors.neutral600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Voltar',
                style:
                    AppTypography.body.copyWith(color: AppColors.neutral600)),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.heavyImpact();
              Navigator.pop(ctx, true);
            },
            child: Text('Excluir',
                style: AppTypography.body.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final repo = ref.read(serviceMgmtRepositoryProvider);
      await repo.deleteCategory(id);
      ref.read(serviceMgmtProvider.notifier).refresh();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Categoria excluída'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorias'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddSheet,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.category_outlined,
                          size: 48, color: AppColors.neutral300),
                      const SizedBox(height: AppSpacing.md),
                      Text('Nenhuma categoria',
                          style: AppTypography.body
                              .copyWith(color: AppColors.neutral400)),
                      const SizedBox(height: AppSpacing.sm),
                      Text('Adicione categorias para organizar seus serviços',
                          style: AppTypography.caption
                              .copyWith(color: AppColors.neutral400)),
                      const SizedBox(height: AppSpacing.lg),
                      ElevatedButton(
                        onPressed: _showAddSheet,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        child: const Text('Criar categoria'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    itemCount: _categories.length,
                    itemBuilder: (_, i) {
                      final cat = _categories[i];
                      return GestureDetector(
                        onTap: () => _showEditSheet(cat),
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.neutral100,
                            border: Border.all(color: AppColors.neutral200),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: AppColors.accentSoft,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.sm),
                                ),
                                child: const Icon(Icons.category_rounded,
                                    color: AppColors.primary, size: 18),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  cat['name'] as String,
                                  style: AppTypography.bodySemibold,
                                ),
                              ),
                              const Icon(Icons.chevron_right,
                                  color: AppColors.neutral300),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
