# Plan de Mejoras - Software de Automatización de Radio

Este documento detalla las mejoras propuestas para convertir DineMac en un software completo de automatización de radio profesional.

## 🎙️ Funcionalidades de Radio Profesional

### 1. Sistema de Programación
- [ ] **Programación por Horarios**
  - Calendario semanal con slots de programación
  - Programación automática basada en horarios
  - Bloques de programación (música, noticias, publicidad, etc.)
  - Programación recurrente (diaria, semanal, mensual)

- [ ] **Templates de Programación**
  - Plantillas predefinidas para diferentes tipos de programas
  - Templates para horas pico, madrugada, fines de semana
  - Personalización de templates

- [ ] **Gestión de Bloques de Contenido**
  - Bloques de música (30 min, 1 hora, etc.)
  - Bloques de noticias
  - Bloques de publicidad
  - Bloques de entrevistas/contenido hablado

### 2. Gestión de Contenido Avanzada

- [ ] **Base de Datos de Canciones**
  - Metadata completa (género, año, artista, álbum, BPM, duración)
  - Sistema de tags y categorías
  - Búsqueda avanzada y filtros
  - Calificaciones y favoritos
  - Historial de reproducción

- [ ] **Gestión de Publicidad**
  - Insertar spots publicitarios en la playlist
  - Programación de breaks publicitarios
  - Tracking de reproducción de anuncios
  - Rotación automática de anuncios
  - Horarios de exclusión (no publicidad en ciertos horarios)

- [ ] **Gestión de Noticias**
  - Insertar boletines de noticias
  - Programación de noticias por horarios
  - Priorización de noticias urgentes
  - Integración con feeds RSS

- [ ] **Gestión de IDs y Promos**
  - IDs de estación (jingles)
  - Promociones programadas
  - Rotación automática de IDs

### 3. Automatización Inteligente

- [ ] **Motor de Reglas**
  - Reglas basadas en horarios
  - Reglas basadas en género musical
  - Reglas de separación (no repetir mismo artista/álbum)
  - Reglas de rotación de canciones
  - Reglas de crossfade automático

- [x] **Detección de Silencios** - ✅ **IMPLEMENTADO**
  - ✅ Detección automática de silencios en audio - **IMPLEMENTADO**
    - Monitoreo en tiempo real del nivel RMS de audio
    - Umbral configurable para detectar silencio
    - Rastreo de duración de silencios
  - ✅ Auto-stop en silencios largos - **IMPLEMENTADO**
    - Detección automática cuando el silencio excede duración configurada
    - Auto-stop configurable
  - ⚠️ Auto-play de contenido de respaldo (parcialmente implementado)
    - Opción para avanzar a siguiente canción en silencio
    - Sistema completo de playlist de respaldo pendiente

- [ ] **Sistema de Fallback**
  - Playlist de respaldo automática
  - Activación automática en caso de error
  - Notificaciones de fallos

