# Musica Player - Software de Automatización de Radio

## Descripción General

Musica Player es una aplicación macOS desarrollada en SwiftUI para la automatización de radio. Permite gestionar dos reproductores de audio independientes con funcionalidades avanzadas de reproducción, efectos de audio, detección de BPM, y comandos de automatización entre players.

## Características Principales

### 🎵 Reproducción Dual
- **Dos Players Independientes**: Cada player tiene su propia playlist y controles independientes
- **Reproducción Simultánea**: Ambos players pueden reproducir audio al mismo tiempo
- **Precarga Inteligente**: Los archivos marcados como "siguiente" se precargan automáticamente para transiciones sin interrupciones
  - Precarga automática cuando se marca una canción como "next"
  - Scheduling inmediato en playerNode (incluso durante reproducción)
  - Visualización de información de siguiente canción (título, artista, duración)
  - Panel "NEXT:" en la UI mostrando detalles completos

### 📋 Gestión de Playlists
- **Playlists Dinámicas**: Agregar, eliminar y reorganizar canciones mediante drag & drop
- **Comandos de Automatización**: Insertar comandos en la playlist para controlar ambos players
- **Marcado de Siguiente**: Marcar cualquier canción como "siguiente" para reproducción prioritaria
- **Modos de Reproducción**:
  - **Shuffle**: Reproducción aleatoria
  - **Repeat One**: Repetir la canción actual
  - **Repeat All**: Repetir toda la playlist
- **Indicadores Visuales**:
  - "ON AIR" para la canción en reproducción
  - "NEXT" para la canción marcada como siguiente
  - Parpadeo cuando quedan 10 segundos y hay una canción marcada como siguiente

### 🎛️ Efectos de Audio
Cada player tiene acceso a efectos profesionales:

#### Compresor
- **Threshold**: -20 dB (ajustable)
- **Ratio**: 1:1 a 20:1
- **Attack**: 0.001 segundos
- **Release**: 0.05 segundos

#### Reverb
- **Wet/Dry Mix**: 0-100%
- **Presets**: Medium Hall, Large Hall, Cathedral, etc.

#### Delay
- **Delay Time**: 0.25 segundos (ajustable)
- **Feedback**: 0-100%
- **Wet/Dry Mix**: 0-100%

#### Ecualizador
- **Low Gain**: Control de frecuencias bajas
- **Mid Gain**: Control de frecuencias medias
- **High Gain**: Control de frecuencias altas

### 🎚️ Controles de Reproducción
- **Velocidad de Reproducción**: 0.5x a 2.0x
- **Balance Estéreo**: -1.0 (izquierda) a 1.0 (derecha)
- **Crossfade**: Transiciones suaves entre canciones (duración configurable)
- **Fade In/Out**: Fade automático al inicio y fin de canciones
- **Seek**: Avanzar/retroceder 10 segundos
- **Volumen Master**: Control de volumen global para ambos players

### 🎯 Detección de BPM y Beats
- **Detección Automática de BPM**: Análisis automático del tempo de las canciones
- **Detección de Beats en Tiempo Real**: Indicador visual que parpadea con cada beat
- **Métodos Avanzados**:
  - Spectral Flux para detectar cambios espectrales
  - High-Frequency Content (HFC) para percusión
  - Detección combinada multi-método
- **Parámetros Ajustables**:
  - Factor de suavizado
  - Incremento relativo mínimo
  - Multiplicador de desviación estándar
  - Threshold mínimo de energía
  - Pesos para Spectral Flux y HFC

### 🔇 Detección Automática de Silencios
- **Monitoreo en Tiempo Real**: Análisis continuo del nivel RMS de audio
- **Detección Configurable**: 
  - Umbral de silencio ajustable (0.001 - 0.1)
  - Duración mínima de silencio antes de actuar (1.0 - 10.0 segundos)
- **Acciones Automáticas**:
  - **Auto-Stop**: Detiene la reproducción cuando se detecta silencio prolongado
  - **Auto-Play Fallback**: Avanza automáticamente a la siguiente canción
- **Indicadores de Estado**: 
  - Estado visual de silencio en tiempo real
  - Duración del silencio detectado
- **Casos de Uso**:
  - Prevenir transmisión en silencio (radio en vivo)
  - Detectar archivos corruptos o vacíos
  - Mantener flujo continuo de contenido (automatización 24/7)

