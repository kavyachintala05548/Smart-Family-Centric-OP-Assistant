import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../models/models.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  List<AppointmentModel> appointments = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadAppointments();
    });
  }

  Future<void> loadAppointments() async {
    if (!mounted) return;
    setState(() => loading = true);
    try {
      final response = await ApiClient.get('/appointments');
      if (!mounted) return;
      setState(() {
        appointments = (response as List).map((item) => AppointmentModel.fromJson(item)).toList();
        loading = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> cancelAppointment(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes, Cancel')),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await ApiClient.put('/appointments/$id/cancel', {});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment cancelled successfully.')));
      loadAppointments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
    }
  }

  Future<void> openRescheduleDialog(AppointmentModel appointment) async {
    try {
      final availabilityResponse = await ApiClient.get('/doctors/${appointment.doctorId}/availability');
      if (!mounted) return;
      final slots = (availabilityResponse as List)
          .map((item) => AvailabilityModel.fromJson(item))
          .where((slot) => slot.status == 'available')
          .toList();

      if (!mounted) return;

      if (slots.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No available slots for rescheduling.')));
        return;
      }

      int? selectedNewSlotId = slots.first.id;

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: const Text('Reschedule Appointment'),
            content: SizedBox(
              width: double.maxFinite,
              height: 250,
              child: ListView.builder(
                itemCount: slots.length,
                itemBuilder: (context, index) {
                  final slot = slots[index];
                  return RadioListTile<int>(
                    value: slot.id,
                    groupValue: selectedNewSlotId,
                    onChanged: (v) => setStateDialog(() => selectedNewSlotId = v),
                    title: Text('${slot.date} at ${slot.time}'),
                  );
                },
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await ApiClient.put('/appointments/${appointment.id}/reschedule', {
                      'new_slot_id': selectedNewSlotId,
                    });
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment rescheduled successfully.')));
                    loadAppointments();
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
                  }
                },
                child: const Text('Confirm Reschedule'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'booked':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'rescheduled':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Appointments')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadAppointments,
              child: error != null
                  ? ListView(children: [
                      const SizedBox(height: 150),
                      Center(child: Text(error!, style: const TextStyle(color: Colors.red))),
                      const SizedBox(height: 16),
                      Center(
                        child: OutlinedButton.icon(
                          onPressed: loadAppointments,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ),
                    ])
                  : appointments.isEmpty
                      ? ListView(children: const [SizedBox(height: 200), Center(child: Text('No appointments found.'))])
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: appointments.length,
                          itemBuilder: (context, index) {
                            final apt = appointments[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Appointment #${apt.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Chip(
                                          label: Text(apt.status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11)),
                                          backgroundColor: getStatusColor(apt.status),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text('Doctor ID: ${apt.doctorId}'),
                                    Text('Date & Time: ${apt.date} at ${apt.time}'),
                                    if (apt.symptoms != null && apt.symptoms!.isNotEmpty)
                                      Text('Symptoms: ${apt.symptoms}'),
                                    if (apt.bookingNotes != null && apt.bookingNotes!.isNotEmpty)
                                      Text('Notes: ${apt.bookingNotes}'),
                                    const SizedBox(height: 12),
                                    if (apt.status.toLowerCase() == 'booked')
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          OutlinedButton.icon(
                                            onPressed: () => openRescheduleDialog(apt),
                                            icon: const Icon(Icons.edit_calendar, size: 16),
                                            label: const Text('Reschedule'),
                                          ),
                                          const SizedBox(width: 8),
                                          FilledButton.icon(
                                            style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                            onPressed: () => cancelAppointment(apt.id),
                                            icon: const Icon(Icons.cancel, size: 16),
                                            label: const Text('Cancel'),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
    );
  }
}
