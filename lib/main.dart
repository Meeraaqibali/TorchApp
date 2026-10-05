import 'package:flutter/material.dart';
import 'package:torch_light/torch_light.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:async';

void main() {
  runApp(const TorchApp());
}

class TorchApp extends StatelessWidget {
  const TorchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Torch Pro',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        primaryColor: const Color(0xFFFFD700),
      ),
      home: const TorchHomePage(),
    );
  }
}

class TorchHomePage extends StatefulWidget {
  const TorchHomePage({super.key});

  @override
  State<TorchHomePage> createState() => _TorchHomePageState();
}

class _TorchHomePageState extends State<TorchHomePage> {
  bool _isTorchOn = false;
  double _brightness = 1.0;
  bool _isBlinking = false;
  Timer? _blinkTimer;
  int _blinkSpeedMs = 300;
  String _activeMode = 'flashlight'; // 'flashlight', 'screen', 'blink'

  @override
  void dispose() {
    _blinkTimer?.cancel();
    TorchLight.disableTorch();
    ScreenBrightness().resetScreenBrightness();
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> _toggleTorch() async {
    try {
      if (_isTorchOn) {
        await TorchLight.disableTorch();
        setState(() => _isTorchOn = false);
      } else {
        await TorchLight.enableTorch();
        setState(() => _isTorchOn = true);
      }
    } catch (e) {
      _showError('Flashlight not supported on this device.');
    }
  }

  Future<void> _changeBrightness(double value) async {
    setState(() => _brightness = value);
    try {
      await ScreenBrightness().setScreenBrightness(value);
    } catch (e) {
      _showError('Cannot change screen brightness.');
    }
  }

  void _toggleBlink() {
    if (_isBlinking) {
      _blinkTimer?.cancel();
      setState(() => _isBlinking = false);
      TorchLight.disableTorch();
    } else {
      setState(() => _isBlinking = true);
      _blinkTimer = Timer.periodic(Duration(milliseconds: _blinkSpeedMs), (timer) async {
        try {
          if (_isTorchOn) {
            await TorchLight.disableTorch();
            setState(() => _isTorchOn = false);
          } else {
            await TorchLight.enableTorch();
            setState(() => _isTorchOn = true);
          }
        } catch (e) {
          _blinkTimer?.cancel();
          setState(() => _isBlinking = false);
        }
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚡ Torch Pro', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Mode Selector
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildModeButton('Flashlight', 'flashlight'),
                _buildModeButton('Screen', 'screen'),
                _buildModeButton('Blink', 'blink'),
              ],
            ),
          ),
          Expanded(
            child: _activeMode == 'flashlight'
                ? _buildFlashlightMode()
                : _activeMode == 'screen'
                    ? _buildScreenMode()
                    : _buildBlinkMode(),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(String title, String mode) {
    bool isActive = _activeMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() => _activeMode = mode);
        if (mode != 'blink' && _isBlinking) _toggleBlink();
        if (mode != 'flashlight' && _isTorchOn && !_isBlinking) _toggleTorch();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFFD700) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? const Color(0xFFFFD700) : Colors.grey),
        ),
        child: Text(title, style: TextStyle(color: isActive ? Colors.black : Colors.grey, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildFlashlightMode() {
    return Center(
      child: GestureDetector(
        onTap: _toggleTorch,
        child: Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1A1A1A),
            border: Border.all(color: _isTorchOn ? const Color(0xFFFFD700) : Colors.grey, width: 4),
            boxShadow: _isTorchOn ? [BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.5), blurRadius: 30)] : [],
          ),
          child: Center(
            child: Icon(Icons.power_settings_new, size: 80, color: _isTorchOn ? const Color(0xFFFFD700) : Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildScreenMode() {
    WakelockPlus.enable(); // Keep screen on
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Screen Light', style: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 40),
          Slider(
            value: _brightness,
            min: 0.1,
            max: 1.0,
            activeColor: const Color(0xFFFFD700),
            onChanged: _changeBrightness,
          ),
          Text('${(_brightness * 100).toInt()}%', style: const TextStyle(color: Colors.black, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildBlinkMode() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _toggleBlink,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1A1A1A),
                border: Border.all(color: _isBlinking ? const Color(0xFFFFD700) : Colors.grey, width: 4),
              ),
              child: Center(
                child: Icon(_isBlinking ? Icons.stop : Icons.flash_on, size: 60, color: _isBlinking ? Colors.redAccent : const Color(0xFFFFD700)),
              ),
            ),
          ),
          const SizedBox(height: 30),
          const Text('Blink Speed', style: TextStyle(color: Colors.white, fontSize: 16)),
          Slider(
            value: _blinkSpeedMs.toDouble(),
            min: 50,
            max: 1000,
            divisions: 19,
            activeColor: const Color(0xFFFFD700),
            onChanged: (val) {
              setState(() => _blinkSpeedMs = val.toInt());
              if (_isBlinking) {
                _toggleBlink();
                _toggleBlink();
              }
            },
          ),
          Text('${_blinkSpeedMs}ms', style: const TextStyle(color: Color(0xFFFFD700))),
        ],
      ),
    );
  }
}