### 📊 Visualización
- **VU Meters**: Medidores de nivel estéreo en tiempo real
- **Sensibilidad Ajustable**: Control de la sensibilidad de los VU meters
- **Indicador de Beat**: LED que parpadea con cada beat detectado
- **Información de Canción**: Título y artista mostrados prominentemente

### 🔄 Comandos de Automatización
Los comandos permiten automatizar acciones entre players:

1. **Parar Player 1 → Siguiente en Player 2**: Detiene el Player 1 y reproduce el siguiente en Player 2
2. **Parar Player 2 → Siguiente en Player 1**: Detiene el Player 2 y reproduce el siguiente en Player 1
3. **Parar Player 1**: Detiene el Player 1
4. **Parar Player 2**: Detiene el Player 2
5. **Pausar Player 1**: Pausa el Player 1
6. **Pausar Player 2**: Pausa el Player 2
7. **Reanudar Player 1**: Reanuda el Player 1
8. **Reanudar Player 2**: Reanuda el Player 2

Los comandos se pueden insertar en cualquier posición de la playlist y se ejecutan automáticamente cuando llega su turno.

### 🖥️ Interfaz de Usuario

#### Ventana Principal
- **Status Bar Superior**: 
  - Reloj en tiempo real
  - Botón de AutoPlay (activa/desactiva autoPlay en ambos players)
  - Botón de auto-ordenar ventanas
  - Botón de configuración
  - Botones para mostrar/ocultar cada player
- **Paneles Arrastrables**: Cada player es un panel independiente que se puede arrastrar y reposicionar
- **Auto-ordenamiento**: Botón para reorganizar automáticamente los paneles

#### Vista de Player
- **Información de Canción Actual**: Título y artista mostrados en grande
- **Controles de Reproducción**: Play, Pause, Stop, Previous, Next, Rewind, Fast Forward
- **Barra de Progreso**: Con indicadores de tiempo, BPM y clave musical (Camelot Wheel)
- **Indicador de Beat**: LED que parpadea con cada beat
- **VU Meters**: Visualización de niveles de audio
- **Panel NEXT**: Muestra información de la canción marcada como siguiente
- **Lista de Playlist**: 
  - Números de orden
  - Duración de cada canción
  - Indicadores visuales (ON AIR, NEXT)
  - Menú contextual con opciones avanzadas

#### Ventana de Configuración
- **Configuración por Player**: Cada player tiene su propia sección
- **BPM y Beat Indicator**: Visualización en tiempo real
- **Controles de Volumen**: Sliders individuales y volumen master
- **VU Meters**: Visualización detallada
- **Efectos de Audio**: Controles completos para todos los efectos
- **Controles de Reproducción**: Ajustes de velocidad, balance, crossfade, etc.
- **Parámetros de Detección**: Ajustes finos para detección de BPM y beats
- **Detección de Silencios**: Configuración completa de umbrales y acciones automáticas

## Estructura del Proyecto

```
musica-player/
├── musica-player/
│   ├── musica_playerApp.swift      # Punto de entrada de la aplicación
│   ├── MainWindowView.swift        # Vista principal con paneles arrastrables
│   ├── PlayerView.swift            # Vista principal de cada player
│   ├── PlayerStatusView.swift      # Vista de estado del player
│   ├── DraggablePlayerPanel.swift  # Panel arrastrable para cada player
│   ├── StatusBarView.swift         # Barra de estado superior
│   ├── ConfigView.swift             # Ventana de configuración
│   ├── VUMeterView.swift           # Visualización de VU meters
│   ├── MusicPlayer.swift            # Motor de reproducción de audio
│   ├── Playlist.swift               # Gestión de playlists
│   ├── PlaylistItem.swift          # Items de playlist (canciones y comandos)
│   ├── PlaylistCommand.swift       # Definición de comandos
│   └── Song.swift                   # Modelo de datos de canción
└── musica-player.xcodeproj/
```

## Componentes Principales

### MusicPlayer
Clase principal que maneja la reproducción de audio usando `AVAudioEngine`:
- Reproducción de archivos de audio
- Aplicación de efectos en tiempo real
- Detección de BPM y beats
- Gestión de crossfade y fades
- Precarga de archivos

