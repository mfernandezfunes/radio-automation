# Estructura de Nodos de Audio

## Player Individual (Player 1 y Player 2)

Cada player tiene su propio `AVAudioEngine` con la siguiente cadena:

```
playerNode (AVAudioPlayerNode)
    ↓
varispeedUnit (AVAudioUnitVarispeed) - Control de velocidad
    ↓
delayUnit (AVAudioUnitDelay) - Efecto de delay
    ↓
reverbUnit (AVAudioUnitReverb) - Efecto de reverb
    ↓
equalizerUnit (AVAudioUnitEQ) - Equalizador del player
    ↓
mixerNode (AVAudioMixerNode) - Balance estéreo + VU Meter Tap ⚡
    ↓
outputEQ (AVAudioUnitEQ) - Equalizador de salida del player
    ↓
mainMixerNode (AVAudioMixerNode) - Volumen Master ⚡
    ↓
[Salida del Engine del Player]
```

### Notas importantes:
- **VU Meter Tap**: Instalado en `mixerNode` (ANTES del volumen master)
  - Esto asegura que los VU meters no se vean afectados por cambios en el volumen master
- **Volumen Master**: Controlado en `mainMixerNode.volume`
- **Balance Estéreo**: Controlado en `mixerNode.pan`

---

## Global Audio Mixer

El `GlobalAudioMixer` tiene su propio `AVAudioEngine` separado:

```
globalMixerNode (AVAudioMixerNode)
    ↓
globalOutputEqualizer (AVAudioUnitEQ) - Equalizador de salida global
    ↓
mainMixerNode (AVAudioMixerNode) - Volumen Master Global + VU Meter Tap ⚡
    ↓
[Salida Final del Sistema]
```

### Notas importantes:
- **VU Meter Global Tap**: Instalado en `mainMixerNode` del engine global
  - Muestra el nivel de salida final después de todo el procesamiento
- **Volumen Master Global**: Controlado en `mainMixerNode.volume` del engine global

---

## Limitación Actual

**IMPORTANTE**: Los players NO están conectados físicamente al `GlobalAudioMixer` porque:
- Cada player tiene su propio `AVAudioEngine`
- No se pueden conectar nodos de diferentes engines directamente
- El `GlobalAudioMixer` tiene su propio engine separado

### Estado Actual:
- ✅ **Volumen Master**: Funciona controlando el `mainMixerNode.volume` de cada player
- ✅ **Balance Estéreo**: Funciona controlando el `mixerNode.pan` de cada player
- ✅ **Equalizador de Salida**: Existe en el engine global pero no recibe audio de los players
- ⚠️ **Mixer Global**: Existe pero no está recibiendo audio de los players

### Solución Actual:
El control global funciona mediante:
1. Referencias a los players (`player1`, `player2`)
2. Métodos `setMasterVolume()` y `setStereoBalance()` que controlan directamente los nodos de cada player
3. Los players mantienen sus engines independientes

---

## Flujo de Audio Real

### Player 1:
```
Audio File → playerNode → varispeed → delay → reverb → eq → mixerNode → outputEQ → mainMixerNode → [Salida]
                                                                         ↑
                                                                   VU Meter Tap
```

### Player 2:
```
Audio File → playerNode → varispeed → delay → reverb → eq → mixerNode → outputEQ → mainMixerNode → [Salida]
                                                                         ↑
                                                                   VU Meter Tap
```

### Control Global:
- **Volumen Master**: Afecta `mainMixerNode.volume` de ambos players
- **Balance Estéreo**: Afecta `mixerNode.pan` de ambos players
- **Equalizador de Salida**: Existe en engine global pero no está conectado a los players

---

## Propiedades de Control

### Por Player:
- `playerNode.volume`: Volumen individual del player (0.0 - 1.0)
- `mixerNode.pan`: Balance estéreo del player (-1.0 a 1.0)
- `mainMixerNode.volume`: Volumen master del player (controlado globalmente)

### Global:
- `GlobalAudioMixer.outputVolume`: Volumen master global (afecta ambos players)
- `GlobalAudioMixer.stereoBalance`: Balance estéreo global (afecta ambos players)
- `GlobalAudioMixer.outputEqualizerEnabled`: Estado del equalizador de salida global

