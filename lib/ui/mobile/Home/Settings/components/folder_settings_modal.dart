import 'dart:io' show Platform;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/services/logic/song_fetcher.dart';
import 'package:mg_music/services/ui/global_modal_service.dart';
import 'package:mg_music/services/ui/responsive_service.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mg_music/ui/tv/tv_focusable_item.dart';

class FolderSettingsContent extends StatefulWidget {
  final bool isTv;
  const FolderSettingsContent({Key? key, this.isTv = false}) : super(key: key);

  static Future<void> showModal(BuildContext context, {bool isTv = false}) {
    return GlobalModalService.show(
      title: 'Ubicación de Música',
      icon: Ionicons.folder_outline,
      content: FolderSettingsContent(isTv: isTv),
      actions: [],
    );
  }

  @override
  State<FolderSettingsContent> createState() => _FolderSettingsContentState();
}

class _FolderSettingsContentState extends State<FolderSettingsContent> {
  bool _scanAllDevice = true;
  List<String> _selectedFolders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _scanAllDevice = prefs.getBool('scan_all_device') ?? true;
      _selectedFolders = prefs.getStringList('music_scan_folders') ?? [];
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('scan_all_device', _scanAllDevice);
    await prefs.setStringList('music_scan_folders', _selectedFolders);

    SongFetcher.clearCache();
    SongFetcher.onLibraryChanged.value++;
  }

  Future<void> _addFolder() async {
    final folderPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Selecciona una carpeta de música',
    );
    if (folderPath != null && folderPath.isNotEmpty) {
      if (!_selectedFolders.contains(folderPath)) {
        setState(() {
          _selectedFolders.add(folderPath);
        });
        await _saveSettings();
      }
    }
  }

  Future<void> _removeFolder(String path) async {
    setState(() {
      _selectedFolders.remove(path);
    });
    await _saveSettings();
  }

  Widget _buildOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required AppThemeMode mode,
  }) {
    final Widget tileContent = Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.surface(mode),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isSelected ? AppColors.themeBorder(mode) : Colors.transparent,
          width: 2.w,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.accentBlue : AppColors.icon(mode),
            size: 24.r,
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary(mode),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary(mode),
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
          if (isSelected)
            Icon(Ionicons.checkmark_circle, color: AppColors.accentBlue),
        ],
      ),
    );

    if (widget.isTv) {
      return TvFocusableItem(
        onTap: onTap,
        borderRadius: 16.r,
        child: tileContent,
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: tileContent,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        height: 200.h,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final mode = context.watch<ThemeService>().mode;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildOptionTile(
          title: 'Escanear Todo',
          subtitle: 'Busca música automáticamente en todo el dispositivo.',
          icon: Ionicons.phone_portrait_outline,
          isSelected: _scanAllDevice,
          onTap: () {
            setState(() {
              _scanAllDevice = true;
            });
            _saveSettings();
          },
          mode: mode,
        ),
        _buildOptionTile(
          title: 'Carpetas Específicas',
          subtitle: 'Solo busca música en las carpetas que elijas.',
          icon: Ionicons.folder_open_outline,
          isSelected: !_scanAllDevice,
          onTap: () {
            setState(() {
              _scanAllDevice = false;
            });
            _saveSettings();
          },
          mode: mode,
        ),
        if (!_scanAllDevice) ...[
          SizedBox(height: 16.h),
          Text(
            'Tus Carpetas',
            style: TextStyle(
              color: AppColors.textPrimary(mode),
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 12.h),
          if (_selectedFolders.isEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: Text(
                'No has seleccionado ninguna carpeta. Por favor añade una.',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontSize: 12.sp,
                ),
              ),
            ),
          ..._selectedFolders.map(
            (folder) {
              final folderName = folder.split(Platform.pathSeparator).last;
              final isAdoFolder = folderName.toLowerCase() == 'ado' || 
                                folderName.toLowerCase() == 'mg ado';
              
              final Widget folderTile = Container(
                margin: EdgeInsets.only(bottom: 8.h),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: AppColors.surface(mode),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isAdoFolder ? AppColors.accentBlue : AppColors.themeBorder(mode).withOpacity(0.5),
                    width: isAdoFolder ? 2.w : 1.w,
                  ),
                ),
                child: Row(
                  children: [
                  Icon(Ionicons.folder, color: AppColors.textSecondary(mode), size: 18.r),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          folder.split(Platform.pathSeparator).last,
                          style: TextStyle(
                            color: AppColors.textPrimary(mode),
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          folder,
                          style: TextStyle(
                            color: AppColors.textSecondary(mode),
                            fontSize: 10.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (!widget.isTv)
                    IconButton(
                      icon: Icon(Ionicons.trash_outline, color: Colors.redAccent, size: 18.r),
                      onPressed: () => _removeFolder(folder),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            );

            if (widget.isTv) {
              return TvFocusableItem(
                onTap: () => _removeFolder(folder),
                onLongPress: () => _removeFolder(folder),
                borderRadius: 12.r,
                child: folderTile,
              );
            }

            return folderTile;
          }),
          const SizedBox(height: 8),
          _buildAddButton(),
        ],
      ],
    );
  }

  Widget _buildAddButton() {
    final Widget button = OutlinedButton.icon(
      onPressed: _addFolder,
      icon: Icon(Ionicons.add_circle_outline, color: AppColors.primaryBlueMid),
      label: Text(
        'Añadir Carpeta',
        style: TextStyle(color: AppColors.primaryBlueMid, fontWeight: FontWeight.bold, fontSize: 13.sp),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: AppColors.primaryBlueMid),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );

    if (widget.isTv) {
      return TvFocusableItem(
        onTap: _addFolder,
        borderRadius: 12.r,
        child: SizedBox(width: double.infinity, child: button),
      );
    }

    return button;
  }
}