### Playlist
Gestiona las listas de reproducción:
- Almacena canciones y comandos
- Maneja índices actuales y siguientes
- Soporta shuffle y repeat modes
- Permite reordenamiento mediante drag & drop

### PlaylistCommand
Sistema de comandos para automatización:
- Comandos predefinidos para controlar players
- Ejecución automática cuando llega su turno
- Soporte para secuencias de comandos

## Uso

### Agregar Canciones
1. Hacer clic en el botón "Agregar Canciones" en la playlist
2. Seleccionar archivos de audio desde el selector de archivos
3. Las canciones se agregan al final de la playlist

### Reproducir
1. Seleccionar una canción de la lista
2. Hacer clic en el botón Play o usar el menú contextual "Reproducir Ahora"
3. Usar los controles de reproducción para controlar la reproducción

### Marcar como Siguiente
1. Clic derecho en una canción
2. Seleccionar "Reproducir Siguiente"
3. La canción se marcará con "NEXT" y se precargará automáticamente

### Insertar Comandos
1. Clic derecho en cualquier item de la playlist
2. Seleccionar "Insertar Comando"
3. Elegir el comando deseado del submenú
4. El comando se insertará después del item seleccionado

### Configurar Efectos
1. Abrir la ventana de configuración (botón en la status bar)
2. Navegar a la sección de efectos del player deseado
3. Activar y ajustar los parámetros de los efectos

### Configurar Detección de Silencios
1. Abrir la ventana de configuración
2. Navegar a la sección "Detección de Silencios" del player deseado
3. Activar "Activar Detección de Silencios"
4. Ajustar el umbral de silencio (nivel RMS mínimo)
5. Configurar la duración de silencio antes de actuar
6. Elegir la acción: Auto-Stop o Avanzar a Siguiente Canción
7. El estado se muestra en tiempo real (silencioso/audio detectado)

### AutoPlay
1. Hacer clic en el botón de AutoPlay en la status bar (arriba del reloj)
2. Esto activará/desactivará el autoPlay en ambos players simultáneamente

## Requisitos del Sistema

- **macOS**: 12.0 o superior
- **Xcode**: 14.0 o superior (para desarrollo)
- **Swift**: 5.7 o superior

## Tecnologías Utilizadas

- **SwiftUI**: Framework de interfaz de usuario
- **AVFoundation**: Motor de audio y efectos
- **Combine**: Programación reactiva para observación de cambios
- **CoreMedia**: Procesamiento de metadatos de audio

## Características Técnicas

### Seguridad de Archivos
- Uso de Security-Scoped Bookmarks para acceso persistente a archivos seleccionados por el usuario
- Gestión adecuada de permisos de acceso a recursos

### Rendimiento
- Precarga asíncrona de archivos marcados como "siguiente"
- Procesamiento de audio en tiempo real con bajo latency
- Caché de duraciones de canciones para mejor rendimiento

### Arquitectura
- Patrón MVVM con `ObservableObject` y `@Published`
- Separación de responsabilidades entre componentes
- Referencias cruzadas entre players para comandos

## Licencia

Este proyecto es software propietario. Todos los derechos reservados.

## Autor

Desarrollado por Martin Fernandez

## Notas de Desarrollo

- La aplicación utiliza `AVAudioEngine` para procesamiento de audio de bajo nivel
- Los efectos se aplican mediante `AVAudioUnitEffect` y unidades especializadas
- La detección de BPM utiliza análisis de energía y detección de picos
- La detección de beats en tiempo real utiliza métodos avanzados:
  - Spectral Flux para cambios espectrales
  - High-Frequency Content (HFC) para percusión
  - Umbrales dinámicos basados en estadísticas
- **Detección de Clave Musical (Camelot Wheel)**:
  - Análisis cromático (chromagram) para detectar tonalidad
  - Algoritmo Krumhansl-Schmuckler para identificación de clave
  - Conversión automática a sistema Camelot (1A-12B)
  - Visualización junto al BPM en la UI
- **Detección de Silencios**:
  - Monitoreo continuo del nivel RMS en tiempo real
  - Rastreo de duración de silencios
  - Acciones automáticas configurables (auto-stop o avanzar)
  - Indicadores de estado en tiempo real

