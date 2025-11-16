# AVAudioEngine - Capacidades y Posibilidades Técnicas

Este documento detalla todas las capacidades de AVAudioEngine y cómo pueden ser utilizadas en Musica Player para expandir funcionalidades de audio profesional.

## 📚 Tabla de Contenidos

1. [Introducción a AVAudioEngine](#introducción)
2. [Componentes Principales](#componentes-principales)
3. [Nodos de Audio Disponibles](#nodos-de-audio)
4. [Efectos de Audio](#efectos-de-audio)
5. [Procesamiento en Tiempo Real](#procesamiento-tiempo-real)
6. [Análisis de Audio](#análisis-de-audio)
7. [Grabación y Renderizado](#grabación-y-renderizado)
8. [Routing y Conectividad](#routing-y-conectividad)
9. [Sincronización y Timing](#sincronización)
10. [Casos de Uso Avanzados](#casos-de-uso)
11. [Implementación en Musica Player](#implementación-actual)

---

## Introducción

`AVAudioEngine` es el framework de bajo nivel de Apple para procesamiento de audio en tiempo real. Permite construir grafos de audio complejos con múltiples nodos, efectos, y procesamiento personalizado.

### Características Principales

- **Procesamiento en Tiempo Real**: Latencia ultra-baja para aplicaciones profesionales
- **Grafos de Audio Modulares**: Conectar múltiples nodos de forma flexible
- **Efectos Integrados**: Acceso a efectos de audio profesionales
- **Análisis de Audio**: Tap nodes para análisis en tiempo real
- **Multi-canal**: Soporte para mono, estéreo, y configuraciones surround
- **Sincronización Precisa**: Control de timing a nivel de sample

---

## Componentes Principales

### AVAudioEngine

El motor principal que gestiona el grafo de audio.

```swift
let audioEngine = AVAudioEngine()

// Configuración básica
audioEngine.attach(node)        // Agregar nodo al engine
audioEngine.connect(node1, to: node2, format: format)  // Conectar nodos
audioEngine.start()              // Iniciar el engine
audioEngine.stop()               // Detener el engine
audioEngine.pause()              // Pausar el engine
```

**Propiedades Clave:**
- `mainMixerNode`: Nodo mezclador principal (siempre disponible)
- `inputNode`: Nodo de entrada (micrófono/line-in)
- `outputNode`: Nodo de salida (altavoces/auriculares)

### AVAudioNode

Clase base para todos los nodos de audio.

**Tipos de Nodos:**
- **Source Nodes**: Generan audio (player, input)
- **Processing Nodes**: Procesan audio (effects, mixers)
- **Destination Nodes**: Reciben audio (output, recording)

---

## Nodos de Audio Disponibles

### 1. AVAudioPlayerNode

Reproduce archivos de audio con control preciso.

```swift
let playerNode = AVAudioPlayerNode()
audioEngine.attach(playerNode)

// Cargar archivo
let audioFile = try AVAudioFile(forReading: url)

// Reproducir
playerNode.scheduleFile(audioFile, at: nil) { /* completion */ }
playerNode.play()

// Control preciso
playerNode.pause()
playerNode.stop()
playerNode.seek(to: AVAudioTime)
```

**Capacidades:**
- ✅ Reproducción de archivos de audio
- ✅ Control de timing preciso (sample-accurate)
- ✅ Scheduling de múltiples archivos
- ✅ Loop y segmentos específicos
- ✅ Control de velocidad (con AVAudioUnitVarispeed)
- ✅ Control de pitch (con AVAudioUnitTimePitch)

**Uso en Musica Player:**
- ✅ Implementado para reproducción básica
- ⚠️ Podría expandirse con scheduling avanzado
- ⚠️ Podría agregar loops y segmentos

### 2. AVAudioMixerNode

Mezcla múltiples fuentes de audio.

```swift
let mixerNode = AVAudioMixerNode()
audioEngine.attach(mixerNode)

// Conectar múltiples fuentes
audioEngine.connect(player1, to: mixerNode, format: format)
audioEngine.connect(player2, to: mixerNode, format: format)

// Control de volumen por canal
mixerNode.volume = 0.8
mixerNode.pan = -0.5  // Balance estéreo
```

**Capacidades:**
- ✅ Mezcla de múltiples fuentes
- ✅ Control de volumen individual
- ✅ Balance estéreo (pan)
- ✅ Tap para análisis (usado en Musica Player para VU meters)

**Uso en Musica Player:**
- ✅ Implementado para mezcla principal
- ✅ Usado para VU meters (tap en mainMixerNode)
- ⚠️ Podría usarse para mezclar múltiples players

### 3. AVAudioInputNode

Captura audio de entrada (micrófono, line-in).

```swift
let inputNode = audioEngine.inputNode
let inputFormat = inputNode.inputFormat(forBus: 0)

// Instalar tap para capturar audio
inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { buffer, time in
    // Procesar audio de entrada
}
```

**Capacidades:**
- ✅ Captura de micrófono
- ✅ Captura de line-in
- ✅ Múltiples canales de entrada
- ✅ Análisis de audio de entrada en tiempo real

**Uso Potencial:**
- ⚠️ Grabación de voz en vivo
- ⚠️ Efectos en voz (talk-over)
- ⚠️ Análisis de audio de entrada
- ⚠️ Mixing de voz con música

### 4. AVAudioOutputNode

Salida de audio al sistema.

```swift
let outputNode = audioEngine.outputNode
let outputFormat = outputNode.outputFormat(forBus: 0)

// El outputNode es automático cuando se inicia el engine
audioEngine.connect(mixerNode, to: outputNode, format: outputFormat)
```

**Capacidades:**
- ✅ Salida a altavoces/auriculares
- ✅ Soporte para múltiples dispositivos de salida
- ✅ AirPlay automático (en macOS)
- ✅ Cambio dinámico de dispositivo de salida

---

## Efectos de Audio

### Efectos Disponibles en AVFoundation

#### 1. AVAudioUnitEQ (Ecualizador)

Ecualizador paramétrico con múltiples bandas.

```swift
let eqUnit = AVAudioUnitEQ(numberOfBands: 10)
audioEngine.attach(eqUnit)

// Configurar bandas
let band = eqUnit.bands[0]
band.frequency = 1000.0      // Hz
band.gain = 3.0              // dB
band.bandwidth = 1.0         // Octavas
band.filterType = .parametric

// Tipos de filtro disponibles:
// - .parametric
// - .lowPass
// - .highPass
// - .lowShelf
// - .highShelf
// - .resonantLowPass
// - .resonantHighPass
```

**Capacidades:**
- ✅ Hasta 20 bandas de ecualización
- ✅ Múltiples tipos de filtro por banda
- ✅ Control de frecuencia, ganancia, y ancho de banda
- ✅ Bypass individual por banda

**Uso en Musica Player:**
- ⚠️ Actualmente solo 3 bandas (low, mid, high)
- ⚠️ Podría expandirse a ecualizador paramétrico completo

#### 2. AVAudioUnitReverb (Reverb)

Reverb con múltiples presets.

```swift
let reverbUnit = AVAudioUnitReverb()
audioEngine.attach(reverbUnit)

// Presets disponibles
reverbUnit.loadFactoryPreset(.cathedral)
reverbUnit.loadFactoryPreset(.largeHall)
reverbUnit.loadFactoryPreset(.mediumHall)
reverbUnit.loadFactoryPreset(.smallHall)
reverbUnit.loadFactoryPreset(.largeRoom)
reverbUnit.loadFactoryPreset(.mediumRoom)
reverbUnit.loadFactoryPreset(.smallRoom)
reverbUnit.loadFactoryPreset(.plate)
reverbUnit.loadFactoryPreset(.mediumChamber)
reverbUnit.loadFactoryPreset(.largeChamber)

// Control de wet/dry mix
reverbUnit.wetDryMix = 50.0  // 0-100%
```

**Capacidades:**
- ✅ 11 presets profesionales
- ✅ Control de wet/dry mix
- ✅ Bypass

**Uso en Musica Player:**
- ✅ Implementado con presets y wet/dry mix

#### 3. AVAudioUnitDelay (Delay/Echo)

Delay con control completo.

```swift
let delayUnit = AVAudioUnitDelay()
audioEngine.attach(delayUnit)

delayUnit.delayTime = 0.25        // segundos (0-2)
delayUnit.feedback = 30.0        // 0-100%
delayUnit.lowPassCutoff = 15000  // Hz
delayUnit.wetDryMix = 20.0       // 0-100%
```

**Capacidades:**
- ✅ Control de tiempo de delay (0-2 segundos)
- ✅ Feedback (0-100%)
- ✅ Low-pass filter en feedback
- ✅ Wet/dry mix

**Uso en Musica Player:**
- ✅ Implementado con todos los controles

#### 4. AVAudioUnitDistortion (Distorsión)

Distorsión con múltiples presets.

```swift
let distortionUnit = AVAudioUnitDistortion()
audioEngine.attach(distortionUnit)

// Presets disponibles
distortionUnit.loadFactoryPreset(.drumsBitBrush)
distortionUnit.loadFactoryPreset(.drumsBufferBeats)
distortionUnit.loadFactoryPreset(.drumsLoFi)
distortionUnit.loadFactoryPreset(.multiBrokenSpeaker)
distortionUnit.loadFactoryPreset(.multiCellphoneConcert)
distortionUnit.loadFactoryPreset(.multiDecimated1)
distortionUnit.loadFactoryPreset(.multiDecimated2)
distortionUnit.loadFactoryPreset(.multiDecimated3)
distortionUnit.loadFactoryPreset(.multiDecimated4)
distortionUnit.loadFactoryPreset(.multiDistortedCubed)
distortionUnit.loadFactoryPreset(.multiDistortedFunk)
distortionUnit.loadFactoryPreset(.multiDistortedSquared)
distortionUnit.loadFactoryPreset(.multiEcho1)
distortionUnit.loadFactoryPreset(.multiEcho2)
distortionUnit.loadFactoryPreset(.multiEchoTight1)
distortionUnit.loadFactoryPreset(.multiEchoTight2)
distortionUnit.loadFactoryPreset(.multiEverythingIsBroken)
distortionUnit.loadFactoryPreset(.speakerPhone)

// Control de pre-gain y wet/dry
distortionUnit.preGain = -6.0     // dB
distortionUnit.wetDryMix = 50.0   // 0-100%
```

**Capacidades:**
- ✅ 21 presets de distorsión
- ✅ Control de pre-gain
- ✅ Wet/dry mix

**Uso Potencial:**
- ⚠️ Efectos especiales para radio
- ⚠️ Efectos creativos

#### 5. AVAudioUnitTimePitch (Time/Pitch Shifting)

Cambio de velocidad y pitch independientes.

```swift
let timePitchUnit = AVAudioUnitTimePitch()
audioEngine.attach(timePitchUnit)

timePitchUnit.rate = 1.0        // Velocidad (0.25-4.0)
timePitchUnit.pitch = 0.0       // Pitch en cents (-2400 a +2400)
timePitchUnit.overlap = 8.0     // Overlap para mejor calidad
```

**Capacidades:**
- ✅ Cambio de velocidad sin cambiar pitch
- ✅ Cambio de pitch sin cambiar velocidad
- ✅ Control de overlap para calidad
- ✅ Muy útil para sincronización de BPM

**Uso en Musica Player:**
- ⚠️ Actualmente usa AVAudioUnitVarispeed (solo velocidad)
- ⚠️ Podría cambiarse a TimePitch para mejor control
- ⚠️ Ideal para auto-mix con ajuste de BPM

#### 6. AVAudioUnitVarispeed (Speed Control)

Control de velocidad de reproducción.

```swift
let varispeedUnit = AVAudioUnitVarispeed()
audioEngine.attach(varispeedUnit)

varispeedUnit.rate = 1.0  // 0.25-4.0 (velocidad)
```

**Capacidades:**
- ✅ Control de velocidad
- ⚠️ Cambia pitch al cambiar velocidad

**Uso en Musica Player:**
- ✅ Implementado para playback rate

#### 7. AVAudioUnitEffect (Compresor y otros)

Efectos genéricos y compresor.

```swift
// Compresor (usando AVAudioUnitEffect con subtype)
let compressorUnit = AVAudioUnitEffect(audioComponentDescription: 
    AudioComponentDescription(
        componentType: kAudioUnitType_Effect,
        componentSubType: kAudioUnitSubType_DynamicsProcessor,
        componentManufacturer: kAudioUnitManufacturer_Apple,
        componentFlags: 0,
        componentFlagsMask: 0
    )
)

// Configurar compresor
if let dynamicsProcessor = compressorUnit.auAudioUnit.effectNodes.first {
    // Configurar parámetros del compresor
}
```

**Compresor (Dynamics Processor):**
- ✅ Threshold (dB)
- ✅ Headroom (dB)
- ✅ Expansion Ratio
- ✅ Attack Time
- ✅ Release Time
- ✅ Master Gain

**Uso en Musica Player:**
- ✅ Implementado con Dynamics Processor

#### 8. AVAudioUnitGenerator

Generadores de audio (osciladores, etc.).

```swift
// Ejemplo: Oscilador (requiere implementación personalizada)
class OscillatorNode: AVAudioUnitGenerator {
    // Generar ondas (sine, square, triangle, sawtooth)
}
```

**Capacidades:**
- ✅ Generación de tonos
- ✅ Síntesis de audio
- ⚠️ Requiere implementación personalizada

**Uso Potencial:**
- ⚠️ Tones de prueba
- ⚠️ Generación de señales de prueba
- ⚠️ Síntesis de efectos

---

## Procesamiento en Tiempo Real

### Tap Nodes

Instalar taps en cualquier nodo para análisis o procesamiento.

```swift
// Tap en mixer para análisis
mixerNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, time in
    // Procesar buffer en tiempo real
    let channelData = buffer.floatChannelData
    let frameLength = Int(buffer.frameLength)
    
    // Análisis de audio
    for frame in 0..<frameLength {
        let sample = channelData[0][frame]
        // Procesar sample
    }
}
```

**Capacidades:**
- ✅ Análisis de audio en tiempo real
- ✅ VU meters (implementado en Musica Player)
- ✅ Detección de beats (implementado en Musica Player)
- ✅ Análisis espectral (FFT)
- ✅ Procesamiento personalizado

**Uso en Musica Player:**
- ✅ VU meters
- ✅ Detección de beats
- ⚠️ Podría expandirse para análisis espectral
- ⚠️ Podría usarse para normalización automática

### Custom Audio Units

Crear unidades de procesamiento personalizadas.

```swift
class CustomAudioUnit: AVAudioUnit {
    // Implementar procesamiento personalizado
    override func processBlock(_ buffer: AVAudioPCMBuffer, at time: AVAudioTime) {
        // Procesar buffer
    }
}
```

**Capacidades:**
- ✅ Efectos personalizados
- ✅ Procesamiento específico
- ✅ Algoritmos propietarios

---

## Análisis de Audio

### Análisis Espectral (FFT)

```swift
import Accelerate

func performFFT(on buffer: AVAudioPCMBuffer) -> [Float] {
    let frameLength = Int(buffer.frameLength)
    let log2n = UInt(round(log2(Double(frameLength))))
    let fftSize = 1 << log2n
    
    // Preparar buffers FFT
    var realp = [Float](repeating: 0, count: Int(fftSize/2))
    var imagp = [Float](repeating: 0, count: Int(fftSize/2))
    
    // Realizar FFT
    var fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2))
    
    // Convertir a frecuencia
    var magnitudes = [Float](repeating: 0, count: Int(fftSize/2))
    vDSP_zvmags(&complexBuffer, 1, &magnitudes, 1, vDSP_Length(fftSize/2))
    
    return magnitudes
}
```

**Aplicaciones:**
- ✅ Detección de clave musical
- ✅ Análisis de frecuencias dominantes
- ✅ Visualización espectral
- ✅ Detección de género
- ✅ Análisis de armónicos

### Análisis de Energía

```swift
func calculateRMS(from buffer: AVAudioPCMBuffer) -> Float {
    let channelData = buffer.floatChannelData![0]
    let frameLength = Int(buffer.frameLength)
    
    var sum: Float = 0.0
    vDSP_rmsqv(channelData, 1, &sum, vDSP_Length(frameLength))
    
    return sqrt(sum / Float(frameLength))
}
```

**Aplicaciones:**
- ✅ VU meters (implementado)
- ✅ Normalización automática
- ✅ Detección de silencios
- ✅ Análisis de dinámica

### Análisis de BPM

```swift
// Implementación básica (ya existe en Musica Player)
func detectBPM(from energyValues: [Float], sampleRate: Double) -> Double? {
    // Detectar picos de energía
    // Calcular intervalos entre beats
    // Calcular BPM promedio
}
```

**Mejoras Posibles:**
- ⚠️ Análisis más robusto con autocorrelación
- ⚠️ Detección de cambios de tempo
- ⚠️ Detección de time signature

---

## Grabación y Renderizado

### Grabación a Archivo

```swift
let outputFile = try AVAudioFile(forWriting: outputURL, settings: format.settings)

// Conectar a nodo de grabación
let recordingNode = AVAudioMixerNode()
audioEngine.attach(recordingNode)

// Instalar tap para grabar
recordingNode.installTap(onBus: 0, bufferSize: 4096, format: format) { buffer, time in
    do {
        try outputFile.write(from: buffer)
    } catch {
        print("Error writing to file: \(error)")
    }
}
```

**Capacidades:**
- ✅ Grabación en tiempo real
- ✅ Múltiples formatos (WAV, AIFF, CAF, M4A)
- ✅ Grabación de múltiples canales
- ✅ Grabación con efectos aplicados

**Uso Potencial:**
- ⚠️ Grabación de programas de radio
- ⚠️ Exportación de mixes
- ⚠️ Archivo de transmisiones

### Renderizado Offline

```swift
// Renderizar a archivo sin reproducir
let renderFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, 
                               sampleRate: 44100, 
                               channels: 2, 
                               interleaved: false)!

let outputFile = try AVAudioFile(forWriting: outputURL, settings: renderFormat.settings)

// Renderizar
audioEngine.enableManualRenderingMode(.offline, 
                                      format: renderFormat, 
                                      maximumFrameCount: 4096)

audioEngine.start()
let buffer = AVAudioPCMBuffer(pcmFormat: renderFormat, frameCapacity: 4096)!

while /* más audio para renderizar */ {
    let status = try audioEngine.renderOffline(4096, to: buffer)
    try outputFile.write(from: buffer)
}
```

**Capacidades:**
- ✅ Renderizado más rápido que tiempo real
- ✅ Procesamiento batch
- ✅ Exportación de mixes complejos

---

## Routing y Conectividad

### Múltiples Salidas

```swift
// Conectar a múltiples dispositivos de salida
let output1 = AVAudioOutputNode(deviceID: device1ID)
let output2 = AVAudioOutputNode(deviceID: device2ID)

audioEngine.attach(output1)
audioEngine.attach(output2)

audioEngine.connect(mixer, to: output1, format: format)
audioEngine.connect(mixer, to: output2, format: format)
```

**Capacidades:**
- ✅ Múltiples dispositivos de salida
- ✅ Routing personalizado
- ✅ Monitoreo separado

### Submixers

```swift
// Crear submixers para routing complejo
let submixer1 = AVAudioMixerNode()
let submixer2 = AVAudioMixerNode()

audioEngine.attach(submixer1)
audioEngine.attach(submixer2)

// Conectar fuentes a submixers
audioEngine.connect(player1, to: submixer1, format: format)
audioEngine.connect(player2, to: submixer2, format: format)

// Conectar submixers a mixer principal
audioEngine.connect(submixer1, to: mainMixer, format: format)
audioEngine.connect(submixer2, to: mainMixer, format: format)
```

**Capacidades:**
- ✅ Routing complejo
- ✅ Grupos de canales
- ✅ Aplicar efectos a grupos

---

## Sincronización y Timing

### AVAudioTime

Control preciso de timing.

```swift
// Crear tiempo específico
let sampleTime = AVAudioTime(sampleTime: 44100, atRate: 44100)
let hostTime = AVAudioTime(hostTime: mach_absolute_time())

// Scheduling preciso
playerNode.scheduleSegment(audioFile, 
                          startingFrame: 0, 
                          frameCount: 44100, 
                          at: sampleTime)
```

**Capacidades:**
- ✅ Timing sample-accurate
- ✅ Sincronización entre múltiples nodos
- ✅ Scheduling preciso

### Sincronización de Múltiples Players

```swift
// Sincronizar dos players
let syncTime = AVAudioTime(hostTime: mach_absolute_time() + offset)

player1Node.scheduleFile(file1, at: syncTime)
player2Node.scheduleFile(file2, at: syncTime)

// Ambos comenzarán exactamente al mismo tiempo
```

**Aplicaciones:**
- ✅ Crossfade preciso
- ✅ Sincronización de beats
- ✅ Mixing profesional

---

## Casos de Uso Avanzados

### 1. Auto-Mix con Sincronización de BPM

```swift
// Ajustar velocidad de siguiente canción para match BPM
let currentBPM = 128.0
let nextBPM = 130.0
let targetRate = currentBPM / nextBPM  // 0.9846

// Aplicar durante crossfade
timePitchUnit.rate = targetRate
// ... crossfade ...
timePitchUnit.rate = 1.0  // Restaurar después
```

### 2. Normalización Automática

```swift
// Analizar nivel de audio
let currentLevel = calculateRMS(from: buffer)
let targetLevel: Float = 0.7  // -3 dB

// Aplicar ganancia automática
let gain = targetLevel / currentLevel
mixerNode.volume = gain
```

### 3. Detección de Silencios

```swift
let silenceThreshold: Float = 0.01

if currentLevel < silenceThreshold {
    // Detectar silencio
    handleSilence()
}
```

### 4. Talk-Over (Ducking)

```swift
// Reducir música cuando hay voz
if voiceLevel > threshold {
    musicMixer.volume = 0.3  // Duck music
} else {
    musicMixer.volume = 1.0  // Restore music
}
```

### 5. Sidechain Compression

```swift
// Comprimir música basado en nivel de voz
// (Requiere implementación personalizada del compresor)
```

### 6. Looping y Cue Points

```swift
// Loop de segmento específico
let startFrame: AVAudioFramePosition = 44100
let endFrame: AVAudioFramePosition = 88200

playerNode.scheduleSegment(audioFile,
                          startingFrame: startFrame,
                          frameCount: endFrame - startFrame,
                          at: nil) {
    // Loop completado, programar de nuevo
    scheduleLoop()
}
```

---

## Implementación Actual en Musica Player

### ✅ Implementado

1. **AVAudioEngine básico**: Motor de audio funcionando
2. **AVAudioPlayerNode**: Reproducción de archivos
3. **AVAudioMixerNode**: Mezcla principal
4. **AVAudioUnitEQ**: Ecualizador (3 bandas)
5. **AVAudioUnitReverb**: Reverb con presets
6. **AVAudioUnitDelay**: Delay completo
7. **AVAudioUnitVarispeed**: Control de velocidad
8. **AVAudioUnitEffect (Dynamics Processor)**: Compresor
9. **Tap Nodes**: VU meters y detección de beats
10. **Análisis de BPM**: Detección automática
11. **Crossfade**: Transiciones suaves
12. **Fade In/Out**: Fades automáticos

### ⚠️ Posibles Mejoras

1. **AVAudioUnitTimePitch**: Mejor control para auto-mix
2. **Análisis Espectral (FFT)**: Detección de clave musical
3. **Grabación**: Grabación de programas
4. **Múltiples Salidas**: Routing a diferentes dispositivos
5. **Submixers**: Routing más complejo
6. **Normalización Automática**: Ajuste automático de niveles
7. **Detección de Silencios**: Auto-stop en silencios
8. **Talk-Over**: Ducking automático
9. **Looping Avanzado**: Cue points y loops
10. **Renderizado Offline**: Exportación de mixes

---

## Recursos y Referencias

- **Apple Documentation**: [AVAudioEngine](https://developer.apple.com/documentation/avfaudio/avaudioengine)
- **WWDC Sessions**: 
  - "Advanced AVAudioEngine" (WWDC 2015)
  - "What's New in AVAudioEngine" (varios años)
- **Sample Code**: Apple proporciona ejemplos de uso avanzado

---

## Conclusión

AVAudioEngine ofrece capacidades extensas para procesamiento de audio profesional. Musica Player ya utiliza muchas de estas capacidades, pero hay mucho espacio para expansión, especialmente en:

- Auto-mix inteligente con sincronización de BPM
- Análisis avanzado (clave musical, espectro)
- Grabación y archivo
- Normalización y procesamiento automático
- Routing avanzado para múltiples salidas

La arquitectura actual de Musica Player está bien posicionada para agregar estas funcionalidades de manera modular.