- [ ] **Auto-Mix Inteligente**
  - **Descripción**: Sistema avanzado de mezcla automática que analiza características musicales de las canciones para crear transiciones perfectas y profesionales entre tracks.
  
  - **Componentes Técnicos**:
    - **Detección de BPM**: Ya implementado. Análisis automático del tempo de cada canción.
    - **Detección de Clave Musical**: Análisis espectral para identificar la tonalidad (C, D, E, etc. y modo mayor/menor).
    - **Análisis de Energía**: Cálculo de niveles de energía por secciones (intro, build, drop, outro).
    - **Análisis Espectral**: FFT para identificar frecuencias dominantes y características espectrales.
    - **Sistema de Scoring**: Algoritmo que calcula compatibilidad entre canciones basado en múltiples factores.
  
  - **Algoritmo de Matching**:
    - **BPM Matching**: 
      - Compatibilidad perfecta: ±0 BPM (mismo tempo)
      - Compatibilidad alta: ±5 BPM (ajuste automático de velocidad)
      - Compatibilidad media: ±10 BPM (ajuste con variación)
      - Ajuste automático de `playbackRate` para sincronización
    - **Harmonic Mixing (Camelot Wheel)**:
      - Detección de clave musical (ej: A minor, C major)
      - Conversión a sistema Camelot (1A-12B)
      - Compatibilidad: misma clave, +1/-1, o +7/-7 (relaciones armónicas)
    - **Energy Matching**:
      - Análisis de energía promedio de la canción
      - Transiciones suaves: bajo→medio→alto
      - Evitar saltos abruptos de energía
    - **Genre/Style Matching**:
      - Análisis de características espectrales
      - Matching por género musical
      - Compatibilidad de estilo (house, techno, pop, etc.)
  
  - **Sistema de Sugerencias**:
    - Cálculo de score de compatibilidad para cada canción disponible
    - Filtrado por reglas (no repetir artista, género, etc.)
    - Ranking de mejores opciones
    - Visualización de compatibilidad en UI (indicadores de color/score)
    - Auto-selección de mejor opción cuando está habilitado
  
  - **Transiciones Automáticas**:
    - **Ajuste de BPM**: Sincronización automática de tempos durante crossfade
      - Calcular diferencia de BPM entre canciones
      - Ajustar velocidad de siguiente canción gradualmente
      - Mantener sincronización durante crossfade
      - Restaurar velocidad normal después de transición
    - **Duración Óptima de Crossfade**:
      - Basada en compatibilidad de BPM (más largo si hay ajuste)
      - Basada en puntos de transición detectados
      - Mínimo: 3 segundos, Máximo: 8 segundos
    - **Puntos de Transición**:
      - Detección automática de intros/outros
      - Transición en puntos de menor energía
      - Evitar cortes en medio de frases musicales
  
  - **Implementación Técnica**:
    ```swift
    // Estructura de compatibilidad
    struct SongCompatibility {
        let song: Song
        let bpmMatch: Double          // Diferencia en BPM (0 = perfecto)
        let keyMatch: Bool            // Claves compatibles armónicamente
        let energyMatch: Double       // Compatibilidad de energía (0-1)
        let genreMatch: Double        // Similaridad de género (0-1)
        let transitionScore: Double   // Score total de transición
        let totalScore: Double        // Score final de compatibilidad
    }
    
    // Algoritmo de matching
    func findBestNextSong(from currentSong: Song, 
                          in playlist: Playlist,
                          rules: MixingRules) -> SongCompatibility? {
        // 1. Analizar canción actual
        let currentAnalysis = analyzeSong(currentSong)
        
        // 2. Calcular compatibilidad con todas las canciones
        let compatibilities = playlist.songs
            .filter { rules.allows($0) } // Aplicar reglas
            .map { song in
                calculateCompatibility(
                    current: currentAnalysis,
                    candidate: analyzeSong(song)
                )
            }
        
        // 3. Retornar mejor opción
        return compatibilities.max(by: { $0.totalScore < $1.totalScore })
    }
    
    // Transición automática
    func autoMixTransition(from: Song, to: Song) {
        let bpmDiff = to.bpm - from.bpm
        let targetRate = 1.0 + (bpmDiff / from.bpm)
        
        // Ajustar velocidad gradualmente durante crossfade
        adjustPlaybackRate(to: targetRate, duration: crossfadeDuration)
        applyCrossfade(duration: optimalCrossfadeDuration)
        restorePlaybackRate(after: crossfadeDuration)
    }
    ```
  
  - **Detección de Clave Musical**: ✅ **IMPLEMENTADO**
    - ✅ **Método 1**: Análisis de distribución de notas (chromagram) - Implementado
    - ✅ Algoritmo Krumhansl-Schmuckler para identificación de clave
    - ✅ Conversión automática a sistema Camelot Wheel (1A-12B)
    - ✅ Detección de modo mayor/menor
    - ✅ Visualización en UI junto al BPM
    - ✅ Análisis automático al cargar canción (junto con BPM)
    - ❌ Almacenar clave en metadata de cada canción (pendiente - cache)
    - ❌ **Método 2**: Análisis de acordes dominantes (pendiente)
    - ❌ **Método 3**: Uso de librerías especializadas (librosa, Essentia) (pendiente)
  
  - **Configuración y Control**:
    - Toggle para activar/desactivar auto-mix
    - Nivel de agresividad (conservador, medio, agresivo)
    - Reglas personalizables de matching
    - Override manual cuando sea necesario
    - Visualización de sugerencias en tiempo real
  
  - **Casos de Uso**:
    - **DJ Automático**: Selección automática de siguiente canción
    - **Asistente de DJ**: Sugerencias mientras el DJ elige manualmente
    - **Radio Automatizada**: Transiciones perfectas sin intervención
    - **Preparación de Sets**: Generar playlists con transiciones optimizadas
  
  - **Beneficios**:
    - Transiciones profesionales y suaves
    - Mejor flujo musical continuo
    - Reducción de trabajo manual
    - Experiencia de escucha más coherente
    - Menos errores en transiciones
    - Posibilidad de operación 24/7 sin DJ
  
  - **Estado Actual**:
    - ✅ Detección de BPM implementada
    - ✅ Sistema de crossfade implementado
    - ✅ Análisis de energía básico
    - ✅ Precarga de archivos
    - ✅ **Detección de clave musical (Camelot Wheel) - IMPLEMENTADO**
      - Análisis cromático (chromagram) para detectar tonalidad
      - Algoritmo Krumhansl-Schmuckler para identificación de clave
      - Conversión automática a sistema Camelot (1A-12B)
      - Visualización de clave junto al BPM en la UI
      - Detección de modo mayor/menor
    - ✅ **Mejora en detección de beats en tiempo real - IMPLEMENTADO**
      - Spectral Flux para detectar cambios espectrales
      - High-Frequency Content (HFC) para percusión
      - Detección combinada multi-método
      - Parámetros configurables (pesos, activación/desactivación)
    - ✅ **Precarga y scheduling mejorado - IMPLEMENTADO**
      - Precarga automática cuando se marca canción como "next"
      - Scheduling inmediato en playerNode
      - Visualización de duración de siguiente canción
      - Panel "NEXT:" en la UI mostrando información
    - ❌ Algoritmo de matching (pendiente)
    - ❌ Ajuste automático de BPM (pendiente)
    - ❌ Sistema de sugerencias (pendiente)
  
  - **Complejidad de Implementación**: Media-Alta
  - **Tiempo Estimado**: 2-4 semanas de desarrollo
  - **Dependencias Potenciales**: 
    - Librerías de análisis de audio (librosa wrapper, Essentia, o implementación propia)
    - Algoritmos de FFT para análisis espectral
    - Base de datos para almacenar análisis de canciones

