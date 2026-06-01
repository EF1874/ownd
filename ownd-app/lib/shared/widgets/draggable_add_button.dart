import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DraggableAddButton extends ConsumerStatefulWidget {
  const DraggableAddButton({super.key});

  @override
  ConsumerState<DraggableAddButton> createState() => _DraggableAddButtonState();
}

class _DraggableAddButtonState extends ConsumerState<DraggableAddButton> {
  Offset _offset = const Offset(
    300,
    600,
  ); // Initial position (bottom right-ish)

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Set initial position to bottom right with some padding
    final size = MediaQuery.of(context).size;
    if (_offset == const Offset(300, 600)) {
      _offset = Offset(size.width - 80, size.height - 160);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _offset.dx,
      top: _offset.dy,
      child: Draggable(
        feedback: FloatingActionButton(
          onPressed: () {},
          child: const Icon(Icons.add),
        ),
        childWhenDragging:
            const SizedBox.shrink(), // Hide original when dragging
        onDragStarted: () {
          setState(() {});
        },
        onDragEnd: (details) {
          setState(() {
            // Constrain to screen
            final size = MediaQuery.of(context).size;
            const buttonSize = 56.0;
            double dx = details.offset.dx;
            double dy = details.offset.dy;

            // Simple constraints
            if (dx < 0) dx = 16;
            if (dx > size.width - buttonSize) dx = size.width - buttonSize - 16;
            if (dy < 100) dy = 100; // Keep away from top
            if (dy > size.height - buttonSize - 100) {
              dy = size.height - buttonSize - 100; // Keep away from bottom nav
            }

            _offset = Offset(dx, dy);
          });
        },
        child: FloatingActionButton(
          onPressed: () {
            // Navigate to Add Page
            // Use context.push because /add is a root route or we want it to stack
            context.push('/add');
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
