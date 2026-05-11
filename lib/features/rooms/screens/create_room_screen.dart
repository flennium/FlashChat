import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/input_sanitizer.dart';
import '../../../core/utils/validators.dart';
import '../../../models/room_model.dart';
import '../../profile/widgets/avatar_picker.dart';
import '../controllers/room_controller.dart';

class CreateRoomScreen extends ConsumerStatefulWidget {
  const CreateRoomScreen({super.key, this.room});

  final RoomModel? room;

  bool get isEditing => room != null;

  @override
  ConsumerState<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends ConsumerState<CreateRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _accessCodeController = TextEditingController();
  late final String _uploadKey;

  bool _isPrivate = false;
  String _avatarUrl = '';

  @override
  void initState() {
    super.initState();
    final room = widget.room;
    _nameController.text = room?.name ?? '';
    _descriptionController.text = room?.description ?? '';
    _accessCodeController.text = room?.accessCode ?? '';
    _isPrivate = room?.isPrivate ?? false;
    _avatarUrl = room?.avatarUrl ?? '';
    _uploadKey = room?.id ?? 'draft_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _accessCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(roomControllerProvider);
    final isEditing = widget.isEditing;
    final title = isEditing ? 'Edit room' : 'Create room';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (isEditing)
            IconButton(
              onPressed: state.isLoading ? null : _confirmDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Delete room',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Column(
              children: [
                AvatarPicker(
                  imageUrl: _avatarUrl,
                  onTap: state.isLoading ? () {} : _pickAvatar,
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: state.isLoading ? null : _pickAvatar,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(_avatarUrl.isEmpty
                      ? 'Add room avatar'
                      : 'Change room avatar'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Room name'),
                  validator: Validators.roomName,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: Validators.roomDescription,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  value: _isPrivate,
                  onChanged: (value) => setState(() => _isPrivate = value),
                  title: const Text('Private room'),
                ),
                if (_isPrivate)
                  TextFormField(
                    controller: _accessCodeController,
                    decoration: const InputDecoration(labelText: 'Access code'),
                    validator: (value) {
                      if (!_isPrivate) return null;
                      return Validators.accessCodeRequired(value);
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: state.isLoading ? null : _submit,
            child: Text(
              state.isLoading
                  ? (isEditing ? 'Saving...' : 'Creating...')
                  : (isEditing ? 'Save changes' : 'Create room'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAvatar() async {
    final imageUrl = await ref
        .read(roomControllerProvider.notifier)
        .uploadRoomAvatar(_uploadKey);
    if (!mounted || imageUrl == null) return;
    setState(() => _avatarUrl = imageUrl);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(roomControllerProvider.notifier);
    final normalizedName =
        InputSanitizer.normalizeRoomName(_nameController.text);
    final normalizedDescription =
        InputSanitizer.normalizeRoomDescription(_descriptionController.text);
    final normalizedAccessCode =
        InputSanitizer.normalizeAccessCode(_accessCodeController.text);
    final ok = widget.isEditing
        ? await notifier.updateRoom(
            room: widget.room!,
            name: normalizedName,
            description: normalizedDescription,
            isPrivate: _isPrivate,
            accessCode: normalizedAccessCode,
            avatarUrl: _avatarUrl,
          )
        : await notifier.createRoom(
            name: normalizedName,
            description: normalizedDescription,
            isPrivate: _isPrivate,
            accessCode: normalizedAccessCode,
            avatarUrl: _avatarUrl,
          );

    if (ok && mounted) Navigator.of(context).pop(false);
  }

  Future<void> _confirmDelete() async {
    final room = widget.room;
    if (room == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete room'),
        content:
            Text('Delete "${room.name}"? This removes it from the room list.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;

    final ok = await ref.read(roomControllerProvider.notifier).deleteRoom(room);
    if (ok && mounted) {
      Navigator.of(context).pop(true);
    }
  }
}