### 4. Interfaz y Visualización

- [ ] **Vista de Timeline**
  - Timeline visual de la programación
  - Vista de día/semana/mes
  - Drag & drop en timeline
  - Visualización de bloques de contenido

- [ ] **Dashboard de Control**
  - Vista general del estado de ambos players
  - Indicadores de estado en tiempo real
  - Alertas y notificaciones
  - Métricas de reproducción

- [ ] **Vista de Logs**
  - Log de reproducción completo
  - Historial de comandos ejecutados
  - Log de errores y advertencias
  - Exportación de logs

- [ ] **Temas Personalizables**
  - Temas claros/oscuros
  - Personalización de colores
  - Modo estudio (colores oscuros, menos distracciones)

### 5. Integración y Conectividad

- [ ] **API REST**
  - API para control remoto
  - Endpoints para agregar canciones
  - Endpoints para control de reproducción
  - Webhooks para eventos

- [ ] **Integración con Streaming**
  - Salida a servidores de streaming (Icecast, Shoutcast)
  - Encoding en tiempo real
  - Múltiples streams simultáneos
  - Metadata en stream (Now Playing)

- [ ] **Integración con Redes Sociales**
  - Publicación automática de "Now Playing" en Twitter/X
  - Integración con Facebook
  - Integración con Instagram Stories
  - Hashtags automáticos

