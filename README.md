# SafeScan
Prototipo de aplicación móvil para la interpretación de anomalías vehiculares y señales visuales 

## ¿Qué hace la app?

- Conecta al vehículo vía inalámbrica usando un adaptador OBD
- Lee y traduce códigos de falla en lenguaje simple
- Clasifica los problemas por severidad: leve, moderado, urgente
- Escanea visualmente el tablero con la cámara *(próximamente)*
- Guarda el historial de diagnósticos *(próximamente)*

## Arquitectura


Organizada por features. Cada módulo contiene sus propias pantallas, lógica y modelos. La regla de dependencia es: `features → shared → core`, nunca al revés.


lib/
├── main.dart
├── core/
│   ├── router.dart        # Navegación centralizada
│   ├── theme.dart         # Colores, tipografía y estilos globales
│   └── constants.dart     # Constantes de la app
├── features/
│   ├── home/              # Pantalla principal
│   ├── obd/               # Conexión Bluetooth y dashboard
│   ├── diagnosis/         # Lectura e interpretación de códigos OBD
│   ├── camera/            # Escaneo visual del tablero (próximamente)
│   ├── history/           # Historial de diagnósticos (próximamente)
│   ├── voice/             # Integración de voz (futuro)
│   └── reports/           # Reportes en PDF (futuro)
└── shared/
├── widgets/            # Componentes reutilizables
└── utils/              # Utilidades y extensiones

---

## Estado actual del proyecto

### ✅ Listo
- Estructura de carpetas y arquitectura base
- `theme.dart` — identidad visual completa (dark mode, teal)
- `router.dart` — navegación centralizada
- `main.dart` — punto de entrada conectado a tema y router
- `home_screen.dart` — pantalla principal
- `connection_screen.dart` — flujo de conexión OBD
- `dashboard_screen.dart` — métricas del vehículo
- `diagnosis_screen.dart` — códigos OBD con severidad
- `history_screen.dart` — scaffold base listo

### 🔄 En progreso
- API REST del modelo de IA (compañero)
- `ai_service.dart` — pendiente hasta que la API esté lista

### 📋 Pendiente
- `camera_scan_screen.dart` — esperando modelo de visión
- `history_screen.dart` — lógica y UI completa
- Integración de Riverpod para state management
- Conexión Bluetooth real con OBD
- `voice/` — integración de voz
- `reports/` — exportar diagnósticos en PDF

---

## Cómo correr el proyecto

```bash
# Clonar el repositorio
git clone https://github.com/XJeCeRX/SafeScan.git

# Entrar a la carpeta
cd SafeScan

# Instalar dependencias
flutter pub get

# Correr la app
flutter run
```

---

## Convenciones del equipo

### Ramas