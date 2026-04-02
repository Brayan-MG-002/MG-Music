// Copyright © 2026 Brayan Medrano - MG Music
// Página dedicada a la configuración y gestión de copias de seguridad.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:mg_music/services/logic/backup_service.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:mg_music/services/ui/responsive_service.dart';
import 'package:mg_music/services/ui/custom_toast_service.dart';
import 'package:mg_music/services/ui/global_modal_service.dart';
import 'package:mg_music/ui/tv/tv_focusable_item.dart';
import 'package:provider/provider.dart';

class BackupSettingsPage extends StatefulWidget {
  const BackupSettingsPage({super.key});

  @override
  State<BackupSettingsPage> createState() => _BackupSettingsPageState();
}

class _BackupSettingsPageState extends State<BackupSettingsPage> {
  final BackupService _backupService = BackupService();
  
  bool _incSettings = true;
  bool _incFavorites = true;
  bool _incPlaylists = true;
  bool _incTheme = true;
  bool _incRoutes = true;
  bool _incAdo = true;
  
  String _backupPath = '';
  List<Map<String, dynamic>> _backups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    final path = await _backupService.getBackupDirectory();
    final list = await _backupService.listBackups();
    
    if (mounted) {
      setState(() {
        _incSettings = prefs.getBool('backup_cfg_settings') ?? true;
        _incFavorites = prefs.getBool('backup_cfg_favorites') ?? true;
        _incPlaylists = prefs.getBool('backup_cfg_playlists') ?? true;
        _incTheme = prefs.getBool('backup_cfg_theme') ?? true;
        _incRoutes = prefs.getBool('backup_cfg_routes') ?? true;
        _incAdo = prefs.getBool('backup_cfg_ado') ?? true;
        _backupPath = path;
        _backups = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveToggle(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _changeDirectory() async {
    String? result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      await _backupService.setBackupDirectory(result);
      setState(() => _backupPath = result);
      _refreshBackups();
      CustomToastService.show(context, message: 'Ubicación actualizada', type: ToastType.success);
    }
  }

  Future<void> _refreshBackups() async {
    final list = await _backupService.listBackups();
    if (mounted) setState(() => _backups = list);
  }

  Future<void> _createBackup() async {
    CustomToastService.show(context, message: 'Creando copia...', type: ToastType.info);
    final result = await _backupService.exportBackup();
    if (!mounted) return;
    
    if (result['success']) {
      CustomToastService.show(context, message: 'Copia creada exitosamente', type: ToastType.success);
      _refreshBackups();
    } else {
      CustomToastService.show(context, message: result['message'], type: ToastType.error);
    }
  }


  Future<void> _importFromExternal() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) return;

      final path = result.files.single.path!;
      final file = File(path);
      final stats = await file.stat();
      final metadata = await _backupService.getBackupDetails(path);

      final Map<String, dynamic> backupMap = {
        'path': path,
        'name': path.split('/').last.split('\\').last,
        'size': stats.size,
        'modified': stats.modified,
        'metadata': metadata,
      };

      if (mounted) {
        _showBackupDetails(backupMap);
      }
    } catch (e) {
      if (mounted) {
        CustomToastService.show(context, message: 'Error al leer archivo: $e', type: ToastType.error);
      }
    }
  }

  Future<void> _deleteBackup(Map<String, dynamic> backup) async {
    final confirmed = await GlobalModalService.showConfirmation(
      title: 'Eliminar Copia',
      message: '¿Estás seguro de que deseas borrar "${backup['name']}" permanentemente?',
      confirmText: 'Eliminar',
      confirmButtonColor: Colors.red,
      icon: Ionicons.trash_outline,
    );

    if (confirmed) {
      final success = await _backupService.deleteBackup(backup['path']);
      if (success) {
        CustomToastService.show(context, message: 'Copia eliminada', type: ToastType.success);
        _refreshBackups();
      }
    }
  }