- [ ] **Sistema de Notificaciones**
  - Notificaciones push para eventos importantes
  - Alertas de programación
  - Notificaciones de errores

### 6. Grabación y Archivo

- [ ] **Grabación de Programas**
  - Grabación automática de programas completos
  - Grabación manual
  - Formatos múltiples (MP3, WAV, FLAC)
  - Metadata automática en archivos grabados

- [ ] **Archivo de Contenido**
  - Almacenamiento de programas grabados
  - Sistema de búsqueda en archivo
  - Reproducción de archivos históricos
  - Exportación de programas

### 7. Análisis y Reportes

- [ ] **Estadísticas de Reproducción**
  - Canciones más reproducidas
  - Horas pico de audiencia
  - Análisis de rotación
  - Tiempo de aire por artista/género

- [ ] **Reportes Automáticos**
  - Reportes diarios/semanales/mensuales
  - Reportes de publicidad reproducida
  - Reportes de cumplimiento de programación
  - Exportación a PDF/Excel

- [ ] **Análisis de Audiencia**
  - Tracking de picos de audiencia
  - Análisis de preferencias musicales
  - Identificación de tendencias

### 8. Seguridad y Control de Acceso

- [ ] **Sistema de Usuarios**
  - Múltiples usuarios con diferentes permisos
  - Roles (Administrador, Operador, Editor)
  - Autenticación y autorización

- [ ] **Control de Acceso**
  - Permisos por funcionalidad
  - Logs de acciones de usuarios
  - Bloqueo de funciones críticas

- [ ] **Backup y Restauración**
  - Backup automático de configuraciones
  - Backup de playlists y programación
  - Restauración de backups
  - Sincronización en la nube

### 9. Mejoras de Audio

- [ ] **Normalización de Audio**
  - Normalización automática de niveles
  - Loudness normalization (LUFS)
  - Prevención de clipping

- [ ] **Procesamiento Avanzado**
  - Noise reduction
  - De-esser
  - Gate automático
  - Limiter avanzado

- [ ] **Efectos Adicionales**
  - Chorus
  - Flanger
  - Phaser
  - Distortion (para efectos especiales)

- [x] **Mejoras de Detección**
  - ✅ Detección de clave musical (Camelot Wheel) - **IMPLEMENTADO**
  - ✅ Detección de beats mejorada (Spectral Flux + HFC) - **IMPLEMENTADO**
  - ❌ Detección de género automática (pendiente)
  - ✅ Análisis de energía espectral (implementado en beat detection)
  - ❌ Detección de intros/outros automática (pendiente)

### 10. Automatización de Transiciones

- [ ] **Transiciones Inteligentes**
  - Transiciones basadas en BPM
  - Transiciones basadas en clave musical
  - Transiciones basadas en energía
  - Sugerencias automáticas de transiciones

- [ ] **Sistema de Cue Points**
  - Marcadores de inicio/fin automáticos
  - Cue points manuales
  - Auto-fade en cue points
  - Loops en cue points

- [ ] **Hot Cues**
  - Hot cues para saltos rápidos
  - Hot cues para loops
  - Hot cues para samples

### 11. Gestión de Múltiples Estaciones

- [ ] **Múltiples Estaciones**
  - Gestión de múltiples estaciones desde una sola aplicación
  - Cambio rápido entre estaciones
  - Configuraciones independientes por estación

- [ ] **Sincronización entre Estaciones**
  - Sincronización de contenido
  - Sincronización de programación
  - Compartir playlists entre estaciones

