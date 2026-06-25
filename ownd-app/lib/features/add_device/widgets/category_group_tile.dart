part of 'category_picker.dart';

class _CategoryGroupTile extends StatelessWidget {
  final String title;
  final bool initiallyExpanded;
  final Widget child;

  const _CategoryGroupTile({
    required this.title,
    required this.initiallyExpanded,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 12),
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        initiallyExpanded: initiallyExpanded,
        children: [Align(alignment: Alignment.centerLeft, child: child)],
      ),
    );
  }
}
