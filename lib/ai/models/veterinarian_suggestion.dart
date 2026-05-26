/// Sugerencia de veterinario especialista (datos demo; integrable con Maps/API).
class VeterinarianSuggestion {
  final String name;
  final String specialty;
  final String location;
  final String phone;
  final String notes;
  final bool isEmergency;

  const VeterinarianSuggestion({
    required this.name,
    required this.specialty,
    required this.location,
    required this.phone,
    this.notes = '',
    this.isEmergency = false,
  });
}