### 12. Mejoras de Playlist

- [ ] **Playlists Inteligentes**
  - Generación automática de playlists
  - Playlists basadas en reglas
  - Playlists dinámicas
  - Sugerencias de canciones

- [ ] **Gestión Avanzada**
  - Duplicados de playlists
  - Exportación/importación de playlists
  - Compartir playlists
  - Versionado de playlists

- [ ] **Filtros y Búsqueda**
  - Filtros avanzados (género, año, BPM, duración)
  - Búsqueda en tiempo real
  - Búsqueda por metadata
  - Búsqueda por tags

### 13. Integración con Hardware

- [ ] **Controladores MIDI**
  - Soporte para controladores MIDI
  - Mapeo de controles
  - Feedback visual en controladores

- [ ] **Interfaces de Audio Externas**
  - Soporte para múltiples interfaces
  - Routing avanzado
  - Monitoreo de salidas

- [ ] **Hardware de Transmisión**
  - Integración con consolas de radio
  - Control de transmisores
  - Monitoreo de señal

### 14. Mejoras de Rendimiento

- [x] **Optimización**
  - ✅ Precarga optimizada - **IMPLEMENTADO**
    - Precarga automática cuando se marca canción como "next"
    - Scheduling inmediato en playerNode
    - Visualización de información de siguiente canción
  - ❌ Caché inteligente de archivos (pendiente)
  - ❌ Reducción de uso de memoria (pendiente)
  - ❌ Optimización de CPU (pendiente)

- [ ] **Escalabilidad**
  - Soporte para playlists muy grandes
  - Optimización de búsquedas
  - Indexación de metadata

### 15. Funcionalidades de Red

- [ ] **Sincronización en Red**
  - Sincronización entre múltiples instancias
  - Control remoto desde otras máquinas
  - Compartir estado entre estaciones

- [ ] **Streaming de Control**
  - Control remoto vía web
  - Interfaz web para monitoreo
  - API para aplicaciones móviles

### 16. Mejoras de Usabilidad

- [ ] **Atajos de Teclado**
  - Atajos personalizables
  - Atajos para funciones frecuentes
  - Modos de atajos (normal, edición, etc.)

- [ ] **Gestos y Controles Táctiles**
  - Soporte para trackpad gestures
  - Controles táctiles en pantallas táctiles
  - Gestos personalizables

- [ ] **Personalización de UI**
  - Layouts personalizables
  - Paneles redimensionables
  - Vistas personalizables
  - Widgets configurables

### 17. Sistema de Alertas

- [ ] **Alertas Inteligentes**
  - Alertas de programación
  - Alertas de errores
  - Alertas de bajo contenido
  - Alertas de problemas técnicos

- [ ] **Notificaciones**
  - Notificaciones del sistema
  - Notificaciones push
  - Notificaciones por email
  - Notificaciones por SMS

### 18. Mejoras de Metadata

- [ ] **Enriquecimiento de Metadata**
  - Búsqueda automática de metadata online
  - Actualización de metadata
  - Corrección automática de metadata
  - Metadata extendida (letras, biografías, etc.)

- [ ] **Gestión de Imágenes**
  - Carátulas de álbumes
  - Imágenes de artistas
  - Visualización en interfaz
  - Búsqueda automática de imágenes

### 19. Funcionalidades de Comunicación

- [ ] **Sistema de Mensajería**
  - Mensajes entre operadores
  - Notas en canciones
  - Comentarios en programación

- [ ] **Chat en Vivo**
  - Chat entre operadores
  - Chat con oyentes (si se integra con web)
  - Moderación de chat

### 20. Mejoras de Automatización

- [ ] **Scripts Personalizados**
  - Sistema de scripting
  - Scripts para automatización compleja
  - API para scripts

- [ ] **Integración con Calendarios**
  - Sincronización con calendarios
  - Eventos especiales
  - Programación basada en eventos

