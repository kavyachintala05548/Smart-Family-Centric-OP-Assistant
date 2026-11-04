import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../models/models.dart';

class SpecialistScreen extends StatefulWidget {
  const SpecialistScreen({super.key});

  @override
  State<SpecialistScreen> createState() => _SpecialistScreenState();
}

class _SpecialistScreenState extends State<SpecialistScreen> {
  final symptomController = TextEditingController();
  final feeController = TextEditingController(text: '2000');
  List<RecommendationModel> recommendations = [];
  bool loading = false;
  String? error;

  Future<void> findSpecialists() async {
    setState(() { loading = true; error = null; });
    try {
      final symptoms = symptomController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final response = await ApiClient.post('/recommendations', {
        'symptoms': symptoms,
        'custom_symptom_text': symptomController.text,
        'city': 'Hyderabad',
        'latitude': 17.3850,
        'longitude': 78.4867,
        'preferences': {
          'max_consultation_fee': double.tryParse(feeController.text) ?? 2000,
          'preferred_gender': 'Any',
        },
        'sort_by': 'best_match',
      });
      setState(() {
        recommendations = (response['recommendations'] as List).map((item) => RecommendationModel.fromJson(item)).toList();
      });
    } catch (e) {
      setState(() => error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> openBooking(RecommendationModel recommendation) async {
    try {
      final familyResponse = await ApiClient.get('/family-members');
      final familyMembers = (familyResponse as List).map((item) => FamilyMemberModel.fromJson(item)).toList();
      if (!mounted) return;

      if (familyMembers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add a family member first.')));
        return;
      }

      final availabilityResponse = await ApiClient.get('/doctors/${recommendation.doctor.id}/availability');
      final slots = (availabilityResponse as List).map((item) => AvailabilityModel.fromJson(item)).toList();
      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => BookingSheet(
          recommendation: recommendation,
          familyMembers: familyMembers,
          slots: slots,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find Specialist')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: symptomController, decoration: const InputDecoration(labelText: 'Symptoms', hintText: 'child fever, cough', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: feeController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Maximum consultation fee', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: loading ? null : findSpecialists, icon: const Icon(Icons.search), label: Text(loading ? 'Searching...' : 'Find Specialists'))),
            const SizedBox(height: 12),
            if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
            Expanded(
              child: recommendations.isEmpty
                  ? const Center(child: Text('Enter symptoms and search for specialists.'))
                  : ListView.builder(
                      itemCount: recommendations.length,
                      itemBuilder: (context, index) {
                        final item = recommendations[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text(item.doctor.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                                    Chip(label: Text('${item.matchScore.toStringAsFixed(1)}/100')),
                                  ],
                                ),
                                Text('${item.doctor.specialty} • ${item.doctor.hospitalName ?? ''}'),
                                Text('Fee: Rs.${item.doctor.consultationFee.toStringAsFixed(0)} • Rating: ${item.doctor.averageRating}'),
                                Text('Distance: ${item.distanceKm} km • Wait: ${item.doctor.waitingTime ?? '-'} min'),
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                                  child: Text(item.explanation),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(width: double.infinity, child: FilledButton(onPressed: () => openBooking(item), child: const Text('View Slots & Book'))),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class BookingSheet extends StatefulWidget {
  final RecommendationModel recommendation;
  final List<FamilyMemberModel> familyMembers;
  final List<AvailabilityModel> slots;

  const BookingSheet({super.key, required this.recommendation, required this.familyMembers, required this.slots});

  @override
  State<BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<BookingSheet> {
  int? selectedFamilyMember;
  int? selectedSlot;
  final notesController = TextEditingController();
  bool booking = false;

  Future<void> book() async {
    if (selectedFamilyMember == null || selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a family member and time slot.')));
      return;
    }
    setState(() => booking = true);
    try {
      await ApiClient.post('/appointments', {
        'doctor_id': widget.recommendation.doctor.id,
        'family_member_id': selectedFamilyMember,
        'slot_id': selectedSlot,
        'symptoms': widget.recommendation.doctor.specialty,
        'booking_notes': notesController.text,
      });
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment booked successfully.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
    } finally {
      setState(() => booking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Book ${widget.recommendation.doctor.fullName}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Select Family Member'),
            DropdownButtonFormField<int>(
              initialValue: selectedFamilyMember,
              items: widget.familyMembers.map((member) => DropdownMenuItem(value: member.id, child: Text('${member.name} (${member.relationship ?? '-'})'))).toList(),
              onChanged: (value) => setState(() => selectedFamilyMember = value),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            const Text('Select Appointment Slot'),
            SizedBox(
              height: 220,
              child: widget.slots.isEmpty
                  ? const Center(child: Text('No available slots.'))
                  : ListView.builder(
                      itemCount: widget.slots.length,
                      itemBuilder: (context, index) {
                        final slot = widget.slots[index];
                        return RadioListTile<int>(
                          value: slot.id,
                          groupValue: selectedSlot,
                          onChanged: (value) => setState(() => selectedSlot = value),
                          title: Text('${slot.date} at ${slot.time}'),
                        );
                      },
                    ),
            ),
            TextField(controller: notesController, decoration: const InputDecoration(labelText: 'Booking Notes', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: booking ? null : book, child: Text(booking ? 'Booking...' : 'Confirm Booking'))),
          ],
        ),
      ),
    );
  }
}
