import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/room_controller.dart';
import '../widgets/room_tile.dart';
import 'create_room_screen.dart';

class RoomListScreen extends ConsumerStatefulWidget {
  const RoomListScreen({super.key});

  @override
  ConsumerState<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends ConsumerState<RoomListScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final rooms = ref.watch(roomListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Rooms')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search rooms',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: rooms.when(
              data: (items) {
                final filtered = items.where((room) {
                  return room.name.toLowerCase().contains(_query) ||
                      room.description.toLowerCase().contains(_query);
                }).toList();
                if (filtered.isEmpty) {
                  return const Center(child: Text('No rooms found yet.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemBuilder: (_, index) => RoomTile(room: filtered[index]),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: filtered.length,
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text(error.toString())),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const CreateRoomScreen()),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create Room'),
      ),
    );
  }
}