- [ ] **Machine Learning**
  - Predicción de preferencias
  - Optimización automática de playlists
  - Detección de patrones
  - Recomendaciones inteligentes

## Priorización Sugerida

### Fase 1 - Fundamentos de Radio (Alta Prioridad)
1. Sistema de Programación por Horarios
2. Base de Datos de Canciones con Metadata
3. Gestión de Publicidad y Breaks
4. Vista de Timeline
5. Sistema de Reglas Básico

### Fase 2 - Automatización (Media-Alta Prioridad)
6. Motor de Reglas Avanzado
7. Auto-Mix Inteligente
8. Sistema de Fallback
9. Integración con Streaming
10. Grabación de Programas

### Fase 3 - Integración y Análisis (Media Prioridad)
11. API REST
12. Integración con Redes Sociales
13. Análisis y Reportes
14. Sistema de Usuarios y Permisos
15. Backup y Restauración

### Fase 4 - Mejoras Avanzadas (Baja-Media Prioridad)
16. Normalización de Audio Avanzada
17. Controladores MIDI
18. Machine Learning
19. Múltiples Estaciones
20. Funcionalidades de Red Avanzadas

## Notas de Implementación

- Cada funcionalidad debe ser modular y opcional
- Mantener compatibilidad con la funcionalidad existente
- Priorizar estabilidad y rendimiento
- Documentar todas las nuevas funcionalidades
- Probar exhaustivamente antes de release

## Consideraciones Técnicas

- **Base de Datos**: Considerar Core Data o SQLite para metadata
- **Networking**: Usar URLSession para API REST
- **Streaming**: Integrar librerías como libshout o similar
- **Machine Learning**: Usar Core ML para análisis
- **Performance**: Optimizar para uso 24/7 sin interrupciones

## ✅ Mejoras Implementadas Recientemente

### Detección de Clave Musical (Camelot Wheel)
- ✅ Análisis cromático (chromagram) para detectar tonalidad
- ✅ Algoritmo Krumhansl-Schmuckler para identificación de clave
- ✅ Conversión automática a sistema Camelot (1A-12B)
- ✅ Visualización de clave junto al BPM en la UI
- ✅ Detección de modo mayor/menor
- ✅ Análisis automático al cargar canción

### Mejora en Detección de Beats en Tiempo Real
- ✅ Spectral Flux para detectar cambios espectrales
- ✅ High-Frequency Content (HFC) para percusión
- ✅ Detección combinada multi-método
- ✅ Parámetros configurables (pesos, activación/desactivación)
- ✅ Optimizado para tiempo real con análisis por bandas de frecuencia

### Precarga y Scheduling Mejorado
- ✅ Precarga automática cuando se marca canción como "next"
- ✅ Scheduling inmediato en playerNode (incluso durante reproducción)
- ✅ Visualización de duración de siguiente canción
- ✅ Panel "NEXT:" en la UI mostrando información completa
- ✅ Limpieza automática de recursos cuando se desmarca

### Detección Automática de Silencios
- ✅ Detección en tiempo real de silencios en audio
- ✅ Monitoreo continuo del nivel RMS
- ✅ Umbral configurable para detectar silencio (0.001 - 0.1)
- ✅ Duración configurable antes de actuar (1.0 - 10.0 segundos)
- ✅ Rastreo de duración de silencios
- ✅ Auto-stop cuando el silencio excede duración configurada
- ✅ Opción para avanzar a siguiente canción en silencio
- ✅ Estado de silencio visible en tiempo real
- ✅ **Configuración completa en UI** - Sección dedicada en ConfigView
  - Toggle para activar/desactivar detección
  - Sliders para umbral y duración
  - Toggles para acciones (auto-stop o avanzar)
  - Indicador visual de estado (silencioso/audio detectado)
  - Duración actual de silencio mostrada en tiempo real
- ⚠️ Sistema completo de playlist de respaldo (pendiente)

