import 'package:flutter/material.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/app_header.dart';
import '../widgets/app_breadcrumbs.dart';

class MainLayout extends StatefulWidget {
  final Widget child;
  final String title;
  final List<BreadcrumbItem> breadcrumbs;
  final List<Widget>? actions;
  final int selectedSidebarIndex;
  final void Function(int)? onSidebarItemSelected;

  const MainLayout({
    Key? key,
    required this.child,
    required this.title,
    required this.breadcrumbs,
    this.actions,
    this.selectedSidebarIndex = 0,
    this.onSidebarItemSelected,
  }) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  bool _drawerOpen = false;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    return Scaffold(
      drawer: isDesktop
          ? null
          : Drawer(
              child: AppSidebar(
                selectedIndex: widget.selectedSidebarIndex,
                onItemSelected: (i) {
                  Navigator.of(context).pop();
                  if (widget.onSidebarItemSelected != null)
                    widget.onSidebarItemSelected!(i);
                },
              ),
            ),
      body: Row(
        children: [
          if (isDesktop)
            AppSidebar(
              selectedIndex: widget.selectedSidebarIndex,
              onItemSelected: widget.onSidebarItemSelected ?? (_) {},
            ),
          Expanded(
            child: Column(
              children: [
                AppHeader(
                  title: widget.title,
                  breadcrumbs: widget.breadcrumbs,
                  actions: widget.actions,
                  selectedSidebarIndex: widget.selectedSidebarIndex,
                ),
                Expanded(
                  child: Container(
                    color: const Color(0xFFF5F8FA),
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: widget.child,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
