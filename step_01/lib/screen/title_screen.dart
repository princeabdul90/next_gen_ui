/*
* Developer: Abubakar Abdullahi
* Date: 1/26/2024
* Company: ESAT PILIPINAS TEKNIK, OPC
*/


import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:next_gen_ui/assets.dart';
import 'package:next_gen_ui/orb_shader/orb_shader_config.dart';
import 'package:next_gen_ui/orb_shader/orb_shader_widget.dart';
import 'package:next_gen_ui/screen/title_screen_ui.dart';
import 'package:next_gen_ui/styles.dart';
import 'package:particle_field/particle_field.dart';
import 'package:rnd/rnd.dart';

class TitleScreen extends StatefulWidget {
  const TitleScreen({super.key});

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> with  SingleTickerProviderStateMixin {
  final _orbKey = GlobalKey<OrbShaderWidgetState>();

  /// Editable Settings
  /// 0-1, receive lighting strength
  final  _minReceiveLightAmt = .35;
  final  _maxReceiveLightAmt = .7;

  /// 0-1, emit lighting  strength
  final _minEmitLightAmt = .5;
  final _maxEmitLightAmt = 1;

  /// Internal
  var _mousePos =  Offset.zero;

  Color get _emitColor => AppColors.emitColors[_difficultyOverride ?? _difficulty];
  Color get _orbColor => AppColors.orbColors[_difficultyOverride ?? _difficulty];

  /// Currently selected difficulty
  int _difficulty = 0;

  /// Currently focused difficulty (if  any)
  int? _difficultyOverride;
  double _orbEnergy = 0;
  double _minOrbEnergy = 0;

  double get _finalReceiveLightAmt {
    final light = lerpDouble(_minReceiveLightAmt, _maxReceiveLightAmt, _orbEnergy) ?? 0;
    return light  + _pulseEffect.value * .05  * _orbEnergy;
  }

  double get _finalEmitLightAmt {
    return lerpDouble(_minEmitLightAmt, _maxEmitLightAmt, _orbEnergy) ?? 0;
  }

  late final _pulseEffect = AnimationController(
    vsync: this,
    duration: _getRndPulseDuration(),
    lowerBound: -1,
    upperBound: 1
  );

  Duration _getRndPulseDuration() => 100.ms + 200.ms * Random().nextDouble();

  double _getMinEnergyForDifficulty(int  difficulty) => switch (difficulty){
    1 => 0.3,
    2 => 0.6,
    _ => 0,
  };


  @override
  void initState() {
    super.initState();
    _pulseEffect.forward();
    _pulseEffect.addListener(_handlePulseEffectUpdate);
  }

  void _handlePulseEffectUpdate(){
    if(_pulseEffect.status  == AnimationStatus.completed){
      _pulseEffect.reverse();
      _pulseEffect.duration = _getRndPulseDuration();
    }else if(_pulseEffect.status == AnimationStatus.dismissed){
      _pulseEffect.duration = _getRndPulseDuration();
      _pulseEffect.forward();
    }
  }

  void _handleDifficultyPressed(int value){
    setState(() => _difficulty = value);
    _bumpMinEnergy();
  }

  Future<void> _bumpMinEnergy([double amount = 0.1])  async  {
    setState(() {
      _minOrbEnergy = _getMinEnergyForDifficulty(_difficulty) + amount;
    });
    await Future<void>.delayed(.2.seconds);
    setState(() {
      _minOrbEnergy = _getMinEnergyForDifficulty(_difficulty);
    });
  }

  void _handleStartPressed() => _bumpMinEnergy(0.3);

  void _handleDifficultyFocused(int? value){
    setState(() {
      _difficultyOverride = value;
      if(value == null){
        _minOrbEnergy = _getMinEnergyForDifficulty(_difficulty);
      }else {
        _minOrbEnergy = _getMinEnergyForDifficulty(value);
      }
    });
  }

  /// Update mouse position so the orbWidget can use it, doing it here prevents
  /// btns from blocking the mouse-move events in the widget itself.
  void _handleMouseMove(PointerHoverEvent e){
    setState(() {
      _mousePos = e.localPosition;
    });
  }

  // final _finalReceiveLightAmt = 0.7;
  // final _finalEmitLightAmt = 0.5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: MouseRegion(
          onHover: _handleMouseMove,
          child: _AnimatedColors(
            emitColor: _emitColor,
            orbColor: _orbColor,
            builder: (_, orbColor, emitColor) {
              return Stack(
                children: [
                  /// Bg-Base
                  Image.asset(AssetPaths.titleBgBase),

                  /// Bg-Receive
                  _LitImage(
                    color: _orbColor,
                    imgSrc: AssetPaths.titleBgReceive,
                    lightAmt: _finalReceiveLightAmt,
                    pulseEffect: _pulseEffect,
                  ),

                  /// Orb
                  Positioned.fill(
                      child: Stack(
                        children: [
                          // Orb
                          OrbShaderWidget(
                            key: _orbKey,
                            mousePos: _mousePos,
                            minEnergy: _minOrbEnergy,
                            config: OrbShaderConfig(
                              ambientLightColor: orbColor,
                              materialColor: orbColor,
                              lightColor: orbColor
                            ),
                            onUpdate: (energy) => setState(() {
                              _orbEnergy = energy;
                            }),
                          ),
                        ],
                      ),
                  ),



                  /// Mg-Base
                  _LitImage(
                    color: _orbColor,
                    imgSrc: AssetPaths.titleMgBase,
                    lightAmt: _finalReceiveLightAmt,
                    pulseEffect: _pulseEffect,
                  ),

                  /// Mg-Receive
                  _LitImage(
                    color: _orbColor,
                    imgSrc: AssetPaths.titleMgReceive,
                    lightAmt: _finalReceiveLightAmt,
                    pulseEffect: _pulseEffect,
                  ),

                  /// Mg-Emit
                  _LitImage(
                    color: _emitColor,
                    imgSrc: AssetPaths.titleMgEmit,
                    lightAmt: _finalEmitLightAmt,
                    pulseEffect: _pulseEffect,
                  ),

                  /// Particle Field
                  Positioned.fill(
                      child: IgnorePointer(
                        child: ParticleOverlay(
                          color: orbColor,
                          energy: _orbEnergy,
                        ),
                      ),
                  ),

                  /// Fg-Rocks
                  Image.asset(AssetPaths.titleFgBase),

                  /// Fg-Receive
                  _LitImage(
                    color: _orbColor,
                    imgSrc: AssetPaths.titleFgReceive,
                    lightAmt: _finalReceiveLightAmt,
                    pulseEffect: _pulseEffect,
                  ),

                  /// Fg-Emit
                  _LitImage(
                    color: _emitColor,
                    imgSrc: AssetPaths.titleFgEmit,
                    lightAmt: _finalEmitLightAmt,
                    pulseEffect: _pulseEffect,
                  ),

                  /// UI
                  Positioned.fill(
                    child: TitleScreenUI(
                      difficulty: _difficulty,
                      onDifficultyPressed: _handleDifficultyPressed,
                      onDifficultyFocused: _handleDifficultyFocused,
                      onStartPressed: _handleStartPressed,
                    ),
                  )
                ],
              ).animate().fadeIn(duration: 1.seconds, delay: .3.seconds);
            },


          ),
        ),
      ),
    );
  }
}


