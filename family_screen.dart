import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../models/models.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  List<FamilyMemberModel> members = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadMembers();
  }

  Future<void> loadMembers() async {
    setState(() => loading = true);
    try {
      final response = await ApiClient.get('/family-members');
      setState(() {
        members = (response as List).map((item) => FamilyMemberModel.fromJson(item)).toList();
        loading = false;
        error = null;
      });
    } catch (e) {
      setState(() {
        loading = false;
        error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _showAddEditDialog({FamilyMemberModel? member}) {
    final nameController = TextEditingController(text: member?.name ?? '');
    final ageController = TextEditingController(text: member?.age?.toString() ?? '');
    final notesController = TextEditingController(text: member?.medicalNotes ?? '');
    String gender = member?.gender ?? 'Male';
    String relationship = member?.relationship ?? 'Child';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(member == null ? 'Add Family Member' : 'Edit Family Member'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Age', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: gender,
                  items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (v) => setStateDialog(() => gender = v!),
                  decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: relationship,
                  items: ['Self', 'Child', 'Spouse', 'Parent', 'Sibling'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (v) => setStateDialog(() => relationship = v!),
                  decoration: const InputDecoration(labelText: 'Relationship', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Medical Notes (optional)', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                try {
                  final body = {
                    'name': nameController.text.trim(),
                    'age': int.tryParse(ageController.text) ?? 0,
                    'gender': gender,
                    'relationship': relationship,
                    'medical_notes': notesController.text.trim(),
                  };

                  if (member == null) {
                    await ApiClient.post('/family-members', body);
                  } else {
                    await ApiClient.put('/family-members/${member.id}', body);
                  }

                  if (!mounted) return;
                  Navigator.pop(context);
                  loadMembers();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(member == null ? 'Family member added' : 'Family member updated')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> deleteMember(int id) async {
    try {
      await ApiClient.delete('/family-members/$id');
      loadMembers();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Family member deleted.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Members'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEditDialog(),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!, style: const TextStyle(color: Colors.red)))
              : members.isEmpty
                  ? const Center(child: Text('No family members found. Tap + to add.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        final member = members[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${member.gender ?? ''}, ${member.age ?? '-'} yrs • ${member.relationship ?? ''}\nNotes: ${member.medicalNotes ?? 'None'}'),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _showAddEditDialog(member: member),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => deleteMember(member.id),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Member'),
      ),
    );
  }
}
