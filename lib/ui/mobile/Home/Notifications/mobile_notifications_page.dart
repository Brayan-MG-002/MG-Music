import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:mg_music/services/ui/responsive_service.dart';
import 'package:mg_music/services/logic/notification_service.dart';
import 'package:intl/intl.dart';
import 'package:mg_music/services/logic/update_service.dart';
import 'package:mg_music/main.dart' as main_app;

class MobileNotificationsPage extends StatelessWidget {
  const MobileNotificationsPage({super.key});

  Future<void> _onRefresh(BuildContext context) async {
    final hasInternet = await UpdateService.hasInternetConnection();
    if (!hasInternet) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Comprueba tu conexión a internet'),
            backgroundColor: Colors.red.shade900,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    await context.read<NotificationService>().checkForRemoteNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeService>().mode;
    final notificationService = context.watch<NotificationService>();
    final notifications = notificationService.notifications;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () => _onRefresh(context),
        color: AppColors.primaryBlueMid,
        backgroundColor: AppColors.surface(mode),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeader(context, mode, notificationService),
            ),
            if (notifications.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(mode),
              )
            else
              ..._buildNotificationSlivers(
                context,
                mode,
                notifications,
                notificationService,
              ),
            SliverToBoxAdapter(child: SizedBox(height: 120.h)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppThemeMode mode,
    NotificationService service,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 10.h),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Text(
              'Notificaciones',
              style: TextStyle(
                color: AppColors.textPrimary(mode),
                fontSize: 22.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),
          if (service.notifications.any((n) => !n.isRead))
            Positioned(
              right: 0,
              child: IconButton(
                icon: Icon(
                  Ionicons.checkmark_done_outline,
                  color: AppColors.primaryBlueLight,
                  size: 24.r,
                ),
                onPressed: () => service.markAllAsRead(),
                tooltip: 'Marcar todos como leídos',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppThemeMode mode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Ionicons.notifications_off_outline,
            size: 80.r,
            color: AppColors.textSecondary(mode).withOpacity(0.3),
          ),
          SizedBox(height: 20.h),
          Text(
            'No hay notificaciones nuevas',
            style: TextStyle(
              color: AppColors.textSecondary(mode).withOpacity(0.5),
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildNotificationSlivers(
    BuildContext context,
    AppThemeMode mode,
    List<NotificationItem> notifications,
    NotificationService service,
  ) {
    final unread = notifications.where((n) => !n.isRead).toList();
    final read = notifications.where((n) => n.isRead).toList();

    return [
      if (unread.isNotEmpty) ...[
        _buildSectionHeader('Nuevas', mode),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _NotificationCard(
                item: unread[index],
                service: service,
                mode: mode,
              ),
              childCount: unread.length,
            ),
          ),
        ),
      ],
      if (read.isNotEmpty) ...[
        _buildSectionHeader('Anteriores', mode),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _NotificationCard(
                item: read[index],
                service: service,
                mode: mode,
              ),
              childCount: read.length,
            ),
          ),
        ),
      ],
    ];
  }

  Widget _buildSectionHeader(String title, AppThemeMode mode) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 12.h),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                color: AppColors.primaryBlueMid,
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Divider(
                color: AppColors.primaryBlueMid.withOpacity(0.2),
                thickness: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class _NotificationCard extends StatefulWidget {
  final NotificationItem item;
  final NotificationService service;
  final AppThemeMode mode;

  const _NotificationCard({
    required this.item,
    required this.service,
    required this.mode,
  });

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  NotificationItem get item => widget.item;
  AppThemeMode get mode => widget.mode;


  Color get _accentColor {
    if (mode == AppThemeMode.dark) {
      return item.type == NotificationType.beta
          ? Colors.orange.shade700
          : AppColors.primaryBlueMid;
    } else {
      return item.type == NotificationType.beta
          ? Colors.orange.shade600
          : AppColors.primaryBlueLight;
    }
  }


  Color get _borderColor => AppColors.themeBorder(mode);


  List<Color> get _headerGradient => item.isRead
      ? [AppColors.surface(mode), AppColors.surface(mode)]
      : AppColors.songItemGradient(mode);

  IconData get _typeIcon {
    switch (item.type) {
      case NotificationType.beta:
        return Ionicons.flask_outline;
      case NotificationType.notice:
        return Ionicons.megaphone_outline;
      case NotificationType.version:
        return Ionicons.rocket_outline;
    }
  }

  String get _typeLabel {
    switch (item.type) {
      case NotificationType.beta:
        return 'Beta';
      case NotificationType.notice:
        final rawType = item.data?['noti_type'] as String? ?? 'info';
        if (rawType == 'update') return 'Actualización';
        if (rawType == 'promo') return 'Promo';
        return 'Info';
      case NotificationType.version:
        return 'Versión';
    }
  }

  Widget _buildRichMessage(
    String message,
    Map<String, dynamic>? data,
    AppThemeMode mode,
  ) {

    final regExp = RegExp(r'\[\[ACTION:([^|\]]+)\|([^\]]+)\]\]');
    final matches = regExp.allMatches(message).toList();

    if (matches.isEmpty) {
      return Text(
        message,
        style: TextStyle(
          color: AppColors.textSecondary(mode)
              .withOpacity(item.isRead ? 0.8 : 1.0),
          fontSize: 13.sp,
          height: 1.5,
        ),
      );
    }

    final List<Widget> children = [];
    int lastMatchEnd = 0;

    for (final match in matches) {

      if (match.start > lastMatchEnd) {
        final text = message.substring(lastMatchEnd, match.start).trim();
        if (text.isNotEmpty) {
          children.add(
            Text(
              text,
              style: TextStyle(
                color: AppColors.textSecondary(mode)
                    .withOpacity(item.isRead ? 0.8 : 1.0),
                fontSize: 13.sp,
                height: 1.5,
              ),
            ),
          );
          children.add(SizedBox(height: 12.h));
        }
      }

      final type = match.group(1)!;
      final label = match.group(2)!;

      children.add(
        Align(
          alignment: Alignment.centerLeft,
          child: _ActionChip(
            label: label,
            color: _accentColor,
            onTap: () => widget.service.triggerAction({
              'action_type': type,
              'label': label,
            }),
          ),
        ),
      );
      children.add(SizedBox(height: 16.h));

      lastMatchEnd = match.end;
    }


    if (lastMatchEnd < message.length) {
      final remaining = message.substring(lastMatchEnd).trim();
      if (remaining.isNotEmpty) {
        children.add(
          Text(
            remaining,
            style: TextStyle(
              color: AppColors.textSecondary(mode)
                  .withOpacity(item.isRead ? 0.8 : 1.0),
              fontSize: 13.sp,
              height: 1.5,
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }


  String get _shortText {
    if (item.type == NotificationType.notice) {
      return item.data?['short'] as String? ?? item.message;
    }
    return item.message;
  }


  String? _localVersion;
  bool _isNewer = false;

  @override
  void initState() {
    super.initState();
    _expanded = false;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _checkVersion();
  }

  Future<void> _checkVersion() async {
    final notiVersion = item.data?['version'] as String?;
    if (notiVersion == null) return;

    _localVersion = await UpdateService.getLocalVersion();
    if (_localVersion != null) {
      final cmp = UpdateService.compareVersions(_localVersion!, notiVersion);
      if (mounted) {
        setState(() {
          _isNewer = cmp < 0;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _controller.forward();
      // Marcar como leída al expandir
      widget.service.markAsRead(item.id);
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: EdgeInsets.only(bottom: 14.h),
        decoration: BoxDecoration(
          color: AppColors.surface(mode),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: item.isRead
                ? _borderColor.withOpacity(0.2)
                : _borderColor.withOpacity(0.7),
            width: item.isRead ? 1.w : 1.8.w,
          ),
          boxShadow: [
            if (!item.isRead)
              BoxShadow(
                color: _accentColor.withOpacity(0.12),
                blurRadius: 14,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCollapsedRow(),
              SizeTransition(
                sizeFactor: _expandAnimation,
                axisAlignment: -1,
                child: _buildExpandedContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedRow() {
    final iconUrl = item.data?['icon_url'] as String?;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _headerGradient,
        ),
      ),
      child: Row(
        children: [
          if (iconUrl != null)
            Container(
              width: 38.r,
              height: 38.r,
              margin: EdgeInsets.only(right: 12.w),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child: CachedNetworkImage(
                  imageUrl: iconUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: _accentColor.withOpacity(0.1),
                    child: Center(
                      child: SizedBox(
                        width: 20.r,
                        height: 20.r,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _accentColor.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Image.asset(
                    'assets/MG-I-T.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: _accentColor.withOpacity(0.3)),
              ),
            )
          else
            Container(
              padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: _accentColor.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: _accentColor.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_typeIcon, color: _accentColor, size: 11.r),
                  SizedBox(width: 4.w),
                  Text(
                    _typeLabel,
                    style: TextStyle(
                      color: _accentColor,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(width: iconUrl != null ? 0 : 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    color: AppColors.textPrimary(mode)
                        .withOpacity(item.isRead ? 0.8 : 1.0),
                    fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!_expanded) ...[
                  SizedBox(height: 2.h),
                  Text(
                    _shortText,
                    style: TextStyle(
                      color: AppColors.textSecondary(mode)
                          .withOpacity(item.isRead ? 0.5 : 0.7),
                      fontSize: 12.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 8.w),
          if (!item.isRead)
            Container(
              width: 8.r,
              height: 8.r,
              margin: EdgeInsets.only(right: 6.w),
              decoration: BoxDecoration(
                color: _accentColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _accentColor.withOpacity(0.6),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          AnimatedRotation(
            turns: _expanded ? 0.5 : 0.0,
            duration: const Duration(milliseconds: 280),
            child: Icon(
              Ionicons.chevron_down_outline,
              color: AppColors.textSecondary(mode).withOpacity(0.5),
              size: 16.r,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent() {
    final imageUrl = item.data?['image_url'] as String?;
    final actionsObj = item.data?['actions'] as List<dynamic>?;
    final isBetaNoti = item.data?['is_beta'] as bool? ?? false;
    final notiVersion = item.data?['version'] as String?;

    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 14.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _accentColor.withOpacity(0.04),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: _borderColor.withOpacity(0.2), height: 1),
          SizedBox(height: 12.h),


          if (imageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: double.infinity,
                height: 140.h,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: double.infinity,
                  height: 140.h,
                  color: _accentColor.withOpacity(0.05),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: _accentColor.withOpacity(0.3),
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Image.asset(
                  'assets/MG-B.png',
                  width: double.infinity,
                  height: 140.h,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 12.h),
          ],


          if (_isNewer) ...[
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppColors.primaryBlueMid.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.primaryBlueMid.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Ionicons.sparkles_outline,
                      color: AppColors.primaryBlueMid, size: 20.r),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      '¡Aquí están las novedades del MG Music más reciente! Léelas antes de instalarla para estar al tanto de todo.',
                      style: TextStyle(
                        color: AppColors.textPrimary(mode),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
          ],


          if (notiVersion != null)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                children: [
                  Icon(isBetaNoti ? Ionicons.flask : Ionicons.rocket,
                      color: AppColors.textSecondary(mode).withOpacity(0.5),
                      size: 14.r),
                  SizedBox(width: 6.w),
                  Text(
                    'Versión $notiVersion ${isBetaNoti ? '(Beta)' : '(Relase)'}',
                    style: TextStyle(
                      color: AppColors.textSecondary(mode).withOpacity(0.6),
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_localVersion != null && main_app.isBeta) ...[
                    Text('  ·  ',
                        style: TextStyle(
                            color: AppColors.textSecondary(mode)
                                .withOpacity(0.3))),
                    Text(
                      'Tu versión: $_localVersion (Beta)',
                      style: TextStyle(
                        color: AppColors.textSecondary(mode).withOpacity(0.4),
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                ],
              ),
            ),

          _buildRichMessage(item.message, item.data, mode),
          SizedBox(height: 16.h),


          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('dd/MM/yyyy · HH:mm').format(item.timestamp),
                style: TextStyle(
                  color: AppColors.textSecondary(mode)
                      .withOpacity(item.isRead ? 0.3 : 0.4),
                  fontSize: 11.sp,
                ),
              ),


              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_isNewer)
                      Padding(
                        padding: EdgeInsets.only(bottom: 10.h),
                        child: _ActionChip(
                          label: 'Abrir Actualización',
                          icon: Ionicons.download_outline,
                          color: AppColors.primaryBlueMid,
                          onTap: () => widget.service
                              .triggerAction({'action_type': 'open_updates'}),
                        ),
                      ),
                    if (actionsObj != null)
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        alignment: WrapAlignment.end,
                        children: actionsObj.where((act) {
                          final label = act['label'] as String? ?? '';
                          return !item.message.contains(label);
                        }).map((act) {
                          final label = act['label'] as String? ?? 'Abrir';
                          return _ActionChip(
                            label: label,
                            color: _accentColor,
                            onTap: () => widget.service.triggerAction(
                                act as Map<String, dynamic>),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}




class _ActionChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: color.withOpacity(0.35)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon ?? Ionicons.open_outline, color: color, size: 14.r),
              SizedBox(width: 5.w),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