  void _showBackupDetails(Map<String, dynamic> backup) {
    final metadata = backup['metadata'] as Map<String, dynamic>?;
    final date = backup['modified'] as DateTime;
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);
    final theme = Provider.of<ThemeService>(context, listen: false);
    final mode = theme.mode;
    
    GlobalModalService.show(
      title: 'Detalles de la Copia',
      icon: Ionicons.layers_outline,
      primaryColor: AppColors.primaryBlueMid,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Archivo:', backup['name'], mode),
          _buildDetailRow('Creado el:', formattedDate, mode),
          _buildDetailRow('Tamaño:', '${(backup['size'] / 1024).toStringAsFixed(2)} KB', mode),
          if (metadata != null) ...[
            const SizedBox(height: 16),
            Text(
              'CONTENIDO RESPALDADO:',
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 10.sp, 
                color: AppColors.primaryBlueMid,
                letterSpacing: 1.1,
              ),
            ),
            SizedBox(height: 6.h),
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                gradient: _itemGradient(mode),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.themeBorder(mode).withOpacity(0.3)),
              ),
              child: Text(
                metadata['summary'] ?? 'Sin resumen disponible',
                style: TextStyle(fontSize: 12.sp, color: AppColors.textPrimary(mode)),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Versión de App: ${metadata['app_version'] ?? 'N/A'}',
              style: TextStyle(
                fontSize: 11.sp,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary(mode),
              ),
            ),
          ],
          SizedBox(height: 20.h),
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: mode == AppThemeMode.light
                    ? Colors.orange.shade50
                    : Colors.orange.shade900.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Text(
                '¿Deseas restaurar esta copia de seguridad?\nEsta acción reemplazará tus preferencias actuales.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: mode == AppThemeMode.light
                      ? Colors.orange.shade900
                      : Colors.orange.shade300,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
      actions: [
        ModalActionButton(
          label: 'Cancelar',
          onPressed: () => Navigator.of(GlobalModalService.navigatorKey.currentContext!).pop(),
          color: Colors.grey.shade600,
        ),
        ModalActionButton(
          label: 'Restaurar',
          onPressed: () {
            Navigator.of(GlobalModalService.navigatorKey.currentContext!).pop();
            _restoreFromPath(backup['path']);
          },
          color: AppColors.primaryBlueMid,
        ),
      ],
    );
  }

  Future<void> _restoreFromPath(String path) async {
    final result = await _backupService.importFromFile(File(path));
    if (!mounted) return;

    if (result['success']) {
      final pr = result['playlistsRestored'];
      final fr = result['favoritesRestored'];
      
      CustomToastService.show(
        context, 
        message: 'Copia restaurada ($pr playlists, $fr favoritos)', 
        type: ToastType.success
      );
      
      final theme = Provider.of<ThemeService>(context, listen: false);
      theme.init();
    } else {
      CustomToastService.show(context, message: result['message'], type: ToastType.error);
    }
  }


  LinearGradient _itemGradient(AppThemeMode mode) {
    return LinearGradient(
      colors: [
        AppColors.primaryBlueMid.withOpacity(0.25),
        AppColors.background(mode).withOpacity(0.1),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeService>().mode;
    final isTv = MediaQuery.of(context).size.width > 900;

    return Container(
      color: Colors.transparent,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : AnimationLimiter(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  isTv ? 40.w : 20.w,
                  10.h,
                  isTv ? 40.w : 20.w,
                  40.h,
                ),
                children: AnimationConfiguration.toStaggeredList(
                  duration: const Duration(milliseconds: 500),
                  childAnimationBuilder: (widget) => SlideAnimation(
                    verticalOffset: 30.0.h,
                    child: FadeInAnimation(child: widget),
                  ),
                  children: [
                    SizedBox(height: 20.h),

                    _buildBackupActions(mode, isTv),
                    
                    SizedBox(height: 32.h),
                    

                    _buildSectionHeader('Copias en este dispositivo', mode),
                    ..._buildBackupsList(mode, isTv),
                    
                    SizedBox(height: 32.h),
                    

                    _buildSectionHeader('¿Qué respaldar?', mode),
                    _buildSelectionToggles(mode, isTv),
                    
                    SizedBox(height: 24.h),
                    _buildSectionHeader('Carpeta de Guardado', mode),
                    _buildLocationPicker(mode, isTv),
                    
                    SizedBox(height: 200.h),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, AppThemeMode mode) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h, left: 4.w),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: AppColors.primaryBlueMid,
          fontWeight: FontWeight.bold,
          fontSize: 11.sp,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildBackupActions(AppThemeMode mode, bool isTv) {
    return Column(
      children: [

        _buildPremiumGradientButton(
          label: 'Crear Nueva Copia', 
          icon: Ionicons.save_outline, 
          onTap: _createBackup, 
          mode: mode,
          isTv: isTv,
        ),
        const SizedBox(height: 12),

        Material(
          color: Colors.transparent,
          child: TvFocusableItem(
            onTap: _importFromExternal,
            borderRadius: 15.r,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Ionicons.cloud_download_outline,
                    color: AppColors.textSecondary(mode),
                    size: 18.r,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Restaurar desde archivo externo .json',
                    style: TextStyle(
                      color: AppColors.textSecondary(mode),
                      fontSize: 13.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionToggles(AppThemeMode mode, bool isTv) {
    return Container(
      decoration: BoxDecoration(
        gradient: _itemGradient(mode),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.themeBorder(mode).withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.themeBorder(mode).withOpacity(0.1),
            blurRadius: 10.r,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildToggleTile(Ionicons.settings_outline, 'Ajustes', _incSettings, (v) {
            setState(() => _incSettings = v);
            _saveToggle('backup_cfg_settings', v);
          }, mode, isTv: isTv, isFirst: true),
          _buildToggleTile(Ionicons.folder_open_outline, 'Rutas', _incRoutes, (v) {
            setState(() => _incRoutes = v);
            _saveToggle('backup_cfg_routes', v);
          }, mode, isTv: isTv),
          _buildToggleTile(Ionicons.heart_outline, 'Favoritos', _incFavorites, (v) {
            setState(() => _incFavorites = v);
            _saveToggle('backup_cfg_favorites', v);
          }, mode, isTv: isTv),
          _buildToggleTile(Ionicons.list_outline, 'Playlists', _incPlaylists, (v) {
            setState(() => _incPlaylists = v);
            _saveToggle('backup_cfg_playlists', v);
          }, mode, isTv: isTv),
          _buildToggleTile(Ionicons.color_palette_outline, 'Tema', _incTheme, (v) {
            setState(() => _incTheme = v);
            _saveToggle('backup_cfg_theme', v);
          }, mode, isTv: isTv),
          _buildToggleTile(Ionicons.sparkles_outline, 'Experiencia Temática', _incAdo, (v) {
            setState(() => _incAdo = v);
            _saveToggle('backup_cfg_ado', v);
          }, mode, isTv: isTv, isLast: true),
        ],
      ),
    );
  }

  Widget _buildToggleTile(
    IconData icon,
    String title,
    bool value,
    ValueChanged<bool> onChanged,
    AppThemeMode mode, {
    bool isFirst = false,
    bool isLast = false,
    bool isTv = false,
  }) {
    if (isTv) {
      return TvFocusableItem(
        onTap: () => onChanged(!value),
        borderRadius: isFirst
            ? 20.r
            : isLast
                ? 20.r
                : 0,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            border: Border(
              bottom: isLast
                  ? BorderSide.none
                  : BorderSide(color: AppColors.themeBorder(mode).withOpacity(0.2)),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primaryBlueMid, size: 20),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary(mode),
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.primaryBlueLight,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : BorderSide(color: AppColors.themeBorder(mode).withOpacity(0.2)),
        ),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: AppColors.primaryBlueMid, size: 20),
        title: Text(
          title,
          style: TextStyle(
            color: AppColors.textPrimary(mode),
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        activeColor: AppColors.primaryBlueLight,
        value: value,
        onChanged: onChanged,
        dense: true,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildLocationPicker(AppThemeMode mode, bool isTv) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: _itemGradient(mode),
        border: Border.all(color: AppColors.themeBorder(mode).withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.themeBorder(mode).withOpacity(0.1),
            blurRadius: 10.r,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Ionicons.folder_outline, color: AppColors.textSecondary(mode), size: 20.r),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  _backupPath,
                  style: TextStyle(
                    color: AppColors.textSecondary(mode),
                    fontSize: 12.sp,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          _buildPremiumGradientButton(
            label: 'Cambiar Ubicación', 
            icon: Ionicons.create_outline, 
            onTap: _changeDirectory, 
            mode: mode,
            isCompact: true,
            isTv: isTv,
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumGradientButton({
    required String label, 
    required IconData icon, 
    required VoidCallback onTap, 
    required AppThemeMode mode,
    bool isCompact = false,
    bool isTv = false,
  }) {
    final textColor = AppColors.textPrimary(mode);
    
    Widget content = Container(
        height: isCompact ? 50.h : 60.h,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isCompact ? 15.r : 20.r),
          gradient: AppGradients.of(mode, GradientDirection.topLeftBottomRight),
          border: Border.all(color: AppColors.primaryBlueMid.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlueMid.withOpacity(0.2),
              blurRadius: 10.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor, size: isCompact ? 18.r : 22.r),
              SizedBox(width: 10.w),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: isCompact ? 14.sp : 16.sp,
                ),
              ),
            ],
          ),
        ),
      );

    if (isTv) {
      return TvFocusableItem(
        onTap: onTap,
        borderRadius: isCompact ? 15.r : 20.r,
        child: content,
      );
    }

    return GestureDetector(onTap: onTap, child: content);
  }

  List<Widget> _buildBackupsList(AppThemeMode mode, bool isTv) {
    if (_backups.isEmpty) {
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                Icon(Ionicons.albums_outline, size: 48, color: AppColors.textSecondary(mode).withOpacity(0.2)),
                const SizedBox(height: 12),
                Text(
                  'No se encontraron copias de seguridad',
                  style: TextStyle(color: AppColors.textSecondary(mode), fontSize: 12.sp),
                ),
              ],
            ),
          ),
        )
      ];
    }

    return _backups.map((backup) {
      final date = backup['modified'] as DateTime;
      final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(date);
      final size = (backup['size'] / 1024).toStringAsFixed(1);
      final bool hasMetadata = backup['metadata'] != null;

      final item = Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18.r),
          gradient: _itemGradient(mode),
          border: Border.all(
            color: AppColors.primaryBlueMid.withOpacity(0.2),
            width: 1.5.w,
          ),
        ),
        child: ListTile(
          onTap: isTv ? null : () => _showBackupDetails(backup),
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          leading: Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: AppColors.background(mode).withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Ionicons.document_text_outline,
              color: hasMetadata ? AppColors.primaryBlueMid : Colors.grey,
              size: 20.r,
            ),
          ),
          title: Text(
            formattedDate,
            style: TextStyle(
              color: AppColors.textPrimary(mode),
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
            ),
          ),
          subtitle: Text(
            '${size} KB • ${hasMetadata ? backup['metadata']['summary'] : 'Copia legacy'}',
            style: TextStyle(
              color: AppColors.textSecondary(mode),
              fontSize: 11.sp,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            icon: Icon(Ionicons.trash_outline, color: Colors.red, size: 20.r),
            onPressed: () => _deleteBackup(backup),
          ),
        ),
      );

      if (isTv) {
        return TvFocusableItem(
          onTap: () => _showBackupDetails(backup),
          borderRadius: 18.r,
          child: item,
        );
      }

      return item;
    }).toList();
  }

  Widget _buildDetailRow(String label, String value, AppThemeMode mode) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 85.w,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 13.sp, 
                color: AppColors.textSecondary(mode),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.sp, 
                color: AppColors.textPrimary(mode),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
