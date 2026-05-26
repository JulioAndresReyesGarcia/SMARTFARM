/**
 * Asistente veterinario orientativo — sugerencias de especialistas (demo, extensible a Maps).
 */
const VETERINARIANS = [
  {
    name: 'Dr. Carlos Mendoza',
    specialty: 'Bovinos y producción lechera',
    species: ['bovino'],
    location: 'Zona rural — consultorio móvil',
    phone: '+52 555 100 2001',
    isEmergency: false,
  },
  {
    name: 'Dra. Ana Ruiz',
    specialty: 'Aves y avicultura',
    species: ['aves', 'pollo', 'gallina'],
    location: 'Centro avícola regional',
    phone: '+52 555 100 2002',
    isEmergency: false,
  },
  {
    name: 'Dr. Luis Herrera',
    specialty: 'Porcinos y bioseguridad',
    species: ['porcino', 'cerdo'],
    location: 'Granjas del norte',
    phone: '+52 555 100 2003',
    isEmergency: false,
  },
  {
    name: 'Urgencias Vet 24h',
    specialty: 'Emergencias — todas las especies',
    species: ['bovino', 'porcino', 'aves', 'ovino', 'caprino'],
    location: 'Servicio de urgencias',
    phone: '+52 555 911 VET',
    isEmergency: true,
  },
];

function normalize(text) {
  return String(text || '').toLowerCase();
}

function recommendVeterinarians({ species, riskLevel, intent }) {
  const sp = normalize(species);
  const results = [];

  if (riskLevel === 'emergencia' || intent === 'emergencia') {
    const emergency = VETERINARIANS.find((v) => v.isEmergency);
    if (emergency) results.push(emergency);
  }

  for (const vet of VETERINARIANS) {
    if (vet.isEmergency) continue;
    const match = vet.species.some((s) => sp.includes(s) || s.includes(sp));
    if (match) results.push(vet);
  }

  if (results.length === 0) {
    return VETERINARIANS.filter((v) => !v.isEmergency).slice(0, 2);
  }

  return results.slice(0, 3);
}

module.exports = { recommendVeterinarians, VETERINARIANS };
