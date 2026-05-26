import 'package:smartfarm_ai/ai/models/veterinarian_suggestion.dart';

/// Directorio demo de veterinarios (integrable con Maps / API externa).
class VeterinarianDirectory {
  VeterinarianDirectory._();

  static const all = <VeterinarianSuggestion>[
    VeterinarianSuggestion(
      name: 'Dr. Carlos Mendoza',
      specialty: 'Bovinos y producción lechera',
      location: 'Zona rural — consultorio móvil',
      phone: '+52 555 100 2001',
      notes: 'Mastitis, nutrición y reproducción bovina.',
    ),
    VeterinarianSuggestion(
      name: 'Dra. Ana Ruiz',
      specialty: 'Porcinos y bioseguridad',
      location: 'Centro agropecuario regional',
      phone: '+52 555 100 2002',
      notes: 'Sanidad porcina, vacunación y manejo de granjas.',
    ),
    VeterinarianSuggestion(
      name: 'Dr. Luis Herrera',
      specialty: 'Aves y avicultura',
      location: 'Parque industrial avícola',
      phone: '+52 555 100 2003',
      notes: 'Sanidad aviar, vacunas y control de densidad.',
    ),
    VeterinarianSuggestion(
      name: 'Dra. Patricia Gómez',
      specialty: 'Ovinos y caprinos',
      location: 'Zona ganadera alta',
      phone: '+52 555 100 2004',
      notes: 'Parasitosis, partos y nutrición de rumiantes menores.',
    ),
    VeterinarianSuggestion(
      name: 'Urgencias VetAgro 24h',
      specialty: 'Urgencias veterinarias',
      location: 'Servicio regional de emergencias',
      phone: '+52 555 911 VET',
      notes: 'Atención de emergencias en campo y traslado.',
      isEmergency: true,
    ),
    VeterinarianSuggestion(
      name: 'Dr. Miguel Soto',
      specialty: 'Medicina veterinaria rural general',
      location: 'Atención a domicilio — zona rural',
      phone: '+52 555 100 2005',
      notes: 'Visitas a finca, vacunación y cirugías menores.',
    ),
  ];

  static List<VeterinarianSuggestion> bySpecies(String species) {
    final s = species.toLowerCase();
    if (s.contains('bov')) {
      return all.where((v) => v.specialty.toLowerCase().contains('bovin') || v.specialty.contains('lechera')).toList();
    }
    if (s.contains('porc')) {
      return all.where((v) => v.specialty.toLowerCase().contains('porc')).toList();
    }
    if (s.contains('ovin') || s.contains('capr')) {
      return all.where((v) => v.specialty.toLowerCase().contains('ovin') || v.specialty.contains('capr')).toList();
    }
    if (s.contains('av') || s.contains('pollo') || s.contains('gallina')) {
      return all.where((v) => v.specialty.toLowerCase().contains('av')).toList();
    }
    return all.where((v) => v.specialty.contains('rural') || v.specialty.contains('general')).toList();
  }

  static List<VeterinarianSuggestion> emergencies() =>
      all.where((v) => v.isEmergency).toList();
}
