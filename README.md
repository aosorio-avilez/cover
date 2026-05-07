# cover 🎯

[![Cover pub.dev badge](https://img.shields.io/pub/v/cover.svg)](https://pub.dev/packages/cover)
[![cover](https://github.com/aosorio-avilez/cover/actions/workflows/cover.yaml/badge.svg?branch=main)](https://github.com/aosorio-avilez/cover/actions/workflows/cover.yaml)
[![codecov](https://codecov.io/gh/aosorio-avilez/cover/branch/main/graph/badge.svg?token=ZWOS98VTND)](https://codecov.io/gh/aosorio-avilez/cover)

`cover` es la forma más sencilla y robusta de verificar la cobertura de tu código Dart/Flutter directamente desde la terminal o tus scripts.

## ✨ Características

- 📊 **Reportes Claros**: Genera una tabla elegante con el resumen de cobertura por archivo.
- 🚀 **Ideal para CI/CD**: Devuelve códigos de salida (exit codes) para fallar pipelines si la cobertura es insuficiente.
- 🔍 **Líneas Faltantes**: Muestra exactamente qué números de línea te faltan por probar con `--show-uncovered`.
- 🧹 **Filtros Inteligentes**: Ignora archivos generados (`.g.dart`, `.freezed.dart`, etc.) con un solo flag.
- 🤖 **Salida JSON**: Perfecto para integraciones con otras herramientas.
- 🛡️ **Seguro**: Protección contra inyecciones ANSI y manejo de errores robusto.

## 📦 Instalación

### Uso Global (Recomendado)
```sh
dart pub global activate cover
```

### Como Dependencia de Desarrollo
Añádelo a tu `pubspec.yaml`:
```yaml
dev_dependencies:
  cover: ^0.5.1
```

## 🚀 Uso desde CLI

```sh
# Verificación básica (busca coverage/lcov.info por defecto)
$ cover check

# Configurar un mínimo de cobertura y mostrar líneas no cubiertas
$ cover check --min-coverage 90 --show-uncovered

# Ignorar archivos generados y excluir carpetas específicas
$ cover check --exclude-generated --excluded-paths "lib/generated, lib/src/legacy"

# Obtener salida en formato JSON
$ cover check --json
```

### Flags Disponibles

| Flag | Abbr | Descripción | Por defecto |
| :--- | :--- | :--- | :--- |
| `--path` | `-p` | Ruta al archivo `lcov.info` | `coverage/lcov.info` |
| `--min-coverage` | `-m` | Porcentaje mínimo requerido | `100.0` |
| `--show-uncovered`| `-u` | Muestra los números de líneas no cubiertas | `false` |
| `--exclude-generated`| | Ignora archivos `.g.dart`, `.freezed.dart`, etc. | `false` |
| `--excluded-paths`| `-e` | Rutas separadas por coma a excluir | `""` |
| `--json` | `-j` | Salida en formato JSON | `false` |

## 🛠️ Uso Programático

Puedes integrar `cover` directamente en tu lógica de Dart:

```dart
import 'package:cover/cover.dart';

void main() async {
  final service = CoverageService();
  
  final result = await service.checkCoverage(
    filePath: 'coverage/lcov.info',
    minCoverage: 80.0,
    excludeGenerated: true,
  );

  print('Cobertura total: ${result.coverage}%');
}
```

## 📸 Ejemplo de Salida

<img src="https://raw.githubusercontent.com/aosorio-avilez/cover/main/resources/cover_example.png" width="600" />

## 🤝 Contribuciones e Issues
Si encuentras un error o tienes una idea, abre un issue en nuestro [rastreador de problemas](https://github.com/aosorio-avilez/cover/issues).