class _LitImage extends StatelessWidget {
  const _LitImage({
    super.key,
    required this.color,
    required this.imgSrc,
    required this.lightAmt,
    required this.pulseEffect,
  });

  final Color color;
  final  String imgSrc;
  final double lightAmt;
  final AnimationController pulseEffect;

  @override
  Widget build(BuildContext context) {
    final hsl = HSLColor.fromColor(color);
    return ListenableBuilder(
      listenable: pulseEffect,
      builder: (context, child) {
        return Image.asset(
          imgSrc,
          color: hsl.withLightness(hsl.lightness * lightAmt).toColor(),
          colorBlendMode: BlendMode.modulate,
        );
      },
    );
  }
}

class _AnimatedColors extends StatelessWidget {
  const _AnimatedColors({
    super.key,
    required this.emitColor,
    required this.orbColor,
    required this.builder,
  });

  final Color emitColor;
  final Color orbColor;

  final Widget Function(BuildContext context, Color  orbColor, Color emitColor) builder;

  @override
  Widget build(BuildContext context) {
    final duration = .5.seconds;
    return TweenAnimationBuilder(
        tween: ColorTween(begin: emitColor, end: emitColor),
        duration: duration,
        builder: (_, emitColor, __) {
          return  TweenAnimationBuilder(
              tween: ColorTween(begin: orbColor, end: orbColor),
              duration: duration,
              builder: (context, orbColor, __){
                return builder(context, orbColor!, emitColor!);
              }
          );
        },
    );
  }
}

class ParticleOverlay extends StatelessWidget {
  const ParticleOverlay({super.key, required this.color, required this.energy});

  final Color color;
  final double energy;

  @override
  Widget build(BuildContext context) {
    return ParticleField(
        spriteSheet: SpriteSheet(
          image: const AssetImage('assets/images/particle-wave.png'),
        ),
        // blend the image's alpha with the specified color
        blendMode: BlendMode.dstIn,

        // this runs every tick
        onTick: (controller, _, size) {
          List<Particle> particles = controller.particles;

          // add a new particle with random angle, distance & velocity
          double a = rnd(pi  * 2);
          double dist = rnd(1, 4) * 35 + 150 * energy;
          double vel = rnd(1, 2) * (1 + energy * 1.8);
          particles.add(Particle(
            // how many ticks this particle will live:
            lifespan: rnd(1, 2) * 20 + energy * 15,
            // starting distance  from center:
            x: cos(a) * dist,
            y: sin(a)  * dist,
            // starting velocity
            vx: cos(a) * vel,
            vy: sin(a) * vel,
            // other starting values:
            rotation: a,
            scale: rnd(1, 2) * 0.6 + energy * 0.5,
          ));


          // update all of the particles:
          for (int i = particles.length -1; i >= 0; i--) {
            Particle p  = particles[i];
            if(p.lifespan <= 0){
              // particles is expired, remove it:
              particles.removeAt(i);
              continue;
            }
            p.update(
              scale: p.scale * 1.025,
              vx: p.vx * 1.025,
              vy: p.vy * 1.025,
              color: color.withOpacity(p.lifespan * 0.001 + 0.01),
              lifespan: p.lifespan - 1,
            );
          }

        },
    );
  }
}



